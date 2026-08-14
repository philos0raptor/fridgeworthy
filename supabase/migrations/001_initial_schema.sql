-- Fridgeworthy Initial Schema
-- Run with: supabase db push

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================================
-- TABLES
-- ============================================================================

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    display_name text,
    subscription_tier text not null default 'free' check (subscription_tier in ('free', 'pro')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.children (
    id uuid primary key default uuid_generate_v4(),
    profile_id uuid not null references public.profiles(id) on delete cascade,
    name text not null,
    avatar_emoji text not null default '🎨',
    created_at timestamptz not null default now()
);

create table public.artworks (
    id uuid primary key default uuid_generate_v4(),
    child_id uuid not null references public.children(id) on delete cascade,
    title text,
    description text,
    image_url text not null,
    color_palette text[] default '{}',
    background_removed boolean not null default false,
    created_at timestamptz not null default now()
);

create table public.style_templates (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    description text not null,
    preview_image_url text,
    prompt_template text not null,
    negative_prompt text not null default 'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    tier text not null default 'free' check (tier in ('free', 'pro')),
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create table public.wallpapers (
    id uuid primary key default uuid_generate_v4(),
    child_id uuid not null references public.children(id) on delete cascade,
    style_template_id uuid not null references public.style_templates(id),
    image_url text,
    aspect_ratio text not null default '9:19.5',
    resolution text not null default '1170x2532',
    is_watermarked boolean not null default false,
    status text not null default 'pending' check (status in ('pending', 'processing', 'complete', 'failed')),
    error_message text,
    artwork_ids uuid[] not null default '{}',
    created_at timestamptz not null default now(),
    completed_at timestamptz
);

-- ============================================================================
-- INDEXES
-- ============================================================================

create index idx_children_profile_id on public.children(profile_id);
create index idx_artworks_child_id on public.artworks(child_id);
create index idx_wallpapers_child_id on public.wallpapers(child_id);
create index idx_wallpapers_status on public.wallpapers(status);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.artworks enable row level security;
alter table public.style_templates enable row level security;
alter table public.wallpapers enable row level security;

-- Profiles: users can only access their own
create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Children: users can only access their own children
create policy "Users can view own children"
    on public.children for select
    using (profile_id = auth.uid());

create policy "Users can insert own children"
    on public.children for insert
    with check (profile_id = auth.uid());

create policy "Users can update own children"
    on public.children for update
    using (profile_id = auth.uid());

create policy "Users can delete own children"
    on public.children for delete
    using (profile_id = auth.uid());

-- Artworks: users can access artworks belonging to their children
create policy "Users can view own artworks"
    on public.artworks for select
    using (child_id in (select id from public.children where profile_id = auth.uid()));

create policy "Users can insert own artworks"
    on public.artworks for insert
    with check (child_id in (select id from public.children where profile_id = auth.uid()));

create policy "Users can update own artworks"
    on public.artworks for update
    using (child_id in (select id from public.children where profile_id = auth.uid()));

create policy "Users can delete own artworks"
    on public.artworks for delete
    using (child_id in (select id from public.children where profile_id = auth.uid()));

-- Style templates: readable by all authenticated users
create policy "Authenticated users can view style templates"
    on public.style_templates for select
    using (auth.role() = 'authenticated');

-- Wallpapers: users can access wallpapers belonging to their children
create policy "Users can view own wallpapers"
    on public.wallpapers for select
    using (child_id in (select id from public.children where profile_id = auth.uid()));

create policy "Users can insert own wallpapers"
    on public.wallpapers for insert
    with check (child_id in (select id from public.children where profile_id = auth.uid()));

-- Service role can update wallpapers (for edge functions)
create policy "Service role can update wallpapers"
    on public.wallpapers for update
    using (true)
    with check (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    insert into public.profiles (id, email, display_name)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name')
    );
    return new;
end;
$$;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Auto-update updated_at on profiles
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger profiles_updated_at
    before update on public.profiles
    for each row execute function public.update_updated_at();

-- ============================================================================
-- STORAGE
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('artworks', 'artworks', false)
on conflict do nothing;

insert into storage.buckets (id, name, public)
values ('wallpapers', 'wallpapers', true)
on conflict do nothing;

-- Storage policies
create policy "Users can upload artworks"
    on storage.objects for insert
    with check (
        bucket_id = 'artworks' and
        auth.role() = 'authenticated'
    );

create policy "Users can view own artworks"
    on storage.objects for select
    using (
        bucket_id = 'artworks' and
        auth.role() = 'authenticated'
    );

create policy "Anyone can view wallpapers"
    on storage.objects for select
    using (bucket_id = 'wallpapers');

create policy "Service can upload wallpapers"
    on storage.objects for insert
    with check (bucket_id = 'wallpapers');

-- ============================================================================
-- SEED DATA: Style Templates
-- ============================================================================

insert into public.style_templates (name, description, prompt_template, negative_prompt, tier, sort_order) values
(
    'Watercolor Garden',
    'Soft watercolor storybook style with gentle color bleeds on cold-press paper',
    'A seamless phone wallpaper in soft watercolor storybook style, cold-press paper texture, gentle color bleeds. Blend the children''s artwork motifs — {artwork_description} — in a whimsical garden scene with flowers, leaves, and soft sunlight. Use colors from this palette: {color_palette}. Pastel palette, no harsh edges. {aspect_ratio} {resolution}',
    'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    'free',
    1
),
(
    'Geometric Mosaic',
    'Clean flat geometric shapes with bold primary and secondary colors',
    'A seamless phone wallpaper in geometric mosaic style, clean flat shapes, bold primary and secondary colors. Reinterpret the children''s artwork — {artwork_description} — as abstracted geometric tiles arranged in a harmonious grid pattern. Crisp edges, solid fills, no gradients. {aspect_ratio} {resolution}',
    'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    'free',
    2
),
(
    'Pencil Sketch',
    'Detailed graphite pencil drawings on warm cream paper with cross-hatching',
    'A seamless phone wallpaper in detailed pencil sketch style on warm cream paper. Render the children''s artwork subjects — {artwork_description} — as refined graphite pencil drawings with visible cross-hatching and soft shading. Scattered across the composition with generous white space. {aspect_ratio} {resolution}',
    'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    'free',
    3
),
(
    'Storybook Adventure',
    'Gouache storybook illustration with matte opaque paint and warm cozy palette',
    'A seamless phone wallpaper in gouache storybook illustration style, matte opaque paint, rounded friendly forms, warm cozy palette. Place the children''s artwork characters — {artwork_description} — into an adventure scene as if illustrating a children''s picture book. {child_name}''s magical world. {aspect_ratio} {resolution}',
    'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    'pro',
    4
),
(
    'Cut-Paper Collage',
    'Layered paper textures with torn edges and drop shadows on kraft background',
    'A seamless phone wallpaper in cut-paper collage style, layered paper textures with visible torn edges and subtle drop shadows. Reinterpret the children''s artwork — {artwork_description} — as paper cutout elements layered over kraft paper background. Handmade, tactile aesthetic. {aspect_ratio} {resolution}',
    'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    'pro',
    5
),
(
    'Pop Art Burst',
    'Bold pop art with halftone dots, thick outlines, and vibrant saturated colors',
    'A seamless phone wallpaper in pop art style. Transform the children''s artwork — {artwork_description} — into bold, high-contrast panels with halftone dots, thick black outlines, and vibrant saturated primary colors. Comic-book energy, repeated motifs in different color treatments. {aspect_ratio} {resolution}',
    'blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces',
    'pro',
    6
);
