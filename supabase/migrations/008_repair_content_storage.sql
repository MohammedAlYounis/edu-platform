-- Ensure content buckets and admin upload policies exist on the remote project.
insert into storage.buckets (id, name, public)
values
  ('lessons', 'lessons', false),
  ('exams', 'exams', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists "lessons_read_authenticated" on storage.objects;
create policy "lessons_read_authenticated"
on storage.objects for select
using (bucket_id = 'lessons' and auth.uid() is not null);

drop policy if exists "lessons_admin_write" on storage.objects;
create policy "lessons_admin_write"
on storage.objects for insert
with check (bucket_id = 'lessons' and public.is_admin());

drop policy if exists "exams_read_authenticated" on storage.objects;
create policy "exams_read_authenticated"
on storage.objects for select
using (bucket_id = 'exams' and auth.uid() is not null);

drop policy if exists "exams_admin_write" on storage.objects;
create policy "exams_admin_write"
on storage.objects for insert
with check (bucket_id = 'exams' and public.is_admin());
