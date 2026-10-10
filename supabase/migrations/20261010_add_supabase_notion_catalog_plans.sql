-- Supabase Pro and Notion Business. create_order prices every order from this
-- table, so plan_name must match index.html character for character.
-- Already applied to the live project; kept here so the repo matches it.
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('supabase', 'Supabase Pro – Own Mail – 1 Month – 120000 Ks', 120000, false, null, null, false),
('notion', 'Notion Business – Own Mail – 3 Months – 31500 Ks', 31500, false, null, null, false)
on conflict (product_id, plan_name) do nothing;
