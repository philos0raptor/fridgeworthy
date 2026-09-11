-- ============================================================================
-- Track the fal.ai queue request behind a wallpaper job
--
-- generate-wallpaper POSTed to queue.fal.run and then immediately read
-- `images[0].url` from the reply. The queue endpoint never returns that — it
-- returns a request handle — so every call fell through to the "No image in
-- response" branch and marked the wallpaper failed.
--
-- The fix is to treat generation as what it is: asynchronous. Submitting
-- returns a handle, which has to outlive the request that created it, so it is
-- persisted here. A later call resolves the handle and finalises the job.
--
-- This also takes image generation off the edge function's wall clock. The old
-- flow did submit, generate, download, and upload inside one request, which
-- would time out on real generation even once the response shape was fixed.
-- ============================================================================

alter table public.wallpapers
    add column if not exists fal_request_id text,
    add column if not exists fal_status_url text,
    add column if not exists fal_response_url text;

comment on column public.wallpapers.fal_request_id is
    'fal.ai queue request id. Present once submitted; the job is resolved by polling fal_status_url.';

-- Finalising looks up rows still in flight, so index the predicate it filters on.
create index if not exists wallpapers_processing_idx
    on public.wallpapers (status)
    where status = 'processing';
