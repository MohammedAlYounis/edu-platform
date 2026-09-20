-- ============================================================
-- 003_submissions.sql
-- الحلول المرسلة — قاعدة "submission واحد فعّال" مفروضة في DB
-- وليس فقط في Flutter (بند 13 و54.2 في التصميم)
-- ============================================================

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.contents (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  file_path text not null,
  file_name text not null,
  file_size bigint,
  mime_type text,
  status text not null default 'pending'
    check (status in ('pending', 'reviewing', 'reviewed', 'needs_resubmission')),
  grade numeric(5, 2) check (grade is null or (grade >= 0 and grade <= 100)),
  review_note text,
  reviewer_id uuid references public.profiles (id),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  can_resubmit boolean not null default false,
  resubmission_reason text,
  -- يُعلَّم true تلقائيًا عندما يُسمح للطالب بإرسال نسخة جديدة، بحيث
  -- يبقى هذا السجل كسجل تاريخي (لا يُحذف) دون أن يُحسب "فعّالًا".
  is_superseded boolean not null default false,
  updated_at timestamptz not null default now()
);

create index if not exists idx_submissions_student on public.submissions (student_id);
create index if not exists idx_submissions_content on public.submissions (content_id);
create index if not exists idx_submissions_status on public.submissions (status);

-- يمنع فعليًا وجود أكثر من submission فعّال واحد لكل (طالب + محتوى)،
-- حتى تحت تزامن عالٍ (race condition) — الحماية الأخيرة بعد الـ trigger.
create unique index if not exists uq_active_submission_per_content
on public.submissions (student_id, content_id)
where is_superseded = false;

drop trigger if exists set_submissions_updated_at on public.submissions;
create trigger set_submissions_updated_at
  before update on public.submissions
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- Trigger: قبل أي INSERT جديد، تحقق من عدم وجود submission فعّال
-- سابق. إن وُجد وكان can_resubmit = true على القديم، عَلِّمه
-- is_superseded = true تلقائيًا بدل رفض الإدراج.
-- ------------------------------------------------------------
create or replace function public.handle_new_submission()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  existing record;
  content_row record;
begin
  select * into content_row from public.contents where id = new.content_id;

  if content_row.type <> 'exam' then
    raise exception 'لا يمكن رفع حل لدرس، فقط للاختبارات';
  end if;

  if now() < content_row.available_from or now() > content_row.available_until then
    raise exception 'الاختبار غير متاح حاليًا لاستقبال الحلول';
  end if;

  select * into existing
  from public.submissions
  where student_id = new.student_id
    and content_id = new.content_id
    and is_superseded = false
  limit 1;

  if found then
    if existing.can_resubmit then
      update public.submissions
      set is_superseded = true
      where id = existing.id;
    else
      raise exception 'لديك حل مُرسَل مسبقًا لهذا الاختبار ولا يمكنك إرسال حل آخر';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists before_submission_insert on public.submissions;
create trigger before_submission_insert
  before insert on public.submissions
  for each row execute function public.handle_new_submission();

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.submissions enable row level security;

-- SELECT: الطالب يرى حلوله فقط، الـ admin يرى الكل
create policy "submissions_select_own_or_admin"
on public.submissions for select
using (student_id = auth.uid() or public.is_admin());

-- INSERT: الطالب فقط، ولنفسه فقط (باقي القواعد تُفرض عبر الـ trigger أعلاه)
create policy "submissions_insert_own"
on public.submissions for insert
with check (student_id = auth.uid());

-- UPDATE: admin فقط — الطالب لا يملك أي صلاحية تعديل على submissions إطلاقًا
-- (لا grade, لا status, لا can_resubmit) تمامًا كما في بند 42 من التصميم.
create policy "submissions_update_admin_only"
on public.submissions for update
using (public.is_admin())
with check (public.is_admin());
