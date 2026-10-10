-- ============================================================
-- GamePay Hub — Order + Chat + Login + Payment-slip backend
--
-- How to run this: Supabase Dashboard -> SQL Editor -> New query
-- -> paste this whole file -> Run. Safe to re-run (uses IF NOT EXISTS
-- and CREATE OR REPLACE), so re-running after an edit won't duplicate data
-- or fail on columns/policies that already exist.
-- ============================================================

create extension if not exists pgcrypto;

-- 1. Orders -----------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  access_token uuid not null default gen_random_uuid(), -- the guest customer's private "ticket" to their own order
  user_id uuid references auth.users(id) on delete set null, -- set automatically when the customer is logged in
  order_code text not null unique,
  product_name text not null,
  plan_name text not null,
  amount numeric not null default 0,
  payment_method text,
  account_info text,
  note text,
  payment_slip_path text, -- path inside the private "payment-slips" storage bucket
  status text not null default 'pending' check (status in ('pending','approved','rejected','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Re-running on an older copy of this table: add any columns that were
-- introduced later without wiping existing rows.
alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists payment_slip_path text;
-- Lets an admin hide clutter (old test orders, etc.) from the default
-- dashboard view without ever deleting the row -- the order and its chat
-- history stay in the database exactly as the "no one deletes" policies
-- below intend, just filtered out of view until "Show archived" is toggled.
alter table public.orders add column if not exists archived boolean not null default false;
-- When each side last opened this order's chat -- lets both the admin
-- dashboard and the customer's "My Orders" list show a real, persisted
-- unread-message count instead of an in-memory one that forgets on reload.
alter table public.orders add column if not exists admin_last_read_at timestamptz;
alter table public.orders add column if not exists customer_last_read_at timestamptz;
-- Snapshotted from the plan at the moment of purchase (not looked up live),
-- so a later admin edit to the plan's own Warranty/Format/Note in the Stock
-- list can never rewrite what an existing customer was actually promised.
alter table public.orders add column if not exists plan_warranty text;
alter table public.orders add column if not exists plan_format text;
alter table public.orders add column if not exists plan_note text;
-- Admin can end a finished order's conversation from their side; once set,
-- send_customer_message (below) refuses any further customer replies. There
-- is no "reopen" action -- ending a chat is meant to be final, matching a
-- completed/finished order.
alter table public.orders add column if not exists chat_closed boolean not null default false;
-- Set by admin when rejecting an order (a preset reason like "out of
-- stock" / "payment screenshot wrong", or a custom note) -- shown back to
-- the customer on their order-status page instead of a generic message.
alter table public.orders add column if not exists reject_reason text;

-- 2. Chat messages, one thread per order -------------------------
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  sender text not null check (sender in ('customer','admin')),
  body text not null,
  created_at timestamptz not null default now()
);

-- 3. Admin allow-list (who may use shinpayhubcld.html) --------------------
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- 4. Lock every table down by default ------------------------------
alter table public.orders enable row level security;
alter table public.messages enable row level security;
alter table public.admins enable row level security;

-- Helper: is the currently-logged-in Supabase Auth user an admin?
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
grant execute on function public.is_admin() to authenticated, anon;

-- Admins (logged in via shinpayhubcld.html AND listed in public.admins) can
-- read/update the real tables directly.
drop policy if exists "admin read orders" on public.orders;
create policy "admin read orders" on public.orders
  for select using (public.is_admin());

drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders
  for update using (public.is_admin());

drop policy if exists "admin read messages" on public.messages;
create policy "admin read messages" on public.messages
  for select using (public.is_admin());

drop policy if exists "admin insert messages" on public.messages;
create policy "admin insert messages" on public.messages
  for insert with check (public.is_admin());

-- Logged-in customers can see their own orders/messages directly (this is
-- what powers "My Orders" across devices once you sign in). Guests who
-- never log in fall back to the token-gated functions further down.
drop policy if exists "customer read own orders" on public.orders;
create policy "customer read own orders" on public.orders
  for select using (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists "customer read own messages" on public.messages;
create policy "customer read own messages" on public.messages
  for select using (
    auth.uid() is not null
    and exists (select 1 from public.orders o where o.id = messages.order_id and o.user_id = auth.uid())
  );

-- Guests (not logged in) get no table policy at all — the only way in is
-- through the functions below, and only if you already hold the exact
-- access_token (the customer's private order link).

-- Postgres treats a changed argument list as a distinct overload rather
-- than replacing it, so an older version of this function from before
-- payment slips (or any other since-changed argument list) existed would
-- otherwise stick around and make every call to "create_order" ambiguous.
-- This project's create_order signature has changed several times across
-- sessions, so rather than track every historical argument list by hand
-- (which has already gone stale once -- see the "function name is not
-- unique" error re-running this on a database with an older, untracked
-- overload still in it), drop every existing overload of it dynamically.
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'create_order'
  loop
    execute format('drop function if exists %s', r.sig);
  end loop;
end $$;

create or replace function public.create_order(
  p_product_name text, p_plan_name text, p_amount numeric,
  p_payment_method text, p_account_info text, p_note text,
  p_payment_slip_path text default null
) returns table (id uuid, access_token uuid, order_code text)
language plpgsql security definer set search_path = public as $$
declare
  v_code text := 'GPH-' || to_char(now(),'YYYYMMDD') || '-' || substr(replace(gen_random_uuid()::text,'-',''),1,5);
begin
  return query
  insert into public.orders(product_name, plan_name, amount, payment_method, account_info, note, order_code, payment_slip_path, user_id)
  values (p_product_name, p_plan_name, p_amount, p_payment_method, p_account_info, p_note, v_code, p_payment_slip_path, auth.uid())
  returning orders.id, orders.access_token, orders.order_code;
end;
$$;

create or replace function public.get_order_status(p_token uuid)
returns table(status text, order_code text)
language sql security definer set search_path = public as $$
  select status, order_code from public.orders where access_token = p_token;
$$;

create or replace function public.get_messages(p_token uuid)
returns table(sender text, body text, created_at timestamptz)
language sql security definer set search_path = public as $$
  select m.sender, m.body, m.created_at
  from public.messages m
  join public.orders o on o.id = m.order_id
  where o.access_token = p_token
  order by m.created_at asc;
$$;

create or replace function public.send_customer_message(p_token uuid, p_body text)
returns void
language plpgsql security definer set search_path = public as $$
declare v_order_id uuid; v_chat_closed boolean;
begin
  select id, chat_closed into v_order_id, v_chat_closed from public.orders where access_token = p_token;
  if v_order_id is null then
    raise exception 'invalid order token';
  end if;
  -- Client-side already hides the input once ended; this is the real gate,
  -- since a customer's browser is never trusted to enforce it on its own.
  if v_chat_closed then
    raise exception 'this conversation has ended';
  end if;
  insert into public.messages(order_id, sender, body) values (v_order_id, 'customer', p_body);
end;
$$;

-- Stamps "I've seen this chat" for a guest/token-holding customer -- same
-- token-gated pattern as send_customer_message, since a customer (logged
-- in or not) has no direct UPDATE policy on orders.
create or replace function public.mark_customer_read(p_token uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.orders set customer_last_read_at = now() where access_token = p_token;
end;
$$;
grant execute on function public.mark_customer_read to anon, authenticated;

-- The anon (public) key may call only these functions — never the raw
-- tables. "authenticated" gets them too, since a logged-in customer's own
-- browser still uses the same token flow for chat/order-creation.
grant execute on function public.create_order to anon, authenticated;
grant execute on function public.get_order_status to anon, authenticated;
grant execute on function public.get_messages to anon, authenticated;
grant execute on function public.send_customer_message to anon, authenticated;

-- 5. Payment-slip screenshots (private storage bucket) -------------
-- file_size_limit/allowed_mime_types are enforced by Storage itself on
-- every upload (anon includes an un-authenticated guest, so without
-- these a guest could upload arbitrarily large or arbitrary-type files
-- here all day for free). 8MB covers a phone screenshot comfortably.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('payment-slips', 'payment-slips', false, 8388608, array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "anyone can upload a payment slip" on storage.objects;
create policy "anyone can upload a payment slip" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'payment-slips');

drop policy if exists "admin can read payment slips" on storage.objects;
create policy "admin can read payment slips" on storage.objects
  for select to authenticated
  using (bucket_id = 'payment-slips' and public.is_admin());

-- 6. Admin: look up which email a "username" (its part before the @)
-- registered with. auth.users isn't exposed to the API by default, so
-- this is the only door into it, and only for an admin.
-- Postgres can't CREATE OR REPLACE a function whose return columns changed
-- (adding "id" here) -- it has to be dropped first, the same issue
-- create_order hit earlier when its argument list changed.
drop function if exists public.admin_search_users(text);

create or replace function public.admin_search_users(p_query text)
returns table(id uuid, email text, created_at timestamptz)
language sql security definer set search_path = public as $$
  select u.id, u.email, u.created_at
  from auth.users u
  where public.is_admin() and u.email ilike '%' || p_query || '%'
  order by u.created_at desc
  limit 20;
$$;
grant execute on function public.admin_search_users to authenticated;

-- 6b. Admin: look up one customer's email by their user_id, so the chat
-- panel can show a real "username" (email's part before the @) instead of
-- just the order's typed-in account_info. auth.users isn't exposed to the
-- API directly, so this is the door in, same pattern as admin_search_users.
create or replace function public.admin_get_user_email(p_user_id uuid)
returns text
language sql security definer set search_path = public as $$
  select email from auth.users where public.is_admin() and id = p_user_id;
$$;
grant execute on function public.admin_get_user_email to authenticated;

-- Admin dashboard stat card ("Total Users") -- same is_admin()-gated door
-- into auth.users as the two functions above, just a count instead of rows.
create or replace function public.admin_count_users()
returns integer
language sql security definer set search_path = public as $$
  select count(*)::int from auth.users where public.is_admin();
$$;
grant execute on function public.admin_count_users to authenticated;

-- 7. No one may delete orders or chat history -- not the customer, not
-- admin, not a hijacked session, no one. Orders/messages have no DELETE
-- policy at all, and with RLS enabled that already means every DELETE is
-- refused by default -- these two are here anyway to say so explicitly,
-- so the "no deleting" rule can't be lost or misread as an oversight the
-- next time this file is edited. The only way to remove a row at all is
-- a superuser running SQL directly in the dashboard, never through the
-- app or the API.
drop policy if exists "no one deletes orders" on public.orders;
create policy "no one deletes orders" on public.orders for delete using (false);

drop policy if exists "no one deletes messages" on public.messages;
create policy "no one deletes messages" on public.messages for delete using (false);

-- 8. Coupons ------------------------------------------------------
-- Each row is a single-use coupon code worth a fixed Kyat amount off an
-- order. assigned_user_id null = a public promo code anyone who has the
-- code can redeem; set = gifted straight to that one customer, and only
-- they can redeem it. used_at set = "Expired" in the admin dashboard,
-- null = "Live".
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  amount numeric not null check (amount > 0),
  assigned_user_id uuid references auth.users(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  used_at timestamptz,
  used_by_user_id uuid references auth.users(id) on delete set null,
  used_by_order_id uuid references public.orders(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.coupons enable row level security;

drop policy if exists "admin manage coupons" on public.coupons;
create policy "admin manage coupons" on public.coupons
  for all using (public.is_admin()) with check (public.is_admin());

-- Orders: remember which coupon (if any) an order used, and how much it
-- knocked off -- amount already holds the post-discount total charged.
alter table public.orders add column if not exists coupon_code text;
alter table public.orders add column if not exists discount_amount numeric not null default 0;

-- 9. Notifications --------------------------------------------------
-- Powers the customer-side "Notice" tab -- currently only used to tell a
-- customer they were gifted a coupon, but kept general so admin can drop
-- other one-off notices later without a schema change.
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.notifications enable row level security;

drop policy if exists "customer read own notifications" on public.notifications;
create policy "customer read own notifications" on public.notifications
  for select using (auth.uid() = user_id);

-- Deliberately no customer UPDATE policy on this table: a row-level
-- policy here can't restrict which COLUMNS a customer touches, so one
-- that let them flip their own read_at would also let them rewrite their
-- own title/body (e.g. forging a fake "GamePay gave you 50,000 Ks"
-- notice for a screenshot). mark_notifications_read() below is the only
-- door in -- it's security definer and only ever sets read_at = now().
drop policy if exists "customer mark own notifications read" on public.notifications;

drop policy if exists "admin manage notifications" on public.notifications;
create policy "admin manage notifications" on public.notifications
  for all using (public.is_admin()) with check (public.is_admin());

-- Admin: create a coupon code (optionally gifted straight to one user, with
-- a notification telling them to go check it).
create or replace function public.admin_create_coupon(p_code text, p_amount numeric, p_user_id uuid default null)
returns table(id uuid, code text, amount numeric)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  return query
  insert into public.coupons(code, amount, assigned_user_id, created_by)
  values (p_code, p_amount, p_user_id, auth.uid())
  returning coupons.id, coupons.code, coupons.amount;

  if p_user_id is not null then
    insert into public.notifications(user_id, title, body)
    values (
      p_user_id, 'You got a coupon!',
      'GamePay Hub gave you a coupon code: ' || p_code || ' (worth ' || p_amount || ' Ks). Enter it at checkout to use it!'
    );
  end if;
end;
$$;
grant execute on function public.admin_create_coupon to authenticated;

-- Admin: send a one-way announcement to every registered customer at once
-- (drops a row in notifications per user -- same table and Noti box the
-- coupon-gift notice above already uses, just addressed to everyone
-- instead of one person). Read-only for the customer; there's nowhere for
-- a reply to go.
create or replace function public.admin_broadcast_notification(p_title text, p_body text)
returns int
language plpgsql security definer set search_path = public as $$
declare v_count int;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  insert into public.notifications(user_id, title, body)
  select id, p_title, p_body from auth.users;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
grant execute on function public.admin_broadcast_notification to authenticated;

-- Admin: full coupon list for the dashboard's Coupons tab.
create or replace function public.admin_list_coupons()
returns setof public.coupons
language sql security definer set search_path = public as $$
  select * from public.coupons where public.is_admin() order by created_at desc;
$$;
grant execute on function public.admin_list_coupons to authenticated;

-- Admin: manually remove a coupon, live or already-expired.
create or replace function public.admin_delete_coupon(p_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  delete from public.coupons where id = p_id;
end;
$$;
grant execute on function public.admin_delete_coupon to authenticated;

-- Admin: every registered user with an order count, for the dashboard's
-- User List (auth.users isn't exposed to the API directly, same reason
-- admin_search_users exists below).
-- `meta` carries raw_user_meta_data (username, avatar_style, avatar_color)
-- so the admin side can render the same avatar the customer picked for
-- themselves instead of a generated placeholder.
drop function if exists public.admin_list_users();
create or replace function public.admin_list_users()
returns table(id uuid, email text, created_at timestamptz, order_count bigint, meta jsonb)
language sql security definer set search_path = public as $$
  select u.id, u.email, u.created_at, count(o.id) as order_count, u.raw_user_meta_data
  from auth.users u
  left join public.orders o on o.user_id = u.id
  where public.is_admin()
  group by u.id, u.email, u.created_at, u.raw_user_meta_data
  order by u.created_at desc;
$$;
grant execute on function public.admin_list_users to authenticated;

-- Customer (or guest, for a public code): check a coupon at checkout
-- without consuming it -- create_order is what actually redeems it.
-- Global rate limit for check_coupon -- it's callable by anon (a guest
-- checking a coupon at checkout never has to log in first), so there's
-- no stable per-caller identity to throttle by the way admin_gate's
-- per-account lockout does. One shared sliding window across every
-- caller is the tradeoff: a script guessing codes (36^6 ≈ 2.1 billion
-- combinations for the "GPH......" codes randomCouponCode() generates)
-- is slowed to uselessness at any sane cap, while real traffic -- one
-- or two checks per customer, at checkout -- never gets close to it.
create table if not exists public.coupon_check_rate_limit (
  id boolean primary key default true check (id),
  window_start timestamptz not null default now(),
  count int not null default 0
);
insert into public.coupon_check_rate_limit (id) values (true) on conflict (id) do nothing;
alter table public.coupon_check_rate_limit enable row level security;
-- No policies at all, same reasoning as admin_gate -- nothing outside
-- check_coupon itself (security definer, bypasses RLS) ever needs to
-- touch this row.

create or replace function public.check_coupon(p_code text)
returns table(amount numeric, valid boolean)
language plpgsql security definer set search_path = public as $$
declare
  v_row public.coupons%rowtype;
  v_window_start timestamptz;
  v_count int;
begin
  select window_start, count into v_window_start, v_count
    from public.coupon_check_rate_limit where id = true for update;
  if now() - v_window_start > interval '1 minute' then
    update public.coupon_check_rate_limit set window_start = now(), count = 1 where id = true;
  else
    if v_count >= 20 then
      raise exception 'Too many coupon checks right now -- please try again in a minute.';
    end if;
    update public.coupon_check_rate_limit set count = v_count + 1 where id = true;
  end if;

  select * into v_row from public.coupons where code = p_code;
  if v_row.id is null or v_row.used_at is not null then
    return query select 0::numeric, false;
    return;
  end if;
  if v_row.assigned_user_id is not null and v_row.assigned_user_id is distinct from auth.uid() then
    return query select 0::numeric, false;
    return;
  end if;
  return query select v_row.amount, true;
end;
$$;
grant execute on function public.check_coupon to anon, authenticated;

-- Customer: read their own notifications (My Account -> Notice tab).
create or replace function public.get_notifications()
returns setof public.notifications
language sql security definer set search_path = public as $$
  select * from public.notifications where user_id = auth.uid() order by created_at desc;
$$;
grant execute on function public.get_notifications to authenticated;

create or replace function public.mark_notifications_read()
returns void
language sql security definer set search_path = public as $$
  update public.notifications set read_at = now() where user_id = auth.uid() and read_at is null;
$$;
grant execute on function public.mark_notifications_read to authenticated;

-- 10. Support messages ----------------------------------------------
-- A general chat thread between a logged-in customer and GamePay support,
-- independent of any specific order (per-order chat in "messages" keeps
-- working exactly as before). Powers the customer-side "Message" tab and
-- the admin's per-user message box.
create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  sender text not null check (sender in ('customer','admin')),
  body text not null,
  created_at timestamptz not null default now()
);
alter table public.support_messages enable row level security;

drop policy if exists "customer read own support messages" on public.support_messages;
create policy "customer read own support messages" on public.support_messages
  for select using (auth.uid() = user_id);

drop policy if exists "customer send own support messages" on public.support_messages;
create policy "customer send own support messages" on public.support_messages
  for insert with check (auth.uid() = user_id and sender = 'customer');

drop policy if exists "admin manage support messages" on public.support_messages;
create policy "admin manage support messages" on public.support_messages
  for all using (public.is_admin()) with check (public.is_admin());

-- Optional image attachment (a screenshot, a payment slip, a promo image)
-- alongside or instead of body text -- body stays not-null (empty string
-- for an image-only message) so existing rows/constraints don't change.
alter table public.support_messages add column if not exists image_url text;

-- file_size_limit/allowed_mime_types: the bucket is public (chat
-- attachments need to load for both sides without a signed URL), so
-- without a size cap anyone with an account could use it as free,
-- unlimited public file hosting under our own domain.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-images', 'chat-images', true, 8388608, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "anyone can view chat images" on storage.objects;
create policy "anyone can view chat images" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'chat-images');

-- Both uploaders (index.html's customer chat, shinpayhubcld.html's admin
-- reply box) already upload under a fixed folder -- "<user_id>/..." for a
-- customer, "admin/..." for the admin -- so this just makes that the
-- enforced rule instead of trusting the client to keep doing it: a
-- customer can only write into their own folder, never pose as another
-- customer or as "admin/..." in the same shared public bucket.
drop policy if exists "authenticated can upload chat images" on storage.objects;
create policy "authenticated can upload chat images" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-images'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or ((storage.foldername(name))[1] = 'admin' and public.is_admin())
    )
  );

-- support_messages has no natural "one row per conversation" to hang an
-- admin_last_read_at on the way orders does -- this table gives it one,
-- so the admin's Messages inbox can compute unread counts/badges the
-- same way the per-order chat already does it.
create table if not exists public.support_read_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  admin_last_read_at timestamptz
);
alter table public.support_read_state enable row level security;

drop policy if exists "admin manage support read state" on public.support_read_state;
create policy "admin manage support read state" on public.support_read_state
  for all using (public.is_admin()) with check (public.is_admin());

-- 10. Stock overrides -------------------------------------------------
-- The product/plan catalog itself is still the static list baked into
-- index.html (no schema for it), so this is a thin overlay: for any
-- (product_id, plan_name) pair the admin has touched, the storefront
-- merges these fields on top of the catalog at render time. A row that's
-- never edited just doesn't exist -- the catalog's own price/outOfStock
-- keep being used until an admin overrides them here.
create table if not exists public.stock_overrides (
  product_id text not null,
  plan_name text not null,
  price numeric,
  out_of_stock boolean not null default false,
  low_stock boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  primary key (product_id, plan_name)
);
-- Lets admin edit a plan's Warranty/Format/Note straight from the Stock
-- list instead of needing a code deploy for every wording tweak -- null
-- means "keep using whatever index.html's own catalog already says".
alter table public.stock_overrides add column if not exists warranty text;
alter table public.stock_overrides add column if not exists format text;
alter table public.stock_overrides add column if not exists note text;
-- Percent off this plan's price (0-95), admin-set from the Stock list.
-- Null/0 means no discount -- the storefront keeps charging plain price.
alter table public.stock_overrides add column if not exists discount_percent numeric;
alter table public.stock_overrides enable row level security;

-- Anyone (including logged-out shoppers) needs to read this to see
-- accurate stock/price on the storefront.
drop policy if exists "anyone reads stock overrides" on public.stock_overrides;
create policy "anyone reads stock overrides" on public.stock_overrides
  for select using (true);

drop policy if exists "admin manage stock overrides" on public.stock_overrides;
create policy "admin manage stock overrides" on public.stock_overrides
  for all using (public.is_admin()) with check (public.is_admin());

-- 10b. Product overrides ------------------------------------------------
-- Same overlay idea as stock_overrides, but keyed by product_id alone
-- (not product_id + plan_name) for flags that apply to the whole product
-- card rather than one plan -- currently just "Hot", so admin can flag a
-- trending product from the Stock list without a code deploy.
create table if not exists public.product_overrides (
  product_id text primary key,
  hot boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);
alter table public.product_overrides enable row level security;

drop policy if exists "anyone reads product overrides" on public.product_overrides;
create policy "anyone reads product overrides" on public.product_overrides
  for select using (true);

drop policy if exists "admin manage product overrides" on public.product_overrides;
create policy "admin manage product overrides" on public.product_overrides
  for all using (public.is_admin()) with check (public.is_admin());

-- 10c. Catalog plans (server-side source of truth for pricing) -------
-- index.html's own "products" JS array stays the source of truth for
-- everything DISPLAY-related (descriptions, icons, benefit tables) --
-- this table exists purely so create_order can look up what a plan
-- should actually cost without trusting whatever amount the browser
-- sends. Regenerate by re-running the same extraction the Stock list's
-- CATALOG_MANIFEST uses, any time products/plans change in index.html.
create table if not exists public.catalog_plans (
  product_id text not null,
  plan_name text not null,  -- the plan's canonical name, exactly as index.html's
                             -- products[].plans[].name reads before any discount
                             -- rewrites it for display (plan._catalogName client-side)
  price numeric not null,
  custom boolean not null default false,  -- true = variable-amount plan (top-ups,
                                           -- followers, etc.) priced per base_amount
  base_amount numeric,       -- for custom plans: price is "per this many units"
  min_amount numeric,        -- for custom plans: smallest amount a customer may enter
  out_of_stock boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (product_id, plan_name)
);
alter table public.catalog_plans enable row level security;

-- Anyone needs to read this for checkout to work at all -- it's catalog
-- data, same as the plan names/prices already visible on the storefront,
-- not anything sensitive.
drop policy if exists "anyone reads catalog plans" on public.catalog_plans;
create policy "anyone reads catalog plans" on public.catalog_plans
  for select using (true);

-- Deliberately no insert/update/delete policy for anyone, admin included:
-- this table is only ever written by re-running this file's seed block
-- (service_role bypasses RLS), never through the app or an RPC. Keeping
-- it out of reach of create_order's own callers is the whole point --
-- see the note on create_order above.
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('chatgpt', 'CGPT GO Official – 8$ Plan – 1 Month – 27000 Ks', 27000, false, null, null, false),
('chatgpt', 'CHATGPT PLUS Official – 80$ Plan – 1 Month – 90000 Ks', 90000, false, null, null, false),
('chatgpt', 'CHATGPT PLUS – Private – 1 Month – 30000 Ks', 30000, false, null, null, false),
('chatgpt', 'CGPT GO – 3 Months – Preorder', 27000, false, null, null, true),
('chatgpt', 'ChatGPT Pro 5X – Own Mail – 1 Month – 450000 Ks', 450000, false, null, null, false),
('chatgpt', 'ChatGPT Pro 20X – Own Mail – 1 Month – 885000 Ks', 885000, false, null, null, false),
('canva', 'Canva Education – Own Mail – 1.5 Year – 5000 Ks', 5000, false, null, null, false),
('canva', 'Canva Education – Code Redeem – 1.5 Years – 5000 Ks', 5000, false, null, null, false),
('canva', 'Canva Business – Own Mail – 1 Month – 6000 Ks', 6000, false, null, null, false),
('canva', 'Canva Pro Individual – Private Acc – 1 Month – 7000 Ks', 7000, false, null, null, false),
('capcut', 'CapCut Team – Private Acc – 7 Days – 2000 Ks', 2000, false, null, null, false),
('capcut', 'CapCut Team – Private Acc – 1 Month – 8000 Ks', 8000, false, null, null, false),
('capcut', 'CapCut Pro Individual (crd 1200) – Private Acc – 34 Days – 12000 Ks', 12000, false, null, null, false),
('capcut', 'CapCut Individual – Private Acc – 6 Months – 50000 Ks', 50000, false, null, null, false),
('capcut', 'CapCut Team Head – Own Mail – 1 Month – Contact me', 0, true, null, null, false),
('gemini', 'Gemini AI Pro – Own Mail – 1 Month – 4000 Ks', 4000, false, null, null, false),
('gemini', 'Gemini AI Pro – Own Mail – 2 Months – 7000 Ks', 7000, false, null, null, false),
('gemini', 'Gemini AI Pro – Own Mail – 3 Months – 10000 Ks', 10000, false, null, null, false),
('gemini', 'Gemini AI Pro – Own Mail – 4 Months – 12000 Ks', 12000, false, null, null, false),
('gemini', 'Family Manager – Own Mail – 3 Months – 10000 Ks', 10000, false, null, null, false),
('gemini', 'Family Manager – Own Mail – 12 Months – 15000 Ks', 15000, false, null, null, false),
('gemini', 'Gemini Link – Own Mail – 1.5 Years – 8000 Ks', 8000, false, null, null, false),
('zoom', '🔐 Private – 14 Days – 5000 Ks', 5000, false, null, null, false),
('zoom', '🔐 Private – 1 Month – 8000 Ks', 8000, false, null, null, false),
('zoom', '🔐 Private – 2 Months – 15000 Ks', 15000, false, null, null, false),
('hbomax', '👤1 Profile - 8500 Ks
1 Month', 8500, false, null, null, false),
('hbomax', '👥2 Profiles - 13000 Ks
1 Month', 13000, false, null, null, false),
('hbomax', 'Each Profile - 6000 Ks
Above 3 Pf', 6000, false, null, null, false),
('hbomax', '🔥HBO Head - 25000 Ks
1 Month', 25000, false, null, null, false),
('picsart', '1 Month (👥Share) – 4000 Ks', 4000, false, null, null, false),
('picsart', '1 Month (🔐Private) – 5700 Ks', 5700, false, null, null, false),
('picsart', '3 Months – 14000 Ks', 14000, false, null, null, true),
('picsart', '1 Year – 50000 Ks', 50000, false, null, null, false),
('picsart', 'Own Mail - 1 Month – 24000 Ks', 24000, false, null, null, true),
('hma_vpn', '👥 1 Month – Share – 1400 Ks', 1400, false, null, null, false),
('hma_vpn', '🔐 1 Month – Private – 5000 Ks', 5000, false, null, null, false),
('hma_vpn', '✉️ 1 Month – Own Mail – 6000 Ks', 6000, false, null, null, false),
('vpn', '🔐 2 Months – 1 Device – 5000 Ks', 5000, false, null, null, false),
('vpn', '🔐 3 Months – 2 Devices – 7000 Ks', 7000, false, null, null, false),
('vpn', '🔐 6 Months – 4 Devices – 11000 Ks', 11000, false, null, null, false),
('vpn', '🔐 12 Months – 6 Devices – 15000 Ks', 15000, false, null, null, false),
('telegram', 'Login Method – 1 Month – 20500 Ks', 20500, false, null, null, false),
('telegram', 'Gift Plan – 3 Months – 50000 Ks', 50000, false, null, null, false),
('telegram', 'Gift Plan – 6 Months – 67000 Ks', 67000, false, null, null, false),
('telegram', 'Gift Plan – 9 Months – 118000 Ks', 118000, false, null, null, false),
('telegram', 'Link Plan – 3 Months – 44000 Ks', 44000, false, null, null, false),
('telegram', 'Link Plan – 6 Months – 65000 Ks', 65000, false, null, null, false),
('telegram', 'Link Plan – 12 Months – 118000 Ks', 118000, false, null, null, false),
('adobe_cc', '1 Month - 15000 Ks', 15000, false, null, null, false),
('adobe_cc', '2 Months - 25000 Ks', 25000, false, null, null, false),
('adobe_cc', '3 Months - 39000 Ks', 39000, false, null, null, false),
('adobe_cc', '6 Months - 35000 Ks', 35000, false, null, null, false),
('adobe_cc', '1 Year - 100000 Ks (Stock rare)', 100000, false, null, null, false),
('claude_ai', 'Claude PRO – 1 Month – 93000 Ks', 93000, false, null, null, false),
('claude_ai', 'Claude MAX – 1 Month – 500000 Ks', 500000, false, null, null, false),
('lovable', 'Lovable Pro Official – Own Mail – 1 Month – 120000 Ks', 120000, false, null, null, false),
('lovable', 'Lovable 300 Credits – 1 Month – 98000 Ks', 98000, false, null, null, false),
('lovable', 'Lovable Lite – 12 Months – 55000 Ks', 55000, false, null, null, false),
('lovable', 'Lovable Pro – 1 Month – 18000 Ks', 18000, false, null, null, false),
('supabase', 'Supabase Pro – Own Mail – 1 Month – 120000 Ks', 120000, false, null, null, false),
('notion', 'Notion Business – Own Mail – 3 Months – 31500 Ks', 31500, false, null, null, false),
('notion', 'Notion Business – Own Mail – 12 Months – 75000 Ks', 75000, false, null, null, false),
('cursor', 'Cursor Pro – 1 Month – 92000 Ks', 92000, false, null, null, false),
('cursor', 'Cursor Pro+ – 1 Month – 285000 Ks', 285000, false, null, null, false),
('cursor', 'Cursor Ultra – 1 Month – 920000 Ks', 920000, false, null, null, false),
('cursor', 'Cursor Ultra – 1 Month – 255000 Ks', 255000, false, null, null, false),
('grok', 'Super Grok – 1 Month – 58000 Ks', 58000, false, null, null, false),
('grok', 'Super Grok – 3 Months – 190000 Ks', 190000, false, null, null, false),
('grok', 'SuperGrok Plus – 1 Month – 480000 Ks', 480000, false, null, null, false),
('grok', 'SuperGrok Heavy – 1 Month – DM', 0, false, null, null, false),
('perplexity', 'Perplexity AI Pro – 1 Month – 43000 Ks', 43000, false, null, null, false),
('kling_ai', 'Standard Plan – 1 Month – 40000 Ks', 40000, false, null, null, false),
('kling_ai', 'Pro Plan – 1 Month – 130000 Ks', 130000, false, null, null, false),
('kling_ai', 'Premier Plan – 1 Month – 320000 Ks', 320000, false, null, null, false),
('kling_ai', 'Ultra Plan – 1 Month – 590000 Ks', 590000, false, null, null, false),
('kling_ai', '330 Credits – 26500 Ks', 26500, false, null, null, false),
('kling_ai', '660 Credits – 45500 Ks', 45500, false, null, null, false),
('kling_ai', '1320 Credits – 92500 Ks', 92500, false, null, null, false),
('kling_ai', '3500 Credits – 230000 Ks', 230000, false, null, null, false),
('suno_ai', 'Pro Plan – 1 Month – 50000 Ks', 50000, false, null, null, false),
('suno_ai', 'Premier Plan – 1 Month – 140000 Ks', 140000, false, null, null, false),
('gitHub copilot', 'GitHub Copilot Pro – 1 Month – 48000 Ks', 48000, false, null, null, false),
('gitHub copilot', 'GitHub Copilot Pro+ – 1 Month – 178000 Ks', 178000, false, null, null, false),
('gitHub copilot', 'GitHub Copilot Max – 1 Month – 480000 Ks', 480000, false, null, null, false),
('replit', 'Replit Core – 1 Month – 90000 Ks', 90000, false, null, null, false),
('replit', 'Replit Pro – 1 Month – 455000 Ks', 455000, false, null, null, false),
('railway', 'Railway Hobby – 1 Month – 26000 Ks', 26000, false, null, null, false),
('railway', 'Railway Pro – 1 Month – 48000 Ks', 48000, false, null, null, false),
('quillbot', 'Quillbot Premium – 1 Month – 8000 Ks', 8000, false, null, null, false),
('scribd', 'Scribd Premium – Private Acc – 1 Month – 7000 Ks', 7000, false, null, null, false),
('scribd', 'Scribd Premium – Own Mail – 1 Month – Contact me', 0, true, null, null, false),
('manus_ai', 'Standard – 1 Month – 90000 Ks', 90000, false, null, null, false),
('manus_ai', 'Customizable Plan – 1 Month – 183000 Ks', 183000, false, null, null, false),
('x_premium', 'X Premium – 1 Month – 30000 Ks', 30000, false, null, null, false),
('x_premium', 'X Premium Plus – 1 Month – 135000 Ks', 135000, false, null, null, false),
('whatsapp_plus', 'WhatsApp Plus – 1 Month – 22000 Ks', 22000, false, null, null, false),
('whatsapp_accounts', 'USA Number – 20000 Ks', 20000, false, null, null, false),
('whatsapp_accounts', 'Canada Number – 21000 Ks', 21000, false, null, null, false),
('whatsapp_accounts', 'France Number – 25000 Ks', 25000, false, null, null, false),
('netflix', '🌈(1 Profile) -8000 Ks
1 Month', 8000, false, null, null, false),
('netflix', '🌈(3 Profiles) - 19000 Ks
1 Month', 19000, false, null, null, false),
('netflix', '🌈(4 Profiles) - 25000 Ks
1 Month', 25000, false, null, null, false),
('netflix', '🌈(Head) - 25000 Ks
1 Month', 25000, false, null, null, false),
('spotify', '🔥 Individual Plan — 1 Month — 8000 Ks', 8000, false, null, null, false),
('spotify', '🔥 Individual Plan — 2 Months — 14000 Ks', 14000, false, null, null, false),
('spotify', '✨ Family Plan — 3 Months — 17000 Ks', 17000, false, null, null, false),
('tidal_music', '💥 Individual Plan — 1 Month — 8000 Ks', 8000, false, null, null, false),
('tidal_music', '💥 Family Plan — 1 Month — 8000 Ks', 8000, false, null, null, false),
('tidal_music', '💥 Family Plan — 2 Months — 10000 Ks', 10000, false, null, null, false),
('youtube_music', 'YouTube Music – Your Mail – 1 Month – 7000 Ks', 7000, false, null, null, false),
('soundcloud_go', 'SoundCloud Go — 1 Month — 8000 Ks', 8000, false, null, null, false),
('qobuz_music', 'Qobuz Music — 1 Month — 8000 Ks', 8000, false, null, null, false),
('apple_music', '💥 Individual Plan — 1 Month — 6000 Ks', 6000, false, null, null, false),
('apple_music', '💥 Family Plan — 1 Month — 6000 Ks', 6000, false, null, null, false),
('apple_music', '💥 Family Plan — 2 Months — 9000 Ks', 9000, false, null, null, false),
('apple_music', '💥 Family Plan — 3 Months — 11000 Ks', 11000, false, null, null, false),
('youtube', '🌐 Individual – Private Account – 1 Month – 6500 Ks', 6500, false, null, null, false),
('youtube', '🌐 Individual – 3 Months – 20000 Ks', 20000, false, null, null, false),
('youtube', '✉️ Individual – Invite Your Mail – 1 Month – 7000 Ks', 7000, false, null, null, false),
('youtube', '👑 Family Head Account – 1 Month – 30000 Ks', 30000, false, null, null, false),
('disney', 'Disney+ Premium - 1 Month - 7000 Ks', 7000, false, null, null, false),
('disney', 'Disney+ Duo - 1 Month - 8000 Ks', 8000, false, null, null, false),
('disney', 'Disney+ Trio - 1 Month - 10000 Ks', 10000, false, null, null, false),
('disney', 'Disney+ Premium - 3 Months - 8500 Ks', 8500, false, null, null, false),
('disney', 'Disney+ Duo - 3 Months - 12000 Ks', 12000, false, null, null, false),
('disney', 'Disney+ Trio - 3 Months - 15000 Ks', 15000, false, null, null, false),
('disney', 'Disney+ Premium - 12 Months - 20000 Ks', 20000, false, null, null, false),
('disney', 'Disney+ Duo - 12 Months - 22000 Ks', 22000, false, null, null, false),
('disney', 'Disney+ Trio - 12 Months - 30000 Ks', 30000, false, null, null, false),
('prime', 'Premium – 1 Month – 8000 Ks', 8000, false, null, null, false),
('prime', 'Premium – 6 Months – 20000 Ks', 20000, false, null, null, false),
('bigo', '50 Diamonds 💎 - 4200 Ks', 4200, false, null, null, false),
('bigo', '100 Diamonds 💎 - 8500 Ks', 8500, false, null, null, false),
('bigo', '150 Diamonds 💎 - 12980 Ks', 12980, false, null, null, false),
('bigo', '200 Diamonds 💎 - 16950 Ks', 16950, false, null, null, false),
('bigo', '250 Diamonds 💎 - 21200 Ks', 21200, false, null, null, false),
('bigo', '300 Diamonds 💎 - 25300 Ks', 25300, false, null, null, false),
('bigo', '400 Diamonds 💎 - 34200 Ks', 34200, false, null, null, false),
('bigo', '500 Diamonds 💎 - 42300 Ks', 42300, false, null, null, false),
('bigo', '750 Diamonds 💎 - 63200 Ks', 63200, false, null, null, false),
('bigo', '1000 Diamonds 💎 - 84580 Ks', 84580, false, null, null, false),
('bigo', '2000 Diamonds 💎 - 168700 Ks', 168700, false, null, null, false),
('bigo', '3000 Diamonds 💎 - 265060 Ks', 265060, false, null, null, false),
('facebook_service', '👥Followers(NoRefill)⚡', 5000, true, 1000, 500, false),
('facebook_service', '👥Followers (Refill / High Quality)🔥', 7000, true, 1000, 500, false),
('facebook_service', '👍Like 💥', 5000, true, 1000, 500, false),
('facebook_service', '❤️Love 💥', 5000, true, 1000, 500, false),
('facebook_service', '😂Haha 💥', 5000, true, 1000, 500, false),
('facebook_service', '😮Wow 💥', 5000, true, 1000, 500, false),
('facebook_service', '😢Sad 💥', 5000, true, 1000, 500, false),
('facebook_service', '😡Angry 💥', 5000, true, 1000, 500, false),
('facebook_service', '👍❤️🤣🥲😯 Mixed Reactions 💥', 6500, true, 1000, 500, false),
('facebook_service', '👥👁️Story Views 💯', 6500, true, 1000, 500, false),
('facebook_service', '📢 Facebook Ads 1️⃣💲 ⏩ 5600 Ks', 5600, true, 1, 5, false),
('🪙tiktok_coins_promote', '🪙Titok Coins 🪙', 5200, true, 100, 100, false),
('🪙tiktok_coins_promote', '🔥📈 TikTok Promote 💲💲', 6000, true, 1, 1, false),
('wink', 'Wink VIP – China Region – 7 Days – 2000 Ks', 2000, false, null, null, false),
('wink', 'Wink SVIP – China Region – 7 Days – 3000 Ks', 3000, false, null, null, false),
('wink', '👥Global Region – 1 Month – 7000 Ks (Share) – 1 Device', 8000, false, null, null, false),
('wink', '🔐Global Region – 1 Month – 18000 Ks (Private) – 3 Devices', 18000, false, null, null, false),
('wink', '🔐Global Region – 1 Year – 160000 Ks (Private) – 3 Devices', 160000, false, null, null, false),
('meitu', '👥VIP Plan (Share account) - 1 Month - 8000 Ks', 8000, false, null, null, false),
('meitu', '🔐VIP Plan (Private account) - 1 Month - 12000 Ks', 12000, false, null, null, false),
('meitu', '🔐VIP Plan (Private account) - 1 Year - 98000 Ks', 98000, false, null, null, false),
('meitu', '👥SVIP Plan (Share account) - 1 Month - 15000 Ks', 15000, false, null, null, false),
('meitu', '🔐SVIP Plan (Private account) - 1 Month - 22000 Ks', 22000, false, null, null, false),
('meitu', '🔐SVIP Plan (Private account) - 3 Months - 53000 Ks', 53000, false, null, null, false),
('meitu', '🔐SVIP Plan (Private account) - 1 Year - 160000 Ks', 160000, false, null, null, false),
('meitu', '✉️Own Mail VIP Plan - 1 Month - 12500 Ks', 12500, false, null, null, false),
('meitu', '✉️Own Mail SVIP Plan - 1 Month - 21000 Ks', 21000, false, null, null, false),
('meitu', '✉️Own Mail SVIP Plan - 3 Months - 54000 Ks', 54000, false, null, null, false),
('meitu', '✉️Own Mail SVIP Plan - 1 Year - 165000 Ks', 165000, false, null, null, false),
('steam', '5 USD - 23200 Ks', 23200, false, null, null, false),
('steam', '10 USD - 45000 Ks', 45000, false, null, null, false),
('steam', '20 USD - 90000 Ks', 90000, false, null, null, false),
('steam', '25 USD - 113000 Ks', 113000, false, null, null, false),
('steam', '30 USD - 137000 Ks', 137000, false, null, null, false),
('steam', '35 USD - 157000 Ks', 157000, false, null, null, false),
('steam', '50 USD - 228000 Ks', 228000, false, null, null, false),
('steam', '100 USD - 460000 Ks', 460000, false, null, null, false),
('duolingo', 'Individual Plan – 1 Month – 5000 Ks', 5000, false, null, null, false),
('duolingo', 'Family Plan – Coming Soon', 0, false, null, null, true),
('nordvpn', '👥 2 Months – Share – 8000 Ks', 8000, false, null, null, false),
('nordvpn', '🔐 2 Months – Private – 15000 Ks', 15000, false, null, null, false),
('nordvpn', '👥 3 Months – Share – 12000 Ks', 12000, false, null, null, false),
('nordvpn', '🔐 3 Months – Private – 22000 Ks', 22000, false, null, null, false),
('onevpn', '👥 1 Month – Share – 1600 Ks', 1600, false, null, null, false),
('onevpn', '🔐 1 Month – Private – 6000 Ks', 6000, false, null, null, false),
('surfshark', '👥 2 Months – Share – 6000 Ks', 6000, false, null, null, false),
('surfshark', '🔐 2 Months – Private – 28000 Ks', 28000, false, null, null, false),
('ypt_wallet', 'YPT Wallet – Wallet+One Visa or Master card – 180000 Ks', 180000, false, null, null, false),
('tevau_wallet', 'Tevau Wallet – Wallet+One Visacard – 160000 Ks', 160000, false, null, null, false)
on conflict (product_id, plan_name) do update set
  price = excluded.price, custom = excluded.custom, base_amount = excluded.base_amount,
  min_amount = excluded.min_amount, out_of_stock = excluded.out_of_stock, updated_at = now();

-- create_order no longer takes an amount from the client at all. It used
-- to (p_amount numeric, trusted as-is), which meant anyone with their
-- browser's devtools open could call create_order({ p_amount: 1, ... })
-- and buy anything for 1 Ks -- there was nothing server-side checking it
-- against a real price. Now it looks up what (p_product_id, p_plan_name)
-- should actually cost from catalog_plans + stock_overrides (section 10c,
-- above -- this function is defined after both on purpose, since its
-- %rowtype declarations below need them to already exist) and computes
-- the charge itself, mirroring the exact same math index.html's
-- own order-preview already shows (round() for a discount %, ceil() for
-- a custom per-unit amount), so what the customer previewed and what
-- they're charged always agree.
-- Drop every existing overload again (see the dynamic drop above) -- an
-- older argument list would otherwise stick around as a second overload,
-- and the unqualified "grant" further down fails with "function name is
-- not unique".
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'create_order'
  loop
    execute format('drop function if exists %s', r.sig);
  end loop;
end $$;

-- Still snapshots the plan's Warranty/Format/Note (as resolved on the
-- customer's screen at checkout, after any Stock-list overrides) onto the
-- order row itself, so the order's own chat/detail view can show exactly
-- what the customer was promised even if the plan's info changes later --
-- those three fields aren't money, so there's no reason not to keep
-- trusting the client's snapshot of them the way the rest of this
-- function trusts nothing about the price.
create or replace function public.create_order(
  p_product_id text,
  p_product_name text,
  p_plan_name text,
  p_payment_method text,
  p_account_info text,
  p_note text,
  p_payment_slip_path text default null,
  p_coupon_code text default null,
  p_plan_warranty text default null,
  p_plan_format text default null,
  p_plan_note text default null,
  p_qty numeric default 1,
  p_custom_amount numeric default null
) returns table (id uuid, access_token uuid, order_code text, amount numeric)
language plpgsql security definer set search_path = public as $$
declare
  v_code text := 'GPH-' || to_char(now(),'YYYYMMDD') || '-' || substr(replace(gen_random_uuid()::text,'-',''),1,5);
  v_catalog public.catalog_plans%rowtype;
  v_override public.stock_overrides%rowtype;
  v_base_price numeric;
  v_discount_pct numeric;
  v_unit_price numeric;
  v_amount numeric;
  v_coupon public.coupons%rowtype;
  v_coupon_discount numeric := 0;
  v_order_id uuid;
  v_access_token uuid;
begin
  select * into v_catalog from public.catalog_plans
    where product_id = p_product_id and plan_name = p_plan_name;
  if v_catalog.product_id is null then
    raise exception 'Unknown product or plan -- please refresh and try again.';
  end if;

  select * into v_override from public.stock_overrides
    where product_id = p_product_id and plan_name = p_plan_name;

  if coalesce(v_override.out_of_stock, v_catalog.out_of_stock) then
    raise exception 'This plan is currently out of stock.';
  end if;

  -- Admin's Stock-list price override wins when set (price > 0 means
  -- "set", matching how the storefront's own applyStockOverrides() treats
  -- a 0/blank override price as "no override"); otherwise the catalog's
  -- own price. discount_percent then applies on top, same as the
  -- storefront already shows it.
  v_base_price := v_catalog.price;
  if v_override.price is not null and v_override.price > 0 then
    v_base_price := v_override.price;
  end if;

  v_discount_pct := least(95, greatest(0, coalesce(v_override.discount_percent, 0)));
  v_unit_price := case when v_discount_pct > 0
    then round(v_base_price * (1 - v_discount_pct / 100))
    else v_base_price end;

  if v_catalog.custom then
    if v_catalog.base_amount is null or v_catalog.base_amount <= 0 then
      raise exception 'This plan can''t be ordered online -- please message us directly.';
    end if;
    if p_custom_amount is null or p_custom_amount < coalesce(v_catalog.min_amount, 1) then
      raise exception 'Please enter a valid amount for this plan.';
    end if;
    v_amount := ceil((p_custom_amount / v_catalog.base_amount) * v_unit_price);
  else
    v_amount := v_unit_price * greatest(1, coalesce(p_qty, 1));
  end if;

  if p_coupon_code is not null then
    select * into v_coupon from public.coupons where code = p_coupon_code for update;
    if v_coupon.id is not null and v_coupon.used_at is null
       and (v_coupon.assigned_user_id is null or v_coupon.assigned_user_id = auth.uid()) then
      v_coupon_discount := least(v_coupon.amount, v_amount);
    end if;
  end if;

  insert into public.orders(product_name, plan_name, amount, payment_method, account_info, note, order_code, payment_slip_path, user_id, coupon_code, discount_amount, plan_warranty, plan_format, plan_note)
  values (p_product_name, p_plan_name, v_amount - v_coupon_discount, p_payment_method, p_account_info, p_note, v_code, p_payment_slip_path, auth.uid(),
          case when v_coupon_discount > 0 then p_coupon_code else null end, v_coupon_discount, p_plan_warranty, p_plan_format, p_plan_note)
  returning orders.id, orders.access_token into v_order_id, v_access_token;

  if v_coupon_discount > 0 then
    -- "id" alone here is ambiguous: this function's own RETURNS TABLE
    -- declares an out parameter named "id" too, which PL/pgSQL also sees
    -- in scope here -- found by writing a real coupon-redemption test
    -- for this change and watching it fail with exactly that error, on
    -- a line that already shipped unchanged in the previous version of
    -- this function. Qualifying it is the fix in both places.
    update public.coupons set used_at = now(), used_by_user_id = auth.uid(), used_by_order_id = v_order_id where coupons.id = v_coupon.id;
  end if;

  return query select v_order_id, v_access_token, v_code, v_amount - v_coupon_discount;
end;
$$;
grant execute on function public.create_order to anon, authenticated;

-- 11. Dashboard access code -----------------------------------------
-- A second lock in front of shinpayhubcld.html's login, entirely separate
-- from Supabase Auth: checked before email/password are ever tried, so a
-- correct account alone isn't enough to get in. RLS has zero policies on
-- this table (not even for admins) -- both RPCs below are the only way
-- in or out, and check_admin_gate_code only ever returns true/false,
-- never the stored code itself, even to a logged-in admin.
create table if not exists public.admin_gate (
  id boolean primary key default true check (id),
  code text,
  updated_at timestamptz not null default now()
);
alter table public.admin_gate enable row level security;
-- Was storing the gate code as plain text -- anyone who ever saw the
-- table (a dashboard screen-share, a future reader of this file's own
-- data) would see the real code. Hash it with pgcrypto's bcrypt (already
-- enabled at the top of this file) instead; check_admin_gate_code below
-- transparently upgrades an old plaintext row to a hash the first time
-- it's matched, so re-running this file on an existing project doesn't
-- require resetting the code by hand.
alter table public.admin_gate add column if not exists failed_attempts int not null default 0;
alter table public.admin_gate add column if not exists locked_until timestamptz;

create or replace function public.check_admin_gate_code(p_code text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare v_code text; v_locked_until timestamptz; v_failed int; v_match boolean;
begin
  select code, locked_until, failed_attempts into v_code, v_locked_until, v_failed
  from public.admin_gate where id = true;

  -- No code configured yet -- stay reachable so first-time setup (logging
  -- in once with just email/password to set the code from Settings) works.
  if v_code is null then
    return true;
  end if;

  -- Locked out from too many recent wrong guesses -- refuse without even
  -- looking at p_code, so a script retrying as fast as it can still only
  -- gets a few guesses every 15 minutes.
  if v_locked_until is not null and v_locked_until > now() then
    return false;
  end if;

  -- bcrypt hashes always start with "$2"; anything else is a leftover
  -- plaintext code from before this column was hashed.
  if v_code like '$2%' then
    v_match := (crypt(p_code, v_code) = v_code);
  else
    v_match := (v_code = p_code);
    if v_match then
      -- Right code, old plaintext row -- upgrade it to a hash now.
      update public.admin_gate set code = crypt(p_code, gen_salt('bf')) where id = true;
    end if;
  end if;

  if v_match then
    update public.admin_gate set failed_attempts = 0, locked_until = null where id = true;
  else
    v_failed := v_failed + 1;
    update public.admin_gate set
      failed_attempts = v_failed,
      locked_until = case when v_failed >= 8 then now() + interval '15 minutes' else locked_until end
    where id = true;
  end if;
  return v_match;
end;
$$;
grant execute on function public.check_admin_gate_code to anon, authenticated;

create or replace function public.set_admin_gate_code(p_current text, p_new text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare v_code text; v_match boolean;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  select code into v_code from public.admin_gate where id = true;
  if v_code is not null then
    v_match := case when v_code like '$2%' then crypt(p_current, v_code) = v_code else v_code = p_current end;
    if not v_match then
      raise exception 'current code is incorrect';
    end if;
  end if;
  insert into public.admin_gate (id, code, updated_at, failed_attempts, locked_until)
    values (true, crypt(p_new, gen_salt('bf')), now(), 0, null)
    on conflict (id) do update set code = excluded.code, updated_at = excluded.updated_at,
      failed_attempts = 0, locked_until = null;
  return true;
end;
$$;
grant execute on function public.set_admin_gate_code to authenticated;

-- ---------------------------------------------------------------------
-- News: admin-authored posts shown on the storefront, Twitter/X-feed
-- style. Read-only for customers by design (no likes/comments), fully
-- admin-managed. The bucket is public -- news images are meant to be
-- seen by anyone browsing the site, logged in or not, same as the
-- product catalog's own images.
-- ---------------------------------------------------------------------
create table if not exists public.news_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  images text[] not null default '{}',
  excerpt text,
  link_url text,
  link_label text,
  caption text,
  source text,
  is_offer boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);
alter table public.news_posts enable row level security;

drop policy if exists "anyone can read news" on public.news_posts;
create policy "anyone can read news" on public.news_posts
  for select using (true);

drop policy if exists "admin manage news" on public.news_posts;
create policy "admin manage news" on public.news_posts
  for all using (public.is_admin()) with check (public.is_admin());

insert into storage.buckets (id, name, public)
values ('news-images', 'news-images', true)
on conflict (id) do nothing;

drop policy if exists "anyone can view news images" on storage.objects;
create policy "anyone can view news images" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'news-images');

drop policy if exists "admin can upload news images" on storage.objects;
create policy "admin can upload news images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'news-images' and public.is_admin());

drop policy if exists "admin can delete news images" on storage.objects;
create policy "admin can delete news images" on storage.objects
  for delete to authenticated
  using (bucket_id = 'news-images' and public.is_admin());

-- 11. Referrals -------------------------------------------------
-- A customer's own username doubles as their referral code (no separate
-- code to generate/store). A new signup enters the code they were given;
-- once they're logged in, submit_referral() records the link as
-- "pending". Nothing is granted automatically -- admin reviews the list
-- and confirms each one by hand, gifting a coupon of whatever amount
-- they choose (2000 Ks is just the number advertised to customers, not
-- a hardcoded value here).
create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references auth.users(id) on delete cascade,
  referred_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','confirmed')),
  reward_amount numeric,
  coupon_code text,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  unique(referred_id)
);
alter table public.referrals enable row level security;

drop policy if exists "customer read own referrals" on public.referrals;
create policy "customer read own referrals" on public.referrals
  for select using (auth.uid() = referrer_id or auth.uid() = referred_id);

drop policy if exists "admin manage referrals" on public.referrals;
create policy "admin manage referrals" on public.referrals
  for all using (public.is_admin()) with check (public.is_admin());

-- The referred side's own welcome coupon (issued instantly by
-- submit_referral() below), tracked separately from the referrer's
-- coupon/reward_amount columns above so admin can see both halves of
-- one referral.
alter table public.referrals add column if not exists referred_coupon_code text;
alter table public.referrals add column if not exists referred_coupon_amount numeric;

-- Customer: submit the referral code they signed up with. security
-- definer because a plain insert policy would let a customer set an
-- arbitrary referrer_id/referred_id pair themselves; this looks the
-- code up server-side and silently no-ops on an unknown code or a
-- self-referral instead of erroring the signup flow over it. Unlike the
-- referrer's coupon (admin-confirmed, admin-chosen amount), the signer-up
-- gets their welcome coupon immediately, no approval needed -- returns it
-- so the client can show a confetti popup right away.
-- Postgres can't CREATE OR REPLACE a function whose return type changed
-- (void -> table(...)) -- has to be dropped first.
drop function if exists public.submit_referral(text);

create or replace function public.submit_referral(p_code text)
returns table(coupon_code text, coupon_amount numeric)
language plpgsql security definer set search_path = public as $$
declare v_referrer_id uuid; v_code text; v_amount numeric;
begin
  select id into v_referrer_id from auth.users
  where raw_user_meta_data->>'username' = p_code
  limit 1;
  if v_referrer_id is null or v_referrer_id = auth.uid() then
    return;
  end if;

  select value into v_amount from public.app_settings where key = 'welcome_coupon_amount';
  if v_amount is null then v_amount := 2000; end if;

  insert into public.referrals(referrer_id, referred_id)
  values (v_referrer_id, auth.uid())
  on conflict (referred_id) do nothing;
  if not found then
    return; -- already referred before -- never issue a second welcome coupon
  end if;

  v_code := 'WELCOME' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
  insert into public.coupons(code, amount, assigned_user_id, created_by)
  values (v_code, v_amount, auth.uid(), v_referrer_id);
  insert into public.notifications(user_id, title, body)
  values (
    auth.uid(), 'Welcome coupon!',
    'Thanks for joining with a referral code! Here''s your coupon: ' || v_code || ' (worth ' || v_amount || ' Ks). Enter it at checkout to use it!'
  );
  update public.referrals set referred_coupon_code = v_code, referred_coupon_amount = v_amount
  where referrer_id = v_referrer_id and referred_id = auth.uid();

  return query select v_code, v_amount;
end;
$$;
grant execute on function public.submit_referral to authenticated;

-- Customer: their own referral stats for the My Account "Referral" card
-- (how many people they've referred, confirmed vs. still pending).
create or replace function public.my_referral_stats()
returns table(pending_count bigint, confirmed_count bigint)
language sql security definer set search_path = public as $$
  select
    count(*) filter (where status = 'pending'),
    count(*) filter (where status = 'confirmed')
  from public.referrals where referrer_id = auth.uid();
$$;
grant execute on function public.my_referral_stats to authenticated;

-- Admin: full referral list (both sides' username/email) for the
-- dashboard's Referrals tab.
-- Postgres can't CREATE OR REPLACE a function whose return columns changed
-- (added coupon_active/referred_coupon_*) -- has to be dropped first.
drop function if exists public.admin_list_referrals();

create or replace function public.admin_list_referrals()
returns table(
  id uuid, status text, reward_amount numeric, coupon_code text, coupon_active boolean,
  referred_coupon_code text, referred_coupon_amount numeric, referred_coupon_active boolean,
  created_at timestamptz, confirmed_at timestamptz,
  referrer_id uuid, referrer_email text, referrer_username text,
  referred_id uuid, referred_email text, referred_username text
)
language sql security definer set search_path = public as $$
  select
    r.id, r.status, r.reward_amount, r.coupon_code, (c1.used_at is null) as coupon_active,
    r.referred_coupon_code, r.referred_coupon_amount, (c2.used_at is null) as referred_coupon_active,
    r.created_at, r.confirmed_at,
    ru.id, ru.email, ru.raw_user_meta_data->>'username',
    rd.id, rd.email, rd.raw_user_meta_data->>'username'
  from public.referrals r
  join auth.users ru on ru.id = r.referrer_id
  join auth.users rd on rd.id = r.referred_id
  left join public.coupons c1 on c1.code = r.coupon_code
  left join public.coupons c2 on c2.code = r.referred_coupon_code
  where public.is_admin()
  order by (r.status = 'pending') desc, r.created_at desc;
$$;
grant execute on function public.admin_list_referrals to authenticated;

-- Admin: confirm one referral -- gifts the referrer a coupon (amount and
-- code both chosen by the admin at confirm time) and notifies them,
-- reusing the exact coupon+notification pattern admin_create_coupon uses.
create or replace function public.admin_confirm_referral(p_referral_id uuid, p_code text, p_amount numeric)
returns void
language plpgsql security definer set search_path = public as $$
declare v_referrer_id uuid; v_status text;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  select referrer_id, status into v_referrer_id, v_status from public.referrals where id = p_referral_id;
  if v_referrer_id is null then raise exception 'referral not found'; end if;
  if v_status = 'confirmed' then raise exception 'already confirmed'; end if;

  insert into public.coupons(code, amount, assigned_user_id, created_by)
  values (p_code, p_amount, v_referrer_id, auth.uid());

  insert into public.notifications(user_id, title, body)
  values (
    v_referrer_id, 'Referral reward!',
    'Thanks for referring a friend to GamePay Hub! Here''s your coupon code: ' || p_code || ' (worth ' || p_amount || ' Ks). Enter it at checkout to use it!'
  );

  update public.referrals set status = 'confirmed', reward_amount = p_amount, coupon_code = p_code, confirmed_at = now()
  where id = p_referral_id;
end;
$$;
grant execute on function public.admin_confirm_referral to authenticated;

-- Customer profile photos -- one bucket, each user's files scoped to a
-- <user_id>/ folder of their own so the upload/overwrite policies can be
-- ownership-checked (unlike chat-images, where anyone-can-upload is fine
-- since it's just chat attachments).
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "anyone can view avatars" on storage.objects;
create policy "anyone can view avatars" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'avatars');

drop policy if exists "users can upload their own avatar" on storage.objects;
create policy "users can upload their own avatar" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "users can replace their own avatar" on storage.objects;
create policy "users can replace their own avatar" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- Admin-curated avatar gallery -- customers pick their profile picture from
-- this list instead of uploading an arbitrary photo of their own; each
-- picture is paired with one of a small fixed set of background colors
-- (chosen by the admin at upload time, see AVATAR_BG_PALETTE client-side).
-- The image itself is just another file in the avatars bucket above,
-- uploaded under the admin's own <user_id>/presets/ folder -- the existing
-- upload policy already covers that since admin is an authenticated user
-- like any other.
create table if not exists public.avatar_presets (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  bg_color text not null default 'white-glass',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
alter table public.avatar_presets enable row level security;

drop policy if exists "anyone can view avatar presets" on public.avatar_presets;
create policy "anyone can view avatar presets" on public.avatar_presets
  for select to anon, authenticated using (true);

drop policy if exists "admin manage avatar presets" on public.avatar_presets;
create policy "admin manage avatar presets" on public.avatar_presets
  for all using (public.is_admin()) with check (public.is_admin());

-- Small admin-editable key/value settings table -- currently just the
-- default amount for the referred side's instant welcome coupon (was
-- hardcoded to 2000 in submit_referral() below), so the admin dashboard's
-- Referrals tab can change it without touching this file again.
create table if not exists public.app_settings (
  key text primary key,
  value numeric not null
);
insert into public.app_settings(key, value) values ('welcome_coupon_amount', 2000)
  on conflict (key) do nothing;
alter table public.app_settings enable row level security;
drop policy if exists "admin manage app settings" on public.app_settings;
create policy "admin manage app settings" on public.app_settings
  for all using (public.is_admin()) with check (public.is_admin());

-- Every other admin_* function in this file gates on is_admin() -- this
-- one didn't, so any logged-in customer could read it directly. The
-- value itself is low-stakes (just the welcome-coupon amount), but the
-- gap was inconsistent with the rest of the file and worth closing.
create or replace function public.admin_get_welcome_coupon_amount()
returns numeric
language sql security definer set search_path = public as $$
  select value from public.app_settings where key = 'welcome_coupon_amount' and public.is_admin();
$$;
grant execute on function public.admin_get_welcome_coupon_amount to authenticated;

create or replace function public.admin_set_welcome_coupon_amount(p_amount numeric)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  insert into public.app_settings(key, value) values ('welcome_coupon_amount', p_amount)
    on conflict (key) do update set value = excluded.value;
end;
$$;
grant execute on function public.admin_set_welcome_coupon_amount to authenticated;

-- Telegram account linking -- this app has no Telegram Bot API integration,
-- so "verification" is the admin manually checking the submitted username
-- against the real Telegram account (from the dashboard's Users tab) before
-- confirming it. Every step is reversible: the customer can cancel a
-- pending request or unlink an already-confirmed one (same action, delete
-- the row -- just a different button label client-side depending on
-- status), and the admin can unlink from their side too.
create table if not exists public.telegram_links (
  user_id uuid primary key references auth.users(id) on delete cascade,
  telegram_username text not null,
  status text not null default 'pending' check (status in ('pending','linked')),
  submitted_at timestamptz not null default now(),
  confirmed_at timestamptz,
  confirmed_by uuid references auth.users(id)
);
alter table public.telegram_links enable row level security;

drop policy if exists "read own or admin telegram link" on public.telegram_links;
create policy "read own or admin telegram link" on public.telegram_links
  for select using (auth.uid() = user_id or public.is_admin());

-- Customer: submit (or resubmit) a Telegram username for verification.
-- Resubmitting always resets to pending, even over an already-linked row --
-- changing your Telegram means it needs re-verifying.
create or replace function public.submit_telegram_link(p_username text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_username is null or length(trim(p_username)) = 0 then
    raise exception 'username required';
  end if;
  insert into public.telegram_links(user_id, telegram_username, status, submitted_at, confirmed_at, confirmed_by)
  values (auth.uid(), trim(p_username), 'pending', now(), null, null)
  on conflict (user_id) do update
    set telegram_username = excluded.telegram_username,
        status = 'pending', submitted_at = now(), confirmed_at = null, confirmed_by = null;
end;
$$;
grant execute on function public.submit_telegram_link to authenticated;

-- Customer: cancel a pending request, or unlink an already-confirmed one.
create or replace function public.unlink_telegram_link()
returns void
language sql security definer set search_path = public as $$
  delete from public.telegram_links where user_id = auth.uid();
$$;
grant execute on function public.unlink_telegram_link to authenticated;

-- Admin: confirm a pending request as verified.
create or replace function public.admin_confirm_telegram_link(p_user_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  update public.telegram_links set status = 'linked', confirmed_at = now(), confirmed_by = auth.uid()
  where user_id = p_user_id;
  if not found then raise exception 'no pending request for this user'; end if;
end;
$$;
grant execute on function public.admin_confirm_telegram_link to authenticated;

-- Admin: reject a pending request, or unlink an already-confirmed one from
-- the admin side.
create or replace function public.admin_unlink_telegram_link(p_user_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  delete from public.telegram_links where user_id = p_user_id;
end;
$$;
grant execute on function public.admin_unlink_telegram_link to authenticated;

-- 13. Email change alerts ------------------------------------------
-- This app has no Telegram Bot API integration (see the manual-review
-- note on telegram_links above), so email-change visibility for admins
-- is surfaced here instead, in the dashboard.
--
-- Supabase Auth handles the actual email swap entirely on its own:
-- auth.updateUser({ email }) sends a confirmation to the new address
-- (and, if "Secure email change" is on, to the old one too); auth.users
-- keeps the OLD email live and working until every required link is
-- confirmed, then flips the single email column to the new value in
-- place -- there is never a second row or a lingering old value to
-- clean up by hand.
--
-- "requested" rows are logged by the client right before it calls
-- auth.updateUser({ email }), so admins see a change in flight
-- immediately; the trigger below flips the matching row to "completed"
-- only when auth.users.email actually changes to that new value, i.e.
-- once Supabase Auth has finished confirming it.
create table if not exists public.email_change_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  old_email text not null,
  new_email text not null,
  status text not null default 'requested' check (status in ('requested','completed')),
  requested_at timestamptz not null default now(),
  completed_at timestamptz
);
alter table public.email_change_events enable row level security;

drop policy if exists "admin read email change events" on public.email_change_events;
create policy "admin read email change events" on public.email_change_events
  for select using (public.is_admin());

create or replace function public.log_email_change_request(p_new_email text)
returns void
language plpgsql security definer set search_path = public as $$
declare v_old_email text;
begin
  select email into v_old_email from auth.users where id = auth.uid();
  if v_old_email is null then
    raise exception 'not authenticated';
  end if;
  insert into public.email_change_events (user_id, old_email, new_email, status)
  values (auth.uid(), v_old_email, p_new_email, 'requested');
end;
$$;
grant execute on function public.log_email_change_request to authenticated;

create or replace function public.admin_list_email_change_events(p_limit int default 30)
returns table(id bigint, user_id uuid, old_email text, new_email text, status text, requested_at timestamptz, completed_at timestamptz)
language sql security definer set search_path = public as $$
  select id, user_id, old_email, new_email, status, requested_at, completed_at
  from public.email_change_events
  where public.is_admin()
  order by requested_at desc
  limit p_limit;
$$;
grant execute on function public.admin_list_email_change_events to authenticated;

create or replace function public.mark_email_change_completed()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.email is distinct from old.email then
    update public.email_change_events
    set status = 'completed', completed_at = now()
    where user_id = new.id and new_email = new.email and status = 'requested';
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
  after update on auth.users
  for each row execute function public.mark_email_change_completed();

-- ============================================================
-- One-time setup after running this file:
-- 1. Create your own admin login: Authentication -> Users -> Add user
--    (use your real email + a strong password). Use an email that's
--    dedicated to this and never used as a regular customer login --
--    otherwise "clean up test accounts" in Authentication can delete
--    your own admin access along with it (public.admins cascades on
--    that user being deleted).
-- 2. Make that user an admin by running (replace the email):
--
--    insert into public.admins (user_id)
--    select id from auth.users where email = 'you@example.com';
--
-- 3. Enable Realtime for the tables: Database -> Replication ->
--    turn on "orders", "messages", and "support_messages" so
--    shinpayhubcld.html gets live updates (including the Messages
--    inbox's unread badge).
--
-- 4. Customer login (email/password) works out of the box once this
--    file has run — no extra dashboard step needed for that. If you
--    want to REQUIRE email confirmation before a customer can log in,
--    turn it on under Authentication -> Providers -> Email.
--
-- 5. Dashboard access code: no code is required until you set one. Log
--    into shinpayhubcld.html once (leave the "Access code" field blank),
--    then set one under Settings -> Dashboard Access Code. From then on
--    that code is required on every login, checked before email/password.
-- ============================================================
