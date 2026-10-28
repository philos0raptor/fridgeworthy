-- Keep the full source photo beside the prepared image in the private artworks bucket.
alter table public.artworks add column original_image_url text;
comment on column public.artworks.original_image_url is
    'Storage path of the untouched source photo. image_url remains the prepared display and wallpaper source.';
