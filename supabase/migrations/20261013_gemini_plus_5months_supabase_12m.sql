-- Gemini card is now "Gemini AI". Plans: the 4-month Pro plan becomes 5 months,
-- a new "Gemini AI Plus" 1-year plan, and a new Supabase Pro 12-month plan.
-- create_order prices every order from this table by plan_name, so each name
-- must match index.html character for character.
-- Step 1 adds the new rows (run it with the code change); step 2 removes the old
-- 4-month key and is safe to run once the new index.html is deployed, otherwise a
-- cached copy of the old page could not order that plan.

-- step 1
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('gemini',   'Gemini AI Pro – Own Mail – 5 Months – 12000 Ks',   12000,  false, null, null, false),
('gemini',   'Gemini AI Plus – Own Mail – 1 Year – 10000 Ks',    10000,  false, null, null, false),
('supabase', 'Supabase Pro – Own Mail – 12 Months – 300000 Ks',  300000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;

-- step 2
delete from public.catalog_plans
where product_id = 'gemini' and plan_name = 'Gemini AI Pro – Own Mail – 4 Months – 12000 Ks';
