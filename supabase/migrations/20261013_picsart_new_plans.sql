-- PicsArt Pro: all old plans are replaced by three new ones (7 days share,
-- 7 days private, 30 days private). create_order prices every order from this
-- table by plan_name, so each name must match index.html character for character.
-- Step 1 adds the new rows (run it with the code change); step 2 removes the old
-- rows and is safe to run once the new index.html is deployed, otherwise a cached
-- copy of the old page could not order those plans.

-- step 1
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('picsart', 'PicsArt Pro – Share – 7 Days – 1000 Ks',    1000, false, null, null, false),
('picsart', 'PicsArt Pro – Private – 7 Days – 2000 Ks',  2000, false, null, null, false),
('picsart', 'PicsArt Pro – Private – 30 Days – 8000 Ks', 8000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;

-- step 2
delete from public.catalog_plans
where product_id = 'picsart'
  and plan_name in (
    '1 Month (👥Share) – 4000 Ks',
    '1 Month (🔐Private) – 5700 Ks',
    '3 Months – 14000 Ks',
    '1 Year – 50000 Ks',
    'Own Mail - 1 Month – 24000 Ks'
  );
