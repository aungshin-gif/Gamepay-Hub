-- Hero banners: admin-manageable main-heading slides for the landing page.
-- The 3 GitHub images (assets/hero-*.jpg) stay as the built-in fallback;
-- rows here are shown FIRST (newest / lowest sort_order first) when present.
-- Run this in the Supabase Dashboard -> SQL Editor.

create table if not exists public.hero_banners (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  link_url text,
  alt_text text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.hero_banners enable row level security;

drop policy if exists "anyone can read hero banners" on public.hero_banners;
create policy "anyone can read hero banners" on public.hero_banners
  for select using (true);

drop policy if exists "admin manage hero banners" on public.hero_banners;
create policy "admin manage hero banners" on public.hero_banners
  for all using (public.is_admin()) with check (public.is_admin());

-- Public storage bucket for uploaded banner images (16:9 recommended)
insert into storage.buckets (id, name, public)
values ('hero-images', 'hero-images', true)
on conflict (id) do nothing;

drop policy if exists "anyone can view hero images" on storage.objects;
create policy "anyone can view hero images" on storage.objects
  for select using (bucket_id = 'hero-images');

drop policy if exists "admin upload hero images" on storage.objects;
create policy "admin upload hero images" on storage.objects
  for insert with check (bucket_id = 'hero-images' and public.is_admin());

drop policy if exists "admin delete hero images" on storage.objects;
create policy "admin delete hero images" on storage.objects
  for delete using (bucket_id = 'hero-images' and public.is_admin());
