-- Study Flora — Supabase schema (SRS §3.6, §4.4, §4.6)
-- Tables use an "sf_" prefix so they never clash with tables from older
-- StudyFlora prototypes in the same project. Safe to run more than once.

-- One snapshot row per user: coins, XP, inventory, garden, cosmetics (game)
-- and modules/summaries (study). updated_at (ms) drives conflict handling (FR-6.5).
create table if not exists public.sf_user_data (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  game       jsonb  not null default '{}'::jsonb,
  study      jsonb  not null default '{}'::jsonb,
  updated_at bigint not null default 0
);

-- Quiz attempts are independent records: merged, never overwritten.
create table if not exists public.sf_quiz_attempts (
  id        text primary key,
  user_id   uuid not null references auth.users (id) on delete cascade,
  payload   jsonb not null,
  taken_at  bigint not null
);
create index if not exists sf_quiz_attempts_user_idx on public.sf_quiz_attempts (user_id);

-- Row Level Security: users can only access their own data (NFR 4.4).
alter table public.sf_user_data enable row level security;
alter table public.sf_quiz_attempts enable row level security;

drop policy if exists "sf own user_data" on public.sf_user_data;
create policy "sf own user_data" on public.sf_user_data
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "sf own quiz_attempts" on public.sf_quiz_attempts;
create policy "sf own quiz_attempts" on public.sf_quiz_attempts
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- In-app "Report Feedback" (comments and opinions about the app). Users can
-- only add feedback; reading it is done by the team in the dashboard.
create table if not exists public.sf_feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users (id) on delete set null default auth.uid(),
  email       text,
  category    text not null,
  rating      int  check (rating between 0 and 5),
  message     text not null check (char_length(message) between 3 and 2000),
  app_version text,
  created_at  timestamptz not null default now()
);
alter table public.sf_feedback enable row level security;
drop policy if exists "sf add feedback" on public.sf_feedback;
create policy "sf add feedback" on public.sf_feedback
  for insert to authenticated with check (user_id is null or auth.uid() = user_id);
