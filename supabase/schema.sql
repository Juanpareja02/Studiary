-- Esquema de Studiary para Supabase.
-- Ejecutar en el SQL Editor del proyecto de Studiary antes de publicar la app.

create table if not exists public.studiary_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.studiary_data enable row level security;

grant select, insert, update, delete on table public.studiary_data to authenticated;
revoke all on table public.studiary_data from anon;

drop policy if exists "Users can read their own Studiary data" on public.studiary_data;
create policy "Users can read their own Studiary data"
  on public.studiary_data
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own Studiary data" on public.studiary_data;
create policy "Users can create their own Studiary data"
  on public.studiary_data
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own Studiary data" on public.studiary_data;
create policy "Users can update their own Studiary data"
  on public.studiary_data
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own Studiary data" on public.studiary_data;
create policy "Users can delete their own Studiary data"
  on public.studiary_data
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'note-files',
  'note-files',
  false,
  8388608,
  array['application/pdf', 'image/*']::text[]
)
on conflict (id) do update set
  public = false,
  file_size_limit = 8388608,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their own note files" on storage.objects;
create policy "Users can read their own note files"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'note-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

drop policy if exists "Users can upload their own note files" on storage.objects;
create policy "Users can upload their own note files"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'note-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

drop policy if exists "Users can update their own note files" on storage.objects;
create policy "Users can update their own note files"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'note-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'note-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

drop policy if exists "Users can delete their own note files" on storage.objects;
create policy "Users can delete their own note files"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'note-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );
