-- Lapor Warga - Supabase PostgreSQL Migration
-- Jalankan file ini langsung di Supabase SQL Editor.
-- Aman dijalankan ulang untuk struktur inti karena memakai IF NOT EXISTS
-- dan DROP POLICY IF EXISTS sebelum membuat policy.

begin;

-- ============================================================
-- 1. Extensions
-- ============================================================

create extension if not exists "pgcrypto";

-- ============================================================
-- 2. Enum Types
-- ============================================================

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('warga', 'admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'verification_status') then
    create type public.verification_status as enum ('pending', 'verified', 'rejected');
  end if;

  if not exists (select 1 from pg_type where typname = 'report_priority') then
    create type public.report_priority as enum ('low', 'medium', 'high');
  end if;

  if not exists (select 1 from pg_type where typname = 'report_status') then
    create type public.report_status as enum ('submitted', 'processed', 'resolved');
  end if;

  if not exists (select 1 from pg_type where typname = 'admin_activity_type') then
    create type public.admin_activity_type as enum (
      'verification',
      'announcement',
      'report_completed',
      'poll',
      'warga_removed',
      'report_status_updated'
    );
  end if;
end
$$;

-- ============================================================
-- 3. Utility Functions
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- 4. Main Tables
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  role public.app_role not null default 'warga',
  avatar_url text,
  verification_status public.verification_status not null default 'pending',
  ktp_number text,
  registration_code text,
  ktp_image_path text,
  phone text,
  rt_rw text,
  address text,
  jabatan text,
  registered_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_warga_has_verification check (
    role <> 'warga' or verification_status in ('pending', 'verified', 'rejected')
  )
);

create table if not exists public.registration_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  rt_rw text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_by_name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  citizen_id uuid references public.profiles(id) on delete set null,
  citizen_name text not null,
  title text not null,
  description text not null,
  category text not null,
  priority public.report_priority not null default 'medium',
  status public.report_status not null default 'submitted',
  votes_count integer not null default 0 check (votes_count >= 0),
  report_photo_url text,
  location_label text,
  location_lat double precision,
  location_lng double precision,
  completion_photo_url text,
  completed_at timestamptz,
  completed_by uuid references public.profiles(id) on delete set null,
  completed_by_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_resolved_requires_completion_photo check (
    status <> 'resolved' or completion_photo_url is not null
  )
);

create table if not exists public.report_upvotes (
  report_id uuid not null references public.reports(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (report_id, user_id)
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  author_id uuid references public.profiles(id) on delete set null,
  author_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.polls (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_by_name text,
  is_active boolean not null default true,
  closes_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.poll_options (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  option_text text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (poll_id, option_text)
);

create table if not exists public.poll_votes (
  poll_id uuid not null references public.polls(id) on delete cascade,
  option_id uuid not null references public.poll_options(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (poll_id, user_id)
);

create table if not exists public.admin_activities (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  description text not null,
  type public.admin_activity_type not null,
  photo_url text,
  related_table text,
  related_id uuid,
  created_at timestamptz not null default now()
);

create or replace function public.current_profile_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_profile_rt_rw()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select rt_rw from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_profile_role() = 'admin', false);
$$;

-- ============================================================
-- 5. Triggers
-- ============================================================

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_registration_codes_updated_at on public.registration_codes;
create trigger set_registration_codes_updated_at
before update on public.registration_codes
for each row execute function public.set_updated_at();

drop trigger if exists set_reports_updated_at on public.reports;
create trigger set_reports_updated_at
before update on public.reports
for each row execute function public.set_updated_at();

drop trigger if exists set_announcements_updated_at on public.announcements;
create trigger set_announcements_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

drop trigger if exists set_polls_updated_at on public.polls;
create trigger set_polls_updated_at
before update on public.polls
for each row execute function public.set_updated_at();

create or replace function public.sync_report_votes_count()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    update public.reports
      set votes_count = votes_count + 1
      where id = new.report_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.reports
      set votes_count = greatest(votes_count - 1, 0)
      where id = old.report_id;
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists report_upvotes_after_insert on public.report_upvotes;
create trigger report_upvotes_after_insert
after insert on public.report_upvotes
for each row execute function public.sync_report_votes_count();

drop trigger if exists report_upvotes_after_delete on public.report_upvotes;
create trigger report_upvotes_after_delete
after delete on public.report_upvotes
for each row execute function public.sync_report_votes_count();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    name,
    email,
    role,
    avatar_url,
    verification_status,
    phone,
    rt_rw,
    address,
    jabatan,
    registration_code,
    ktp_image_path
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1), 'Pengguna'),
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::public.app_role, 'warga'),
    new.raw_user_meta_data->>'avatar_url',
    case
      when coalesce(new.raw_user_meta_data->>'role', 'warga') = 'admin' then 'verified'::public.verification_status
      else 'pending'::public.verification_status
    end,
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'rt_rw',
    new.raw_user_meta_data->>'address',
    new.raw_user_meta_data->>'jabatan',
    new.raw_user_meta_data->>'registration_code',
    new.raw_user_meta_data->>'ktp_image_path'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- ============================================================
-- 6. Views
-- ============================================================

create or replace view public.poll_results
with (security_invoker = true) as
select
  po.poll_id,
  po.id as option_id,
  po.option_text,
  po.sort_order,
  count(pv.user_id)::integer as votes_count
from public.poll_options po
left join public.poll_votes pv on pv.option_id = po.id
group by po.poll_id, po.id, po.option_text, po.sort_order;

-- ============================================================
-- 7. Indexes
-- ============================================================

create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists profiles_verification_status_idx on public.profiles(verification_status);
create index if not exists profiles_rt_rw_idx on public.profiles(rt_rw);
create index if not exists registration_codes_code_idx on public.registration_codes(code);
create index if not exists registration_codes_rt_rw_idx on public.registration_codes(rt_rw);
create index if not exists reports_status_idx on public.reports(status);
create index if not exists reports_priority_idx on public.reports(priority);
create index if not exists reports_category_idx on public.reports(category);
create index if not exists reports_citizen_id_idx on public.reports(citizen_id);
create index if not exists reports_created_at_idx on public.reports(created_at desc);
create index if not exists announcements_created_at_idx on public.announcements(created_at desc);
create index if not exists polls_created_at_idx on public.polls(created_at desc);
create index if not exists poll_options_poll_id_idx on public.poll_options(poll_id);
create index if not exists poll_votes_poll_id_idx on public.poll_votes(poll_id);
create index if not exists admin_activities_created_at_idx on public.admin_activities(created_at desc);

-- ============================================================
-- 8. Storage Buckets
-- ============================================================

insert into storage.buckets (id, name, public)
values
  ('ktp-images', 'ktp-images', false),
  ('report-photos', 'report-photos', false),
  ('completion-photos', 'completion-photos', false)
on conflict (id) do nothing;

-- ============================================================
-- 9. Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.registration_codes enable row level security;
alter table public.reports enable row level security;
alter table public.report_upvotes enable row level security;
alter table public.announcements enable row level security;
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;
alter table public.admin_activities enable row level security;

-- Profiles
drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
on public.profiles for select
to authenticated
using (true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles for update
to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_admin_delete" on public.profiles;
create policy "profiles_admin_delete"
on public.profiles for delete
to authenticated
using (public.is_admin());

-- Registration Codes
drop policy if exists "registration_codes_select_authenticated" on public.registration_codes;
create policy "registration_codes_select_authenticated"
on public.registration_codes for select
to anon, authenticated
using (is_active = true or public.is_admin());

drop policy if exists "registration_codes_admin_insert" on public.registration_codes;
create policy "registration_codes_admin_insert"
on public.registration_codes for insert
to authenticated
with check (public.is_admin());

drop policy if exists "registration_codes_admin_update" on public.registration_codes;
create policy "registration_codes_admin_update"
on public.registration_codes for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "registration_codes_admin_delete" on public.registration_codes;
create policy "registration_codes_admin_delete"
on public.registration_codes for delete
to authenticated
using (public.is_admin());

-- Reports
drop policy if exists "reports_select_verified_warga_or_admin" on public.reports;
create policy "reports_select_verified_warga_or_admin"
on public.reports for select
to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'warga'
      and p.verification_status = 'verified'
  )
);

drop policy if exists "reports_warga_insert_own" on public.reports;
create policy "reports_warga_insert_own"
on public.reports for insert
to authenticated
with check (
  citizen_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'warga'
      and p.verification_status = 'verified'
  )
);

drop policy if exists "reports_warga_update_own_submitted_or_admin" on public.reports;
create policy "reports_warga_update_own_submitted_or_admin"
on public.reports for update
to authenticated
using (
  public.is_admin()
  or (citizen_id = auth.uid() and status = 'submitted')
)
with check (
  public.is_admin()
  or (citizen_id = auth.uid() and status = 'submitted')
);

drop policy if exists "reports_admin_delete" on public.reports;
create policy "reports_admin_delete"
on public.reports for delete
to authenticated
using (public.is_admin());

-- Report Upvotes
drop policy if exists "report_upvotes_select_authenticated" on public.report_upvotes;
create policy "report_upvotes_select_authenticated"
on public.report_upvotes for select
to authenticated
using (true);

drop policy if exists "report_upvotes_insert_own" on public.report_upvotes;
create policy "report_upvotes_insert_own"
on public.report_upvotes for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "report_upvotes_delete_own" on public.report_upvotes;
create policy "report_upvotes_delete_own"
on public.report_upvotes for delete
to authenticated
using (user_id = auth.uid());

-- Announcements
drop policy if exists "announcements_select_authenticated" on public.announcements;
create policy "announcements_select_authenticated"
on public.announcements for select
to authenticated
using (true);

drop policy if exists "announcements_admin_insert" on public.announcements;
create policy "announcements_admin_insert"
on public.announcements for insert
to authenticated
with check (public.is_admin());

drop policy if exists "announcements_admin_update" on public.announcements;
create policy "announcements_admin_update"
on public.announcements for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "announcements_admin_delete" on public.announcements;
create policy "announcements_admin_delete"
on public.announcements for delete
to authenticated
using (public.is_admin());

-- Polls
drop policy if exists "polls_select_authenticated" on public.polls;
create policy "polls_select_authenticated"
on public.polls for select
to authenticated
using (true);

drop policy if exists "polls_admin_insert" on public.polls;
create policy "polls_admin_insert"
on public.polls for insert
to authenticated
with check (public.is_admin());

drop policy if exists "polls_admin_update" on public.polls;
create policy "polls_admin_update"
on public.polls for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "polls_admin_delete" on public.polls;
create policy "polls_admin_delete"
on public.polls for delete
to authenticated
using (public.is_admin());

-- Poll Options
drop policy if exists "poll_options_select_authenticated" on public.poll_options;
create policy "poll_options_select_authenticated"
on public.poll_options for select
to authenticated
using (true);

drop policy if exists "poll_options_admin_insert" on public.poll_options;
create policy "poll_options_admin_insert"
on public.poll_options for insert
to authenticated
with check (public.is_admin());

drop policy if exists "poll_options_admin_update" on public.poll_options;
create policy "poll_options_admin_update"
on public.poll_options for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "poll_options_admin_delete" on public.poll_options;
create policy "poll_options_admin_delete"
on public.poll_options for delete
to authenticated
using (public.is_admin());

-- Poll Votes
drop policy if exists "poll_votes_select_authenticated" on public.poll_votes;
create policy "poll_votes_select_authenticated"
on public.poll_votes for select
to authenticated
using (true);

drop policy if exists "poll_votes_insert_own" on public.poll_votes;
create policy "poll_votes_insert_own"
on public.poll_votes for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "poll_votes_update_own" on public.poll_votes;
create policy "poll_votes_update_own"
on public.poll_votes for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "poll_votes_delete_own" on public.poll_votes;
create policy "poll_votes_delete_own"
on public.poll_votes for delete
to authenticated
using (user_id = auth.uid());

-- Admin Activities
drop policy if exists "admin_activities_select_authenticated" on public.admin_activities;
create policy "admin_activities_select_authenticated"
on public.admin_activities for select
to authenticated
using (true);

drop policy if exists "admin_activities_admin_insert" on public.admin_activities;
create policy "admin_activities_admin_insert"
on public.admin_activities for insert
to authenticated
with check (public.is_admin());

-- Storage Objects
drop policy if exists "storage_authenticated_read_lapor_warga_files" on storage.objects;
create policy "storage_authenticated_read_lapor_warga_files"
on storage.objects for select
to authenticated
using (bucket_id in ('ktp-images', 'report-photos', 'completion-photos'));

drop policy if exists "storage_users_upload_own_lapor_warga_files" on storage.objects;
create policy "storage_users_upload_own_lapor_warga_files"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('ktp-images', 'report-photos', 'completion-photos')
  and owner = auth.uid()
);

drop policy if exists "storage_users_update_own_lapor_warga_files" on storage.objects;
create policy "storage_users_update_own_lapor_warga_files"
on storage.objects for update
to authenticated
using (
  bucket_id in ('ktp-images', 'report-photos', 'completion-photos')
  and (owner = auth.uid() or public.is_admin())
)
with check (
  bucket_id in ('ktp-images', 'report-photos', 'completion-photos')
  and (owner = auth.uid() or public.is_admin())
);

drop policy if exists "storage_users_delete_own_lapor_warga_files" on storage.objects;
create policy "storage_users_delete_own_lapor_warga_files"
on storage.objects for delete
to authenticated
using (
  bucket_id in ('ktp-images', 'report-photos', 'completion-photos')
  and (owner = auth.uid() or public.is_admin())
);

-- ============================================================
-- 10. Helpful Grants
-- ============================================================

grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to authenticated;
grant all on all routines in schema public to authenticated;
grant select on public.registration_codes to anon;
grant select on public.poll_results to authenticated;

commit;
