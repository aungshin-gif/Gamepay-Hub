-- Order chat: allow an image on a message (admin and customer), like the
-- support chat already does.
--
-- * messages.image_url  -- public URL in the existing "chat-images" bucket
--   (that bucket's upload policy already allows `admin/...` for admins and
--   `<user id>/...` for signed-in customers).
-- * get_messages        -- now also returns image_url.
-- * send_customer_message -- optional p_image_url; rejects an empty message,
--   an over-long body, and any image URL that is not from chat-images.
--
-- Old clients keep working: they call send_customer_message(p_token, p_body)
-- (the new parameter defaults to null) and ignore the extra get_messages column.

alter table public.messages add column if not exists image_url text;

drop function if exists public.get_messages(uuid);
create function public.get_messages(p_token uuid)
returns table(sender text, body text, created_at timestamptz, image_url text)
language sql security definer set search_path = public as $$
  select m.sender, m.body, m.created_at, m.image_url
  from public.messages m
  join public.orders o on o.id = m.order_id
  where o.access_token = p_token
  order by m.created_at asc;
$$;
grant execute on function public.get_messages(uuid) to anon, authenticated;

drop function if exists public.send_customer_message(uuid, text);
create function public.send_customer_message(p_token uuid, p_body text, p_image_url text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare v_order_id uuid; v_chat_closed boolean;
begin
  select id, chat_closed into v_order_id, v_chat_closed from public.orders where access_token = p_token;
  if v_order_id is null then
    raise exception 'invalid order token';
  end if;
  -- Client-side already hides the input once ended; this is the real gate,
  -- since a customer's browser is never trusted to enforce it on its own.
  if v_chat_closed then
    raise exception 'this conversation has ended';
  end if;
  if coalesce(btrim(p_body), '') = '' and p_image_url is null then
    raise exception 'empty message';
  end if;
  if char_length(coalesce(p_body, '')) > 4000 then
    raise exception 'message too long';
  end if;
  if p_image_url is not null and p_image_url not like '%/storage/v1/object/public/chat-images/%' then
    raise exception 'invalid image';
  end if;
  insert into public.messages(order_id, sender, body, image_url)
    values (v_order_id, 'customer', coalesce(p_body, ''), p_image_url);
end;
$$;
grant execute on function public.send_customer_message(uuid, text, text) to anon, authenticated;
