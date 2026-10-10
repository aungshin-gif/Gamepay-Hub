-- Wink China Region is now two plans, Wink VIP and Wink SVIP (7 days, private
-- account). create_order prices from this table, so plan_name must match
-- index.html exactly. Already applied to the live project.
-- The old out-of-stock row 'China Region – 1 Month – 4500 Ks' is no longer in
-- index.html; it was left in place (harmless) rather than deleted.
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('wink', 'Wink VIP – China Region – 7 Days – 2000 Ks', 2000, false, null, null, false),
('wink', 'Wink SVIP – China Region – 7 Days – 3000 Ks', 3000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;
