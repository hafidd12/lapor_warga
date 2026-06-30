-- Schema needed by the warga registration flow.
-- Assumes the app signs users up via Supabase Auth, then:
-- 1) looks up an active registration code
-- 2) uploads a KTP image to storage bucket `ktp-images`
-- 3) inserts a row into public.profiles

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null unique,
  role text not null default 'warga' check (role in ('warga', 'admin')),
  avatar_url text,
  verification_status text not null default 'pending' check (
    verification_status in ('pending', 'verified', 'rejected')
  ),
  ktp_number text,
  registration_code text,
  ktp_image_path text,
  phone text,
  rt_rw text,
  address text,
  jabatan text,
  registered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "Profiles can be read by owner" on public.profiles;
create policy "Profiles can be read by owner"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Profiles can be inserted by owner" on public.profiles;
create policy "Profiles can be inserted by owner"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Profiles can be updated by owner" on public.profiles;
create policy "Profiles can be updated by owner"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

grant select, insert, update on public.profiles to authenticated;

create table if not exists public.registration_codes (
  code text primary key,
  rt_rw text not null,
  created_by uuid references auth.users (id) on delete set null,
  created_by_name text not null,
  created_at timestamptz not null default now(),
  is_active boolean not null default true
);

alter table public.registration_codes enable row level security;

drop policy if exists "Active registration codes are readable" on public.registration_codes;
create policy "Active registration codes are readable"
on public.registration_codes
for select
to anon, authenticated
using (is_active = true);

grant select on public.registration_codes to anon, authenticated;

insert into storage.buckets (id, name, public)
values ('ktp-images', 'ktp-images', false)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public;

drop policy if exists "KTP files can be uploaded by owner" on storage.objects;
create policy "KTP files can be uploaded by owner"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'ktp-images'
  and (storage.foldername(name))[1] = 'registrations'
  and (storage.foldername(name))[2] = (select auth.uid()::text)
);

drop policy if exists "KTP files can be read by owner" on storage.objects;
create policy "KTP files can be read by owner"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'ktp-images'
  and owner_id = (select auth.uid())
);

drop policy if exists "KTP files can be updated by owner" on storage.objects;
create policy "KTP files can be updated by owner"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'ktp-images'
  and owner_id = (select auth.uid())
)
with check (
  bucket_id = 'ktp-images'
  and owner_id = (select auth.uid())
);
