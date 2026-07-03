-- Support RT registration codes with an explicit type and parsed RT/RW fields.
-- Existing warga codes keep working because the new columns default to `warga`
-- and existing rows are backfilled from the legacy `rt_rw` column.

begin;

alter table public.registration_codes
  add column if not exists registration_type text not null default 'warga';

alter table public.registration_codes
  add column if not exists rt text;

alter table public.registration_codes
  add column if not exists rw text;

alter table public.registration_codes
  add column if not exists used_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'registration_codes_registration_type_check'
  ) then
    alter table public.registration_codes
      add constraint registration_codes_registration_type_check
      check (registration_type in ('warga', 'admin'));
  end if;
end
$$;

update public.registration_codes
set
  rt = coalesce(nullif(trim(rt), ''), split_part(rt_rw, '/', 1)),
  rw = coalesce(nullif(trim(rw), ''), split_part(rt_rw, '/', 2)),
  registration_type = coalesce(nullif(trim(registration_type), ''), 'warga')
where rt is null
   or rw is null
   or registration_type is null;

create index if not exists registration_codes_registration_type_idx
  on public.registration_codes(registration_type);

commit;
