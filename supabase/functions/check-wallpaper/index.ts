import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FAL_API_KEY = Deno.env.get("FAL_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface RequestBody {
  wallpaper_id: string;
}

/**
 * Resolves an in-flight generation.
 *
 * generate-wallpaper submits to the fal queue and returns a handle; something has to
 * come back later, ask fal whether the render finished, and finalise the row. This is
 * that something, and it is what the client's poll loop calls.
 *
 * Deliberately driven by the client rather than a fal webhook: a webhook endpoint must
 * be unauthenticated to receive fal's callback, which would leave an open door for
 * forging completions. Polling keeps every caller authenticated and ownership-checked.
 */
serve(async (req) => {
  try {
    const { wallpaper_id }: RequestBody = await req.json();

    if (!wallpaper_id) {
      return new Response(JSON.stringify({ error: "wallpaper_id is required" }), { status: 400 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Ownership is checked with the caller's own token so RLS applies. The service-role
    // client below can read anything, so skipping this would let any authenticated user
    // poll — and therefore read the image URL of — someone else's wallpaper.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization" }), { status: 401 });
    }

    const userClient = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: owned } = await userClient
      .from("wallpapers")
      .select("id")
      .eq("id", wallpaper_id)
      .maybeSingle();

    if (!owned) {
      return new Response(JSON.stringify({ error: "Wallpaper not found" }), { status: 404 });
    }

    const { data: wallpaper, error: wallpaperError } = await supabase
      .from("wallpapers")
      .select("*")
      .eq("id", wallpaper_id)
      .single();

    if (wallpaperError || !wallpaper) {
      return new Response(JSON.stringify({ error: "Wallpaper not found" }), { status: 404 });
    }

    // Already settled — nothing to resolve.
    if (wallpaper.status === "complete" || wallpaper.status === "failed") {
      return new Response(JSON.stringify(statusPayload(wallpaper)), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!wallpaper.fal_status_url) {
      return new Response(JSON.stringify(statusPayload(wallpaper)), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const statusResponse = await fetch(wallpaper.fal_status_url, {
      headers: { Authorization: `Key ${FAL_API_KEY}` },
    });

    if (!statusResponse.ok) {
      const detail = await statusResponse.text();
      return new Response(JSON.stringify(await fail(supabase, wallpaper_id, detail)), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const falStatus = await statusResponse.json();

    // IN_QUEUE / IN_PROGRESS — still rendering, report unchanged and let the client poll.
    if (falStatus.status !== "COMPLETED") {
      return new Response(JSON.stringify(statusPayload(wallpaper)), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // COMPLETED: the payload lives at response_url, not on the status response.
    const responseURL = wallpaper.fal_response_url ??
      wallpaper.fal_status_url.replace(/\/status$/, "");

    const resultResponse = await fetch(responseURL, {
      headers: { Authorization: `Key ${FAL_API_KEY}` },
    });

    if (!resultResponse.ok) {
      const detail = await resultResponse.text();
      return new Response(JSON.stringify(await fail(supabase, wallpaper_id, detail)), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const result = await resultResponse.json();
    const generatedImageUrl = result.images?.[0]?.url;

    if (!generatedImageUrl) {
      const detail = `Completed with no image: ${JSON.stringify(result).slice(0, 200)}`;
      return new Response(JSON.stringify(await fail(supabase, wallpaper_id, detail)), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Copy the render into our own storage — fal's URLs are temporary.
    const imageResponse = await fetch(generatedImageUrl);
    if (!imageResponse.ok) {
      return new Response(
        JSON.stringify(await fail(supabase, wallpaper_id, "Could not download the generated image")),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const imageBuffer = await imageResponse.arrayBuffer();

    // fal renders JPEG. Storing those bytes as .png with contentType image/png — which
    // is what the original code did — leaves every object mislabelled, and anything that
    // trusts the declared type rather than sniffing the bytes gets it wrong.
    const contentType = imageResponse.headers.get("content-type")?.split(";")[0] ?? "image/jpeg";
    const extension = contentType === "image/png" ? "png" : "jpg";
    const storagePath = `${wallpaper.child_id}/${wallpaper.id}.${extension}`;

    const { error: uploadError } = await supabase.storage
      .from("wallpapers")
      .upload(storagePath, imageBuffer, { contentType, upsert: true });

    if (uploadError) {
      return new Response(
        JSON.stringify(await fail(supabase, wallpaper_id, `Upload failed: ${uploadError.message}`)),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: publicURL } = supabase.storage.from("wallpapers").getPublicUrl(storagePath);

    const { data: updated } = await supabase
      .from("wallpapers")
      .update({
        status: "complete",
        image_url: publicURL.publicUrl,
        completed_at: new Date().toISOString(),
      })
      .eq("id", wallpaper_id)
      .select()
      .single();

    return new Response(JSON.stringify(statusPayload(updated)), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});

/** The client decodes this shape as WallpaperStatusDTO. */
function statusPayload(row: Record<string, unknown>) {
  return {
    id: row.id,
    status: row.status,
    image_url: row.image_url ?? null,
    error_message: row.error_message ?? null,
  };
}

async function fail(
  supabase: ReturnType<typeof createClient>,
  wallpaperID: string,
  message: string
) {
  const { data } = await supabase
    .from("wallpapers")
    .update({ status: "failed", error_message: message })
    .eq("id", wallpaperID)
    .select()
    .single();

  return statusPayload(data ?? { id: wallpaperID, status: "failed", error_message: message });
}
