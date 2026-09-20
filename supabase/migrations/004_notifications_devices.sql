-- ============================================================
-- 004_notifications_devices.sql
-- الإشعارات وأجهزة FCM
-- ============================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  type text not null default 'general'
    check (type in ('general', 'lesson', 'exam', 'submission', 'resubmission')),
  -- polymorphic reference: target_type يحدد كيف يُفسَّر target_id
  -- (subject_id / content_id / submission_id / student_id / null لإشعار عام لكل الطلاب)
  target_type text check (target_type in ('subject', 'content', 'submission', 'student', 'all')),
  target_id uuid,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_created on public.notifications (created_at desc);

-- كل مستخدم يقرأ إشعاراته: نحتفظ بجدول ربط بسيط لحالة القراءة بدل
-- عمود واحد على notifications (لأن نفس الإشعار قد يستهدف عدة طلاب).
create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  fcm_token text not null,
  platform text check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

drop trigger if exists set_devices_updated_at on public.user_devices;
create trigger set_devices_updated_at
  before update on public.user_devices
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.notifications enable row level security;
alter table public.notification_reads enable row level security;
alter table public.user_devices enable row level security;

-- notifications: القراءة تُفلتَر منطقيًا في التطبيق حسب target،
-- لكن الحد الأدنى هنا: أي مستخدم مسجّل يستطيع القراءة، الكتابة admin فقط.
-- (تضييق أدق حسب target يتطلب دالة أعقد؛ نتركه لتحسين لاحق إذا لزم.)
create policy "notifications_select_authenticated"
on public.notifications for select
using (auth.uid() is not null);

create policy "notifications_admin_write"
on public.notifications for insert
with check (public.is_admin());

-- notification_reads: كل مستخدم يدير حالة قراءته فقط
create policy "notification_reads_own"
on public.notification_reads for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- user_devices: كل مستخدم يدير أجهزته فقط
create policy "user_devices_own"
on public.user_devices for all
using (user_id = auth.uid())
with check (user_id = auth.uid());
