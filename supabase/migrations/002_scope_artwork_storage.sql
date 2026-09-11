-- ============================================================================
-- Scope artwork storage to the owning user
--
-- 001 created the `artworks` bucket private but gated its policies only on
-- `auth.role() = 'authenticated'`, with no path check. Any signed-in user could
-- therefore read or write any object in the bucket — and these are photographs
-- of children.
--
-- Object paths become `{profile_id}/{child_id}/{uuid}.png`, so ownership is
-- checkable from the path's first segment. The alternative — joining the path
-- back through `children` to `profiles` — was rejected because `artworks` has no
-- `profile_id` column, making it a two-hop join evaluated on every object read.
--
-- Rewriting paths is free right now: the bucket is empty.
-- ============================================================================

drop policy if exists "Users can upload artworks" on storage.objects;
drop policy if exists "Users can view own artworks" on storage.objects;

-- `storage.foldername(name)` splits the object path into its folder components,
-- so element 1 is the `{profile_id}` prefix written by SupabaseService.uploadArtwork.
create policy "Users can upload own artworks"
    on storage.objects for insert
    with check (
        bucket_id = 'artworks'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can view own artworks"
    on storage.objects for select
    using (
        bucket_id = 'artworks'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- 001 shipped no delete policy at all, so users could not remove their own
-- uploads even though `deleteArtwork` removes the row.
create policy "Users can delete own artworks"
    on storage.objects for delete
    using (
        bucket_id = 'artworks'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- ============================================================================
-- `artworks.image_url` now holds a storage path, not a URL
--
-- Signed URLs expire, so persisting one would rot. The column stores the durable
-- object path; clients mint short-lived signed URLs on read, and edge functions
-- download by path with the service-role key.
-- ============================================================================

comment on column public.artworks.image_url is
    'Storage object path within the `artworks` bucket, formatted {profile_id}/{child_id}/{uuid}.png. Not a URL — sign it for display.';
