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

-- ---------------------------------------------------------------------------
-- Settings → Delete Account. A signed-in user can delete ONLY their own
-- account: their game/study data, quiz history and the login itself.
-- Feedback they sent is kept for the team but no longer linked to them.
create or replace function public.sf_delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;
  delete from public.sf_quiz_attempts where user_id = uid;
  delete from public.sf_user_data where user_id = uid;
  update public.sf_feedback set user_id = null, email = null where user_id = uid;
  delete from auth.users where id = uid;
end;
$$;
revoke all on function public.sf_delete_my_account() from public, anon;
grant execute on function public.sf_delete_my_account() to authenticated;

-- ---------------------------------------------------------------------------
-- Report Feedback → email to studyflora2026@gmail.com.
-- Every new row in sf_feedback is emailed through the Brevo API. The Brevo
-- API key is NOT stored here: add it once in Supabase → Project Settings →
-- Vault as a secret named  brevo_api_key  (until then feedback is only saved
-- in the table). Each user can send at most 10 feedback messages per hour.
create extension if not exists pg_net with schema extensions;

create or replace function public.sf_feedback_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.user_id is not null and (
    select count(*) from public.sf_feedback
    where user_id = new.user_id and created_at > now() - interval '1 hour'
  ) >= 10 then
    raise exception 'Too much feedback at once. Please try again later.';
  end if;
  return new;
end;
$$;
drop trigger if exists sf_feedback_limit on public.sf_feedback;
create trigger sf_feedback_limit before insert on public.sf_feedback
  for each row execute function public.sf_feedback_limit();

create or replace function public.sf_feedback_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  api_key text;
  body jsonb;
begin
  select decrypted_secret into api_key from vault.decrypted_secrets where name = 'brevo_api_key' limit 1;
  if api_key is null or api_key = '' then
    return new; -- email not set up yet; the feedback is still saved
  end if;
  body := jsonb_build_object(
    'sender', jsonb_build_object('name', 'Study Flora', 'email', 'studyflora2026@gmail.com'),
    'to', jsonb_build_array(jsonb_build_object('email', 'studyflora2026@gmail.com', 'name', 'Study Flora Team')),
    'subject', 'Study Flora feedback: ' || new.category
               || case when coalesce(new.rating, 0) > 0 then ' (' || new.rating || '/5)' else '' end,
    'textContent',
      'New feedback from the Study Flora app' || E'\n\n'
      || 'Type: ' || new.category || E'\n'
      || 'Rating: ' || case when coalesce(new.rating, 0) > 0 then new.rating || ' / 5' else 'not given' end || E'\n'
      || 'From: ' || coalesce(new.email, 'unknown user') || E'\n'
      || 'App version: ' || coalesce(new.app_version, '-') || E'\n'
      || 'Sent: ' || to_char(new.created_at at time zone 'Asia/Manila', 'Mon DD, YYYY HH12:MI AM') || ' (PH time)' || E'\n\n'
      || 'Message:' || E'\n' || new.message
  );
  if new.email is not null then
    body := body || jsonb_build_object('replyTo', jsonb_build_object('email', new.email));
  end if;
  perform net.http_post(
    url := 'https://api.brevo.com/v3/smtp/email',
    body := body,
    headers := jsonb_build_object('api-key', api_key, 'Content-Type', 'application/json', 'Accept', 'application/json')
  );
  return new;
end;
$$;
drop trigger if exists sf_feedback_email on public.sf_feedback;
create trigger sf_feedback_email after insert on public.sf_feedback
  for each row execute function public.sf_feedback_email();

notify pgrst, 'reload schema';
