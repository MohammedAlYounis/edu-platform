-- Restrict notification reads at the database boundary.
-- The Flutter query remains an optimization; it is not the security boundary.
drop policy if exists "notifications_select_authenticated" on public.notifications;
drop policy if exists "notifications_select_targeted" on public.notifications;

create policy "notifications_select_targeted"
on public.notifications for select
using (
  public.is_admin()
  or (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.is_active = true
    )
    and (
      target_type = 'all'
      or (target_type = 'student' and target_id = auth.uid())
      or (
        target_type = 'subject'
        and exists (
          select 1 from public.subjects s
          where s.id = target_id and s.is_active = true
        )
      )
      or (
        target_type = 'content'
        and exists (
          select 1 from public.contents c
          where c.id = target_id and c.is_active = true
        )
      )
    )
  )
);
