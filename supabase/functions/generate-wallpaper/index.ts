import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FAL_API_KEY = Deno.env.get("FAL_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Text-to-image. NOT flux-pro/kontext, which is an image *editing* model and rejects
// any request without an `image_url` — the pipeline feeds it a description, not a
// picture, so kontext could never have worked here.
const FAL_MODEL = "fal-ai/flux-pro/v1.1";

// fal snaps dimensions to multiples of 64 and caps a side at 1440, so the iPhone's
// 1170x2532 is not reachable. 640x1440 is the closest ratio it will honour (0.444 vs
// the device's 0.462); anything taller comes back clamped to a squarer image.
const IMAGE_WIDTH = 640;
const IMAGE_HEIGHT = 1440;

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
      .replace("{resolution}", `${IMAGE_WIDTH}x${IMAGE_HEIGHT} pixels`);

    // Submit to the fal.ai queue.
    //
    // This endpoint returns a request *handle* — {request_id, status_url, response_url} —
    // never the images. Reading `images[0].url` here is what made every generation fail
    // with "No image in response". Resolving the handle is check-wallpaper's job.
    //
    // Submitting and returning also keeps image generation off this function's wall
    // clock; doing the generate/download/upload inline would time out on a real render.
    const falResponse = await fetch(`https://queue.fal.run/${FAL_MODEL}`, {
      method: "POST",
      headers: {
        Authorization: `Key ${FAL_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        prompt,
        negative_prompt: style.negative_prompt,
        image_size: { width: IMAGE_WIDTH, height: IMAGE_HEIGHT },
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

    if (!falResult.request_id) {
      const detail = `Queue accepted the request but returned no request_id: ${JSON.stringify(falResult).slice(0, 200)}`;
      await supabase
        .from("wallpapers")
        .update({ status: "failed", error_message: detail })
        .eq("id", wallpaper.id);

      return new Response(JSON.stringify({ error: "Generation failed", details: detail }), { status: 502 });
    }

    // fal returns status_url/response_url explicitly; fall back to the documented shape
    // so a missing field degrades to a working URL rather than a stuck job.
    const requestBase =
      `https://queue.fal.run/${FAL_MODEL.split("/").slice(0, 2).join("/")}/requests/${falResult.request_id}`;

    await supabase
      .from("wallpapers")
      .update({
        fal_request_id: falResult.request_id,
        fal_status_url: falResult.status_url ?? `${requestBase}/status`,
        fal_response_url: falResult.response_url ?? requestBase,
      })
      .eq("id", wallpaper.id);

    return new Response(
      JSON.stringify({ wallpaper_id: wallpaper.id, status: "processing" }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
