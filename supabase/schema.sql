-- ============================================================
-- GamePay Hub — Order + Chat backend
--
-- How to run this: Supabase Dashboard -> SQL Editor -> New query
-- -> paste this whole file -> Run. Safe to re-run (uses IF NOT EXISTS
-- and CREATE OR REPLACE), so re-running after an edit won't duplicate data.
-- ============================================================

create extension if not exists pgcrypto;

-- 1. Orders -----------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  access_token uuid not null default gen_random_uuid(), -- the customer's private "ticket" to their own order
  order_code text not null unique,
  product_name text not null,
  plan_name text not null,
  amount numeric not null default 0,
  payment_method text,
  account_info text,
  note text,
  status text not null default 'pending' check (status in ('pending','approved','rejected','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Chat messages, one thread per order -------------------------
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  sender text not null check (sender in ('customer','admin')),
  body text not null,
  created_at timestamptz not null default now()
);

-- 3. Admin allow-list (who may use admin.html) --------------------
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

-- Admins (logged in via admin.html AND listed in public.admins) can
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

-- Customers (not logged in) get NO policy on orders/messages at all —
-- meaning the anon key alone can never list or read every order. The
-- only way in is through the four functions below, and only if you
-- already hold the exact access_token (the customer's private order link).

create or replace function public.create_order(
  p_product_name text, p_plan_name text, p_amount numeric,
  p_payment_method text, p_account_info text, p_note text
) returns table (id uuid, access_token uuid, order_code text)
language plpgsql security definer set search_path = public as $$
declare
  v_code text := 'GPH-' || to_char(now(),'YYYYMMDD') || '-' || substr(replace(gen_random_uuid()::text,'-',''),1,5);
begin
  return query
  insert into public.orders(product_name, plan_name, amount, payment_method, account_info, note, order_code)
  values (p_product_name, p_plan_name, p_amount, p_payment_method, p_account_info, p_note, v_code)
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

-- The anon (public) key may call only these four functions —
-- never the raw tables.
grant execute on function public.create_order to anon;
grant execute on function public.get_order_status to anon;
grant execute on function public.get_messages to anon;
grant execute on function public.send_customer_message to anon;

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
--    turn on "orders" and "messages" so admin.html gets live updates.
-- ============================================================
