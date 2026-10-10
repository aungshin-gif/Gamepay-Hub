-- "Lovable Credits" is now "Lovable 300 Credits" (plan_name is the key
-- create_order looks the price up by, and it must match index.html exactly).
-- Step 1 was applied to the live project together with the code change.
-- Step 2 removes the old key; run it once the new index.html is deployed,
-- otherwise a cached copy of the old page could not order that plan.

-- step 1
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('lovable', 'Lovable 300 Credits – 1 Month – 98000 Ks', 98000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;

-- step 2
delete from public.catalog_plans
where product_id = 'lovable' and plan_name = 'Lovable Credits – 1 Month – 98000 Ks';
