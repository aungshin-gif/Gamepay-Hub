-- Lovable product (4 plans). create_order prices every order from this table,
-- so a new product in index.html needs these rows too -- plan_name must match
-- the plan's name in index.html character for character (note the en dashes).
-- Already applied to the live project; kept here so the repo matches it.
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('lovable', 'Lovable Pro Official – Own Mail – 1 Month – 120000 Ks', 120000, false, null, null, false),
('lovable', 'Lovable Credits – 1 Month – 98000 Ks', 98000, false, null, null, false),
('lovable', 'Lovable Lite – 12 Months – 55000 Ks', 55000, false, null, null, false),
('lovable', 'Lovable Pro – 1 Month – 18000 Ks', 18000, false, null, null, false);
