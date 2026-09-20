-- ============================================================
-- 001_profiles.sql
-- جدول profiles + إنشاء تلقائي بعد التسجيل في auth.users + RLS
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  student_number text unique,
  email text not null,
  avatar_url text,
  role text not null default 'student' check (role in ('student', 'admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_student_number on public.profiles (student_number);
create index if not exists idx_profiles_full_name on public.profiles using gin (full_name gin_trgm_ops);

-- نحتاج pg_trgm للبحث الجزئي بالاسم (بند 24 في التصميم: بحث جزئي بالاسم)
create extension if not exists pg_trgm;

-- ------------------------------------------------------------
-- Trigger: عند إنشاء مستخدم جديد في auth.users، أنشئ صفًا في profiles
-- تلقائيًا. full_name و student_number يُمرَّران عبر
-- supabase.auth.signUp(data: {...}) كـ user_metadata من تطبيق Flutter.
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, student_number, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'student_number', ''),
    new.email
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.profiles enable row level security;

-- دالة مساعدة: هل المستخدم الحالي admin؟ (تُستخدم في كل الجداول القادمة أيضًا)
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active = true
  );
$$;

-- SELECT: المستخدم يرى صفّه فقط، الـ admin يرى الجميع
create policy "profiles_select_own_or_admin"
on public.profiles for select
using (id = auth.uid() or public.is_admin());

-- UPDATE: المستخدم يعدّل حقوله الشخصية (لا role, لا is_active, لا student_number)
-- نمنع تعديل الأعمدة الحساسة عبر trigger منفصل بدل تعقيد الـ policy
create policy "profiles_update_own_or_admin"
on public.profiles for update
using (id = auth.uid() or public.is_admin());

create or replace function public.prevent_self_privilege_escalation()
returns trigger language plpgsql as $$
begin
  if not public.is_admin() then
    if new.role <> old.role or new.is_active <> old.is_active
       or new.student_number is distinct from old.student_number then
      raise exception 'غير مسموح بتعديل هذا الحقل';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_profiles_update on public.profiles;
create trigger guard_profiles_update
  before update on public.profiles
  for each row execute function public.prevent_self_privilege_escalation();

-- لا policy لـ INSERT من العميل مباشرة — الإنشاء فقط عبر الـ trigger (security definer)
