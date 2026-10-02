-- News posts: optional per-post fields used by the Figma "User greeting"
-- newsroom storefront (excerpt, external link, image caption, source,
-- offer flag). All nullable / defaulted so existing posts keep working.
-- Run this in the Supabase Dashboard -> SQL Editor.
alter table public.news_posts
  add column if not exists excerpt    text,
  add column if not exists link_url   text,
  add column if not exists link_label text,
  add column if not exists caption    text,
  add column if not exists source     text,
  add column if not exists is_offer   boolean not null default false;
