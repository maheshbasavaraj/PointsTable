-- Run in the Supabase SQL Editor. Public visitors can read; only listed admins can write.
create table if not exists public.tournament_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.tournament_admins enable row level security;
revoke all on public.tournament_admins from anon, authenticated;
grant select on public.tournament_admins to authenticated;
drop policy if exists "admins can read their own row" on public.tournament_admins;
create policy "admins can read their own row" on public.tournament_admins
  for select to authenticated using (auth.uid() = user_id);

create table if not exists public.tournament_state (
  singleton boolean primary key default true check (singleton),
  state jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.tournament_state enable row level security;
revoke all on public.tournament_state from anon, authenticated;
grant select on public.tournament_state to anon, authenticated;
grant update (state, updated_at) on public.tournament_state to authenticated;
drop policy if exists "anyone can view tournament" on public.tournament_state;
create policy "anyone can view tournament" on public.tournament_state
  for select to anon, authenticated using (true);
drop policy if exists "admins can update tournament" on public.tournament_state;
create policy "admins can update tournament" on public.tournament_state
  for update to authenticated
  using (exists (select 1 from public.tournament_admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.tournament_admins a where a.user_id = auth.uid()));

insert into public.tournament_state(singleton, state) values (true, '{
  "teams": ["Team A", "Team B", "Team C", "Team D", "Team E", "Team F"],
  "pools": {
    "Basketball":{"A":[0,1,2],"B":[3,4,5]},
    "Volleyball":{"A":[0,1,2],"B":[3,4,5]},
    "Badminton":{"A":[0,1,2],"B":[3,4,5]},
    "Tug of War":{"A":[0,1,2],"B":[3,4,5]},
    "Chess":{"A":[0,1,2],"B":[3,4,5]},
    "Box Cricket":{"A":[0,1,2],"B":[3,4,5]}
  },
  "results": {}
}'::jsonb) on conflict (singleton) do nothing;

do $$ begin
  alter publication supabase_realtime add table public.tournament_state;
exception when duplicate_object then null;
end $$;
