import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FAL_API_KEY = Deno.env.get("FAL_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface RequestBody {
  child_id: string;
  /**
   * Styles are addressed by slug, never by id. The iOS client seeds its own copies of
   * the style templates with client-generated UUIDs, so an id sent from the app can
   * never match a row here — see 003_style_template_slugs.sql.
   */
  style_slug: string;
}

serve(async (req) => {
  try {
    const { child_id, style_slug }: RequestBody = await req.json();

    if (!style_slug) {
      return new Response(JSON.stringify({ error: "style_slug is required" }), { status: 400 });
    }

    // Create admin client for service-level operations
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get the auth user from the request
    const authHeader = req.headers.get("Authorization")!;
    const userClient = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });

    // Verify the child belongs to the user
    const { data: child, error: childError } = await userClient
      .from("children")
      .select("id, name, profile_id")
      .eq("id", child_id)
      .single();

    if (childError || !child) {
      return new Response(JSON.stringify({ error: "Child not found" }), { status: 404 });
    }

    // Fetch the style template
    const { data: style, error: styleError } = await supabase
      .from("style_templates")
      .select("*")
      .eq("slug", style_slug)
      .single();

    if (styleError || !style) {
      return new Response(
        JSON.stringify({ error: "Style template not found", slug: style_slug }),
        { status: 404 }
      );
    }

    // Fetch recent artworks (4-8)
    const { data: artworks, error: artworksError } = await supabase
      .from("artworks")
      .select("*")
      .eq("child_id", child_id)
      .order("created_at", { ascending: false })
      .limit(8);

    if (artworksError || !artworks || artworks.length === 0) {
      return new Response(JSON.stringify({ error: "No artworks found" }), { status: 400 });
    }

    // Create wallpaper record in 'processing' state
    const { data: wallpaper, error: wallpaperError } = await supabase
      .from("wallpapers")
      .insert({
        child_id,
        style_template_id: style.id,
        status: "processing",
        artwork_ids: artworks.map((a: any) => a.id),
      })
      .select()
      .single();

    if (wallpaperError) {
      return new Response(JSON.stringify({ error: "Failed to create wallpaper record" }), { status: 500 });
    }

    // Assemble the prompt from template
    const artworkDescriptions = artworks
      .map((a: any) => a.description || "colorful children's drawing")
      .join(", ");

    const colorPalettes = artworks
      .flatMap((a: any) => a.color_palette || [])
      .filter((v: string, i: number, arr: string[]) => arr.indexOf(v) === i)
      .slice(0, 8)
      .join(", ");

    let prompt = style.prompt_template
      .replace("{artwork_description}", artworkDescriptions)
      .replace("{color_palette}", colorPalettes || "warm pastels")
      .replace("{child_name}", child.name)
      .replace("{aspect_ratio}", "9:19.5 aspect ratio")
      .replace("{resolution}", "1170x2532 pixels");

    // Call fal.ai FLUX Kontext Pro
    const falResponse = await fetch("https://queue.fal.run/fal-ai/flux-pro/kontext", {
      method: "POST",
      headers: {
        Authorization: `Key ${FAL_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        prompt,
        negative_prompt: style.negative_prompt,
        image_size: { width: 1170, height: 2532 },
        num_images: 1,
        guidance_scale: 7.5,
        num_inference_steps: 28,
      }),
    });

    if (!falResponse.ok) {
      const errorText = await falResponse.text();
      await supabase
        .from("wallpapers")
        .update({ status: "failed", error_message: errorText })
        .eq("id", wallpaper.id);

      return new Response(JSON.stringify({ error: "Generation failed", details: errorText }), { status: 502 });
    }

    const falResult = await falResponse.json();
    const generatedImageUrl = falResult.images?.[0]?.url;

    if (!generatedImageUrl) {
      await supabase
        .from("wallpapers")
        .update({ status: "failed", error_message: "No image in response" })
        .eq("id", wallpaper.id);

      return new Response(JSON.stringify({ error: "No image generated" }), { status: 502 });
    }

    // Download the generated image and upload to Supabase Storage
    const imageResponse = await fetch(generatedImageUrl);
    const imageBlob = await imageResponse.blob();
    const imageBuffer = await imageBlob.arrayBuffer();

    const storagePath = `${child_id}/${wallpaper.id}.png`;
    const { error: uploadError } = await supabase.storage
      .from("wallpapers")
      .upload(storagePath, imageBuffer, { contentType: "image/png" });

    if (uploadError) {
      await supabase
        .from("wallpapers")
        .update({ status: "failed", error_message: "Upload failed" })
        .eq("id", wallpaper.id);

      return new Response(JSON.stringify({ error: "Failed to store wallpaper" }), { status: 500 });
    }

    // Get public URL
    const { data: publicURL } = supabase.storage.from("wallpapers").getPublicUrl(storagePath);

    // Update wallpaper record to complete
    await supabase
      .from("wallpapers")
      .update({
        status: "complete",
        image_url: publicURL.publicUrl,
        completed_at: new Date().toISOString(),
      })
      .eq("id", wallpaper.id);

    return new Response(
      JSON.stringify({ wallpaper_id: wallpaper.id, status: "complete", image_url: publicURL.publicUrl }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
