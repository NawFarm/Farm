-- Livestock Ledger: one private JSON document per authenticated owner.
-- Run this entire file in Supabase Dashboard > SQL Editor.

create table if not exists public.farm_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.farm_data enable row level security;

-- Remove broad access. The publishable browser key can do nothing unless
-- the user is authenticated and one of the policies below permits it.
revoke all on table public.farm_data from anon;
grant select, insert, update, delete on table public.farm_data to authenticated;

-- Re-running this setup is safe.
drop policy if exists "Owners can read their own farm" on public.farm_data;
drop policy if exists "Owners can create their own farm" on public.farm_data;
drop policy if exists "Owners can update their own farm" on public.farm_data;
drop policy if exists "Owners can delete their own farm" on public.farm_data;

create policy "Owners can read their own farm"
on public.farm_data
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Owners can create their own farm"
on public.farm_data
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Owners can update their own farm"
on public.farm_data
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Owners can delete their own farm"
on public.farm_data
for delete
to authenticated
using ((select auth.uid()) = user_id);

comment on table public.farm_data is
'Private Livestock Ledger data. Row Level Security restricts each row to its authenticated owner.';
