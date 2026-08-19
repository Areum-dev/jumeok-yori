-- Prevent a signed-in user from promoting their own profile role through REST.
-- Existing rows are not changed.
create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if new.role is distinct from old.role
     and current_user not in ('postgres', 'supabase_admin')
     and auth.role() is distinct from 'service_role'
     and not public.is_admin() then
    raise exception 'profile role may only be changed by an administrator'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_profile_role_escalation on public.profiles;
create trigger prevent_profile_role_escalation
before update of role on public.profiles
for each row execute function public.prevent_profile_role_escalation();
