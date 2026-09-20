-- ============================================================
-- 002_subjects_contents.sql
-- المواد والمحتوى (دروس + اختبارات) — بند 26/27/36/37 في التصميم
-- ============================================================

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  image_url text,
  is_active boolean not null default true,
  order_index int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contents (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects (id) on delete cascade,
  title text not null,
  description text,
  type text not null check (type in ('lesson', 'exam')),
  file_path text not null,
  file_name text not null,
  file_size bigint,
  mime_type text,
  order_index int not null default 0,
  -- Lesson: تبقى NULL دائمًا. Exam: يجب تعبئتهما (يُفرض بـ check أدناه)
  available_from timestamptz,
  available_until timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint chk_exam_dates check (
    (type = 'lesson' and available_from is null and available_until is null)
    or
    (type = 'exam' and available_from is not null and available_until is not null
     and available_until > available_from)
  )
);

create index if not exists idx_contents_subject on public.contents (subject_id, order_index);
create index if not exists idx_contents_type on public.contents (type);

drop trigger if exists set_subjects_updated_at on public.subjects;
create trigger set_subjects_updated_at
  before update on public.subjects
  for each row execute function public.set_updated_at();

drop trigger if exists set_contents_updated_at on public.contents;
create trigger set_contents_updated_at
  before update on public.contents
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.subjects enable row level security;
alter table public.contents enable row level security;

-- SELECT: الطالب يرى فقط is_active = true، الـ admin يرى كل شيء
create policy "subjects_select_active_or_admin"
on public.subjects for select
using (is_active = true or public.is_admin());

create policy "contents_select_active_or_admin"
on public.contents for select
using (
  (is_active = true and exists (
    select 1 from public.subjects s where s.id = subject_id and s.is_active = true
  ))
  or public.is_admin()
);

-- INSERT/UPDATE/DELETE: admin فقط
create policy "subjects_admin_write"
on public.subjects for all
using (public.is_admin())
with check (public.is_admin());

create policy "contents_admin_write"
on public.contents for all
using (public.is_admin())
with check (public.is_admin());
