-- Organization tenancy and production role model.

create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists org_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','project_manager','lab_technician','model_maintainer','viewer')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

alter table projects add column if not exists organization_id uuid references organizations(id) on delete cascade;
alter table materials add column if not exists organization_id uuid references organizations(id) on delete cascade;
alter table material_tests add column if not exists organization_id uuid references organizations(id) on delete cascade;
alter table model_registry add column if not exists organization_id uuid references organizations(id) on delete cascade;

create index if not exists org_members_user_idx on org_members(user_id);
create index if not exists projects_organization_idx on projects(organization_id);
create index if not exists materials_organization_idx on materials(organization_id);
create index if not exists material_tests_organization_idx on material_tests(organization_id);
create index if not exists model_registry_organization_idx on model_registry(organization_id);

alter table organizations enable row level security;
alter table org_members enable row level security;

create or replace function is_org_member(target_organization_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from org_members
    where organization_id = target_organization_id and user_id = auth.uid()
  );
$$;

create or replace function has_org_role(target_organization_id uuid, allowed_roles text[])
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from org_members
    where organization_id = target_organization_id
      and user_id = auth.uid()
      and role = any(allowed_roles)
  );
$$;

drop policy if exists "members read organizations" on organizations;
create policy "members read organizations" on organizations for select using (is_org_member(id));
drop policy if exists "members read org memberships" on org_members;
create policy "members read org memberships" on org_members for select
  using (user_id = auth.uid() or has_org_role(organization_id, array['admin']));
drop policy if exists "admins manage org memberships" on org_members;
create policy "admins manage org memberships" on org_members for all
  using (has_org_role(organization_id, array['admin']))
  with check (has_org_role(organization_id, array['admin']));

drop policy if exists "organization members read projects" on projects;
create policy "organization members read projects" on projects for select
  using (organization_id is not null and is_org_member(organization_id));
drop policy if exists "organization managers update projects" on projects;
create policy "organization managers update projects" on projects for update
  using (has_org_role(organization_id, array['admin','project_manager']))
  with check (has_org_role(organization_id, array['admin','project_manager']));

drop policy if exists "organization members read materials" on materials;
create policy "organization members read materials" on materials for select
  using (organization_id is not null and is_org_member(organization_id));
drop policy if exists "organization material roles manage materials" on materials;
create policy "organization material roles manage materials" on materials for all
  using (has_org_role(organization_id, array['admin','project_manager','lab_technician','model_maintainer']))
  with check (has_org_role(organization_id, array['admin','project_manager','lab_technician','model_maintainer']));

drop policy if exists "organization members read tests" on material_tests;
create policy "organization members read tests" on material_tests for select
  using (organization_id is not null and is_org_member(organization_id));
drop policy if exists "organization lab roles manage tests" on material_tests;
create policy "organization lab roles manage tests" on material_tests for all
  using (has_org_role(organization_id, array['admin','project_manager','lab_technician']))
  with check (has_org_role(organization_id, array['admin','project_manager','lab_technician']));

drop policy if exists "organization members read models" on model_registry;
create policy "organization members read models" on model_registry for select
  using (organization_id is not null and is_org_member(organization_id));
drop policy if exists "organization model roles manage models" on model_registry;
create policy "organization model roles manage models" on model_registry for all
  using (has_org_role(organization_id, array['admin','model_maintainer']))
  with check (has_org_role(organization_id, array['admin','model_maintainer']));
