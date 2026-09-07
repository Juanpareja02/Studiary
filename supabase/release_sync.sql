-- Additive release migration. RLS and ownership remain enforced by the caller.
create or replace function public.save_studiary_snapshot(p_data jsonb, p_revision timestamptz default null)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare current_row public.studiary_data%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 10485760 then
    raise exception 'Invalid snapshot';
  end if;
  -- The insert also serializes two first-time saves for the same account.
  insert into public.studiary_data(user_id) values(auth.uid()) on conflict do nothing;
  select * into current_row from public.studiary_data where user_id = auth.uid() for update;
  if (p_revision is null and current_row.data <> '{}'::jsonb)
      or (p_revision is not null and current_row.updated_at is distinct from p_revision) then
    return jsonb_build_object('saved', false, 'data', current_row.data, 'revision', current_row.updated_at);
  end if;
  update public.studiary_data set data=p_data, updated_at=clock_timestamp()
    where user_id=auth.uid() returning * into current_row;
  return jsonb_build_object('saved', true, 'data', current_row.data, 'revision', current_row.updated_at);
end;
$$;
revoke all on function public.save_studiary_snapshot(jsonb,timestamptz) from public, anon;
grant execute on function public.save_studiary_snapshot(jsonb,timestamptz) to authenticated;
