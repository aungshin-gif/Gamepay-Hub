-- HBO Max: new 4K Premium plans (1 / 2 / 4 Profiles, Head). create_order prices
-- by plan_name, so names must match index.html character for character
-- (the name contains a real line break before "1 Month").
-- step 1: run with the code change. step 2: run once the new index.html is live.

-- step 1
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('hbomax', E'👤1 Profile - 5000 Ks\n1 Month', 5000, false, null, null, false),
('hbomax', E'👥2 Profiles - 7000 Ks\n1 Month', 7000, false, null, null, false),
('hbomax', E'👥4 Profiles - 9000 Ks\n1 Month', 9000, false, null, null, false),
('hbomax', E'🔥HBO Head - 12000 Ks\n1 Month', 12000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;

-- step 2
delete from public.catalog_plans
where product_id = 'hbomax'
  and plan_name in (
    E'👤1 Profile - 8500 Ks\n1 Month',
    E'👥2 Profiles - 13000 Ks\n1 Month',
    E'Each Profile - 6000 Ks\nAbove 3 Pf',
    E'🔥HBO Head - 25000 Ks\n1 Month'
  );
