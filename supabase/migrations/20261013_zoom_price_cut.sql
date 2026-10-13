-- Zoom Pro price cut: 14 Days 5000->3000, 1 Month 8000->5000, 2 Months 15000->8000.
-- Plan names embed the price and create_order looks plans up by name, so the new
-- rows are added first (step 1, run with the code change) and the old ones are
-- removed later (step 2, once the new index.html is live).

-- step 1
insert into public.catalog_plans (product_id, plan_name, price, custom, base_amount, min_amount, out_of_stock) values
('zoom', '🔐 Private – 14 Days – 3000 Ks', 3000, false, null, null, false),
('zoom', '🔐 Private – 1 Month – 5000 Ks', 5000, false, null, null, false),
('zoom', '🔐 Private – 2 Months – 8000 Ks', 8000, false, null, null, false)
on conflict (product_id, plan_name) do nothing;

-- step 2
delete from public.catalog_plans
where product_id = 'zoom'
  and plan_name in (
    '🔐 Private – 14 Days – 5000 Ks',
    '🔐 Private – 1 Month – 8000 Ks',
    '🔐 Private – 2 Months – 15000 Ks'
  );
