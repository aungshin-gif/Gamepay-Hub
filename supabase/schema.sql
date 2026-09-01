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
drop function if exists public.create_order(text, text, numeric, text, text, text);

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
