-- Orders now require a logged-in account. The site shows a "Create an
-- account first" popup, but the create_order RPC was still callable with
-- just the public anon key, so a guest could place an order by calling it
-- directly. Same function as before plus a guard at the top.
-- Apply AFTER the matching index.html is live, so guests see the popup
-- instead of an "Order save failed" alert.

create or replace function public.create_order(
  p_product_id text, p_product_name text, p_plan_name text, p_payment_method text,
  p_account_info text, p_note text,
  p_payment_slip_path text default null, p_coupon_code text default null,
  p_plan_warranty text default null, p_plan_format text default null, p_plan_note text default null,
  p_qty numeric default 1, p_custom_amount numeric default null
)
returns table(id uuid, access_token uuid, order_code text, amount numeric)
language plpgsql
security definer
set search_path to 'public'
as $function$
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
  if auth.uid() is null then
    raise exception 'Please log in or create an account to place an order.';
  end if;

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
    update public.coupons set used_at = now(), used_by_user_id = auth.uid(), used_by_order_id = v_order_id where coupons.id = v_coupon.id;
  end if;

  return query select v_order_id, v_access_token, v_code, v_amount - v_coupon_discount;
end;
$function$;
