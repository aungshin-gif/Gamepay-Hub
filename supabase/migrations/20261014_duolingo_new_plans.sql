-- Duolingo Individual: 1 Month replaced by 2 Months / 7 Months / 1 Year.
-- Names must match index.html character for character (en dash). Step 1 runs
-- with the code change; step 2 only once the new index.html is live.

-- step 1
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('duolingo', 'Individual Plan – 2 Months – 5000 Ks', 5000, false, null, null, false),
('duolingo', 'Individual Plan – 7 Months – 10000 Ks', 10000, false, null, null, false),
('duolingo', 'Individual Plan – 1 Year – 20000 Ks', 20000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;

-- step 2
delete from public.catalog_plans
where product_id = 'duolingo'
  and plan_name = 'Individual Plan – 1 Month – 5000 Ks';
