import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface RequestBody {
  artwork_id: string;
}

serve(async (req) => {
  try {
    const { artwork_id }: RequestBody = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch the artwork record
    const { data: artwork, error: artworkError } = await supabase
      .from("artworks")
      .select("*")
      .eq("id", artwork_id)
      .single();

    if (artworkError || !artwork) {
      return new Response(JSON.stringify({ error: "Artwork not found" }), { status: 404 });
    }

    // Download the image from storage.
    //
    // `artworks.image_url` holds a storage *path*, not a URL (see 002). The bucket is
    // private, so fetching a URL would 400; this client carries the service-role key and
    // reads the object directly, which also avoids depending on a signed URL that expires.
    const { data: imageBlob, error: downloadError } = await supabase.storage
      .from("artworks")
      .download(artwork.image_url);

    if (downloadError || !imageBlob) {
      return new Response(
        JSON.stringify({ error: "Could not read artwork image", details: downloadError?.message }),
        { status: 502 }
      );
    }

    const imageBuffer = await imageBlob.arrayBuffer();
    // Chunked so a large image cannot blow the argument limit on String.fromCharCode.
    const bytes = new Uint8Array(imageBuffer);
    let binary = "";
    for (let i = 0; i < bytes.length; i += 0x8000) {
      binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
    }
    const base64Image = btoa(binary);

    // Call Claude API for description
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "anthropic-beta": "server-side-fallback-2026-07-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-opus-5",
        // Thinking is on by default, and it draws from max_tokens. The old value of 100
        // was sized for the visible caption alone and would truncate mid-reasoning.
        max_tokens: 2048,
        // A 15-word caption is not hard work; low effort keeps cost and latency down
        // without disabling thinking, which has its own failure modes.
        output_config: { effort: "low" },
        // Route around a safety refusal rather than returning nothing for a drawing.
        fallbacks: "default",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: "image/png",
                  data: base64Image,
                },
              },
              {
                type: "text",
                text: "List the main subjects, colors, and mood of this child's drawing in 15 words or fewer. Be specific about what you see — animals, shapes, people, objects. Output only the description, no preamble.",
              },
            ],
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      return new Response(JSON.stringify({ error: "AI description failed", details: errorText }), { status: 502 });
    }

    const claudeResult = await claudeResponse.json();

    if (claudeResult.stop_reason === "refusal") {
      return new Response(
        JSON.stringify({ error: "Image description was declined", details: claudeResult.stop_details }),
        { status: 502 }
      );
    }

    // Find the text block rather than taking content[0]: with thinking enabled the first
    // block is a thinking block, whose text is empty by default. Indexing blindly would
    // store "" as the description and look like a successful call.
    const description = claudeResult.content
      ?.find((block: { type: string }) => block.type === "text")
      ?.text?.trim() || "";

    if (!description) {
      return new Response(
        JSON.stringify({ error: "Model returned no description" }),
        { status: 502 }
      );
    }

    // Update artwork with description
    await supabase
      .from("artworks")
      .update({ description })
      .eq("id", artwork_id);

    return new Response(
      JSON.stringify({ artwork_id, description }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
