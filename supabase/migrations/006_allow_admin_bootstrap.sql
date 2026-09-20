-- Allow the database owner/admin SQL editor to bootstrap the first admin.
-- Client sessions still cannot change their own role or active state.
create or replace function public.prevent_self_privilege_escalation()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.role <> old.role
       or new.is_active <> old.is_active
       or new.student_number is distinct from old.student_number then
      raise exception 'غير مسموح بتعديل هذا الحقل';
    end if;
  end if;
  return new;
end;
$$;
