-- Replace the example values before running in a non-development environment.

insert into organizations (id, name)
values ('00000000-0000-0000-0000-000000000001', 'WCS BIM Demo')
on conflict (id) do update set name = excluded.name;

-- Add an existing Supabase Auth user after replacing the UUID:
-- insert into org_members (organization_id, user_id, role)
-- values (
--   '00000000-0000-0000-0000-000000000001',
--   'REPLACE-WITH-AUTH-USER-UUID',
--   'admin'
-- )
-- on conflict (organization_id, user_id) do update set role = excluded.role;
