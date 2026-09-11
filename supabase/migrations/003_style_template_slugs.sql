-- ============================================================================
-- Give style templates a stable, human-authored identity
--
-- 001 seeded `style_templates` without ids, letting Postgres generate them,
-- while StyleTemplateSyncService.seedDefaultsIfEmpty inserted the same six
-- styles client-side and let Swift generate *different* UUIDs. The two sets
-- were unrelated by construction, so the id the picker sent to
-- generate-wallpaper could never match a server row — a guaranteed 404 before
-- fal was ever called.
--
-- A slug is authored in both places and therefore matches. Ids stay as the
-- primary key; the slug is the cross-boundary identity.
-- ============================================================================

alter table public.style_templates
    add column if not exists slug text;

-- Backfill the six rows seeded by 001, keyed on their names.
update public.style_templates set slug = 'watercolor-garden'   where name = 'Watercolor Garden'   and slug is null;
update public.style_templates set slug = 'geometric-mosaic'    where name = 'Geometric Mosaic'    and slug is null;
update public.style_templates set slug = 'pencil-sketch'       where name = 'Pencil Sketch'       and slug is null;
update public.style_templates set slug = 'storybook-adventure' where name = 'Storybook Adventure' and slug is null;
update public.style_templates set slug = 'cut-paper-collage'   where name = 'Cut-Paper Collage'   and slug is null;
update public.style_templates set slug = 'pop-art-burst'       where name = 'Pop Art Burst'       and slug is null;

-- Any row the backfill missed would break generation silently, so fail loudly
-- here instead — this migration is the last place it is cheap to notice.
do $$
declare
    missing integer;
begin
    select count(*) into missing from public.style_templates where slug is null;
    if missing > 0 then
        raise exception 'style_templates has % row(s) with no slug; add a backfill line for them', missing;
    end if;
end $$;

alter table public.style_templates
    alter column slug set not null;

create unique index if not exists style_templates_slug_key
    on public.style_templates (slug);

comment on column public.style_templates.slug is
    'Stable identity shared with the iOS client. Clients resolve styles by slug, never by id — ids are generated independently on each side and can never match.';
