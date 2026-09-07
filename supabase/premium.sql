-- Purchase tokens are server-only. The app can read only its own entitlement.
create table if not exists public.play_purchases (
  token_hash text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null,
  purchase_token text not null,
  active boolean not null default false,
  expires_at timestamptz,
  verified_at timestamptz not null default now()
);
create index if not exists play_purchases_user_id_idx on public.play_purchases(user_id);
alter table public.play_purchases enable row level security;
revoke all on public.play_purchases from anon, authenticated;
grant all on public.play_purchases to service_role;

create table if not exists public.premium_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  active boolean not null default false,
  product_id text,
  expires_at timestamptz,
  verified_at timestamptz not null default now()
);
alter table public.premium_entitlements enable row level security;
revoke all on public.premium_entitlements from anon, authenticated;
grant select on public.premium_entitlements to authenticated;
grant all on public.premium_entitlements to service_role;
create policy "Read own verified entitlement" on public.premium_entitlements
  for select to authenticated using ((select auth.uid())=user_id);
