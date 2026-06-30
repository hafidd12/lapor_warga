-- Allow RT/Admin to read private KTP images for verification.
drop policy if exists "Admins can read KTP images" on storage.objects;

create policy "Admins can read KTP images"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'ktp-images'
  and app_private.is_admin()
);
