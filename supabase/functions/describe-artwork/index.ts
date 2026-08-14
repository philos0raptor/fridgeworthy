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

    // Download the image from storage
    const imageUrl = artwork.image_url;
    const imageResponse = await fetch(imageUrl);
    const imageBuffer = await imageResponse.arrayBuffer();
    const base64Image = btoa(
      new Uint8Array(imageBuffer).reduce((data, byte) => data + String.fromCharCode(byte), "")
    );

    // Call Claude API for description
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 100,
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
    const description = claudeResult.content?.[0]?.text?.trim() || "";

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
