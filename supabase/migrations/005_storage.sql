-- ============================================================
-- 005_storage.sql
-- Storage buckets + policies — بند 41/42 في التصميم:
-- ملفات الحلول ليست Public إطلاقًا.
-- ============================================================

insert into storage.buckets (id, name, public)
values
  ('subjects', 'subjects', true),   -- صور الأغلفة فقط، لا مشكلة أمنية
  ('lessons', 'lessons', false),    -- PDF دروس — يتطلب تسجيل دخول
  ('exams', 'exams', false),        -- PDF أسئلة اختبارات — يتطلب تسجيل دخول
  ('submissions', 'submissions', false), -- حلول الطلاب — الأكثر حساسية
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- subjects: صورة الغلاف عامة (قراءة للجميع)، الكتابة admin فقط
-- ------------------------------------------------------------
create policy "subjects_public_read"
on storage.objects for select
using (bucket_id = 'subjects');

create policy "subjects_admin_write"
on storage.objects for insert
with check (bucket_id = 'subjects' and public.is_admin());

create policy "subjects_admin_update_delete"
on storage.objects for update using (bucket_id = 'subjects' and public.is_admin());

create policy "subjects_admin_delete"
on storage.objects for delete using (bucket_id = 'subjects' and public.is_admin());

-- ------------------------------------------------------------
-- lessons / exams: قراءة لأي مستخدم مسجّل دخول، كتابة admin فقط
-- (لا تحتاج Signed URL لأنها ليست بيانات شخصية للطالب، فقط محتوى تعليمي)
-- ------------------------------------------------------------
create policy "lessons_read_authenticated"
on storage.objects for select
using (bucket_id = 'lessons' and auth.uid() is not null);

create policy "lessons_admin_write"
on storage.objects for insert
with check (bucket_id = 'lessons' and public.is_admin());

create policy "exams_read_authenticated"
on storage.objects for select
using (bucket_id = 'exams' and auth.uid() is not null);

create policy "exams_admin_write"
on storage.objects for insert
with check (bucket_id = 'exams' and public.is_admin());

-- ------------------------------------------------------------
-- submissions: الأكثر حساسية. bucket غير عام.
-- المسار المتفق عليه: submissions/{student_id}/{content_id}/{file}
-- نستخدم أول جزء من المسار (foldername) للتحقق أن الطالب صاحب الملف.
-- الوصول الفعلي من التطبيق يكون عبر Signed URL قصير الأجل،
-- وهذه الـ policy تحمي حتى الوصول المباشر لو تسرّب الـ path.
-- ------------------------------------------------------------
create policy "submissions_owner_or_admin_read"
on storage.objects for select
using (
  bucket_id = 'submissions'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

create policy "submissions_owner_insert"
on storage.objects for insert
with check (
  bucket_id = 'submissions'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- لا UPDATE policy للطالب على submissions — الحل لا يمكن تعديله بعد
-- الإرسال (بند 54.3)؛ فقط admin يستطيع (نادرًا، لأغراض إدارية).
create policy "submissions_admin_update"
on storage.objects for update using (bucket_id = 'submissions' and public.is_admin());

-- ------------------------------------------------------------
-- avatars: كل مستخدم يدير صورته فقط، القراءة عامة
-- ------------------------------------------------------------
create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "avatars_owner_write"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_owner_update"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
