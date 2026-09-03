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
-- than replacing it, so an older 6-argument version of this function
-- (from before payment slips existed) would otherwise stick around and
-- make every call to "create_order" ambiguous. Drop it explicitly first.
-- Also drop the later 8-argument version (with a coupon code, defined
-- further down in this file) -- otherwise re-running this whole script on
-- a database that already has it leaves two overloads alive at once for
-- the moment this block recreates the 7-argument one, and the "grant"
-- right below fails with "function name is not unique".
drop function if exists public.create_order(text, text, numeric, text, text, text);
drop function if exists public.create_order(text, text, numeric, text, text, text, text, text);

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
declare v_order_id uuid;
begin
  select id into v_order_id from public.orders where access_token = p_token;
  if v_order_id is null then
    raise exception 'invalid order token';
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
insert into storage.buckets (id, name, public)
values ('payment-slips', 'payment-slips', false)
on conflict (id) do nothing;

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

drop policy if exists "customer mark own notifications read" on public.notifications;
create policy "customer mark own notifications read" on public.notifications
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

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
create or replace function public.admin_list_users()
returns table(id uuid, email text, created_at timestamptz, order_count bigint)
language sql security definer set search_path = public as $$
  select u.id, u.email, u.created_at, count(o.id) as order_count
  from auth.users u
  left join public.orders o on o.user_id = u.id
  where public.is_admin()
  group by u.id, u.email, u.created_at
  order by u.created_at desc;
$$;
grant execute on function public.admin_list_users to authenticated;

-- Customer (or guest, for a public code): check a coupon at checkout
-- without consuming it -- create_order is what actually redeems it.
create or replace function public.check_coupon(p_code text)
returns table(amount numeric, valid boolean)
language plpgsql security definer set search_path = public as $$
declare v_row public.coupons%rowtype;
begin
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

-- create_order now accepts an optional coupon code. The discount is
-- computed and the coupon marked used here -- never trust a client-sent
-- discount, always re-derive it from the coupon row server-side.
drop function if exists public.create_order(text, text, numeric, text, text, text, text);

create or replace function public.create_order(
  p_product_name text, p_plan_name text, p_amount numeric,
  p_payment_method text, p_account_info text, p_note text,
  p_payment_slip_path text default null,
  p_coupon_code text default null
) returns table (id uuid, access_token uuid, order_code text)
language plpgsql security definer set search_path = public as $$
declare
  v_code text := 'GPH-' || to_char(now(),'YYYYMMDD') || '-' || substr(replace(gen_random_uuid()::text,'-',''),1,5);
  v_coupon public.coupons%rowtype;
  v_discount numeric := 0;
  v_order_id uuid;
  v_access_token uuid;
begin
  if p_coupon_code is not null then
    select * into v_coupon from public.coupons where code = p_coupon_code for update;
    if v_coupon.id is not null and v_coupon.used_at is null
       and (v_coupon.assigned_user_id is null or v_coupon.assigned_user_id = auth.uid()) then
      v_discount := least(v_coupon.amount, p_amount);
    end if;
  end if;

  insert into public.orders(product_name, plan_name, amount, payment_method, account_info, note, order_code, payment_slip_path, user_id, coupon_code, discount_amount)
  values (p_product_name, p_plan_name, p_amount - v_discount, p_payment_method, p_account_info, p_note, v_code, p_payment_slip_path, auth.uid(),
          case when v_discount > 0 then p_coupon_code else null end, v_discount)
  returning orders.id, orders.access_token into v_order_id, v_access_token;

  if v_discount > 0 then
    update public.coupons set used_at = now(), used_by_user_id = auth.uid(), used_by_order_id = v_order_id where id = v_coupon.id;
  end if;

  return query select v_order_id, v_access_token, v_code;
end;
$$;
grant execute on function public.create_order to anon, authenticated;

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
alter table public.stock_overrides enable row level security;

-- Anyone (including logged-out shoppers) needs to read this to see
-- accurate stock/price on the storefront.
drop policy if exists "anyone reads stock overrides" on public.stock_overrides;
create policy "anyone reads stock overrides" on public.stock_overrides
  for select using (true);

drop policy if exists "admin manage stock overrides" on public.stock_overrides;
create policy "admin manage stock overrides" on public.stock_overrides
  for all using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- One-time setup after running this file:
-- 1. Create your own admin login: Authentication -> Users -> Add user
--    (use your real email + a strong password).
-- 2. Make that user an admin by running (replace the email):
--
--    insert into public.admins (user_id)
--    select id from auth.users where email = 'you@example.com';
--
-- 3. Enable Realtime for the tables: Database -> Replication ->
--    turn on "orders" and "messages" so shinpayhubcld.html gets live updates.
--
-- 4. Customer login (email/password) works out of the box once this
--    file has run — no extra dashboard step needed for that. If you
--    want to REQUIRE email confirmation before a customer can log in,
--    turn it on under Authentication -> Providers -> Email.
-- ============================================================
