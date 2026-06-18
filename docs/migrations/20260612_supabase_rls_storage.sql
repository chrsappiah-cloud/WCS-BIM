-- Supabase-only project membership, RLS, and private storage policies.
-- Run after the WCS-BIM schema and commercial metadata migration.

create table if not exists project_members (
  project_id uuid not null references projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'viewer'
    check (role in ('admin','project_member','viewer','lab_technician','model_maintainer')),
  created_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

alter table project_members enable row level security;
alter table projects enable row level security;
alter table bim_elements enable row level security;
alter table materials enable row level security;
alter table material_tests enable row level security;
alter table mix_optimizations enable row level security;
alter table fabrication_plans enable row level security;
alter table ai_reports enable row level security;
alter table model_registry enable row level security;

create or replace function add_project_creator()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null then
    insert into project_members(project_id,user_id,role)
    values(new.id,auth.uid(),'admin')
    on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists projects_add_creator on projects;
create trigger projects_add_creator
after insert on projects for each row execute function add_project_creator();

create or replace function is_project_member(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from project_members
    where project_id = target_project_id and user_id = auth.uid()
  );
$$;

create or replace function has_project_role(target_project_id uuid, allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from project_members
    where project_id = target_project_id
      and user_id = auth.uid()
      and role = any(allowed_roles)
  );
$$;

drop policy if exists "members read memberships" on project_members;
create policy "members read memberships" on project_members for select
  using (user_id = auth.uid() or has_project_role(project_id, array['admin']));

drop policy if exists "admins manage memberships" on project_members;
create policy "admins manage memberships" on project_members for all
  using (has_project_role(project_id, array['admin']))
  with check (has_project_role(project_id, array['admin']));

drop policy if exists "members read projects" on projects;
create policy "members read projects" on projects for select using (is_project_member(id));
drop policy if exists "authenticated create projects" on projects;
create policy "authenticated create projects" on projects for insert
  with check (auth.uid() is not null);
drop policy if exists "admins update projects" on projects;
create policy "admins update projects" on projects for update
  using (has_project_role(id, array['admin','project_member']))
  with check (has_project_role(id, array['admin','project_member']));

drop policy if exists "members read bim elements" on bim_elements;
create policy "members read bim elements" on bim_elements for select using (is_project_member(project_id));
drop policy if exists "members manage bim elements" on bim_elements;
create policy "members manage bim elements" on bim_elements for all
  using (has_project_role(project_id, array['admin','project_member']))
  with check (has_project_role(project_id, array['admin','project_member']));

drop policy if exists "members read materials" on materials;
create policy "members read materials" on materials for select using (is_project_member(project_id));
drop policy if exists "members manage materials" on materials;
create policy "members manage materials" on materials for all
  using (has_project_role(project_id, array['admin','project_member','lab_technician']))
  with check (has_project_role(project_id, array['admin','project_member','lab_technician']));

drop policy if exists "members read material tests" on material_tests;
create policy "members read material tests" on material_tests for select using (is_project_member(project_id));
drop policy if exists "lab roles manage material tests" on material_tests;
create policy "lab roles manage material tests" on material_tests for all
  using (has_project_role(project_id, array['admin','project_member','lab_technician']))
  with check (has_project_role(project_id, array['admin','project_member','lab_technician']));

drop policy if exists "members read mix optimizations" on mix_optimizations;
create policy "members read mix optimizations" on mix_optimizations for select using (is_project_member(project_id));
drop policy if exists "members manage mix optimizations" on mix_optimizations;
create policy "members manage mix optimizations" on mix_optimizations for all
  using (has_project_role(project_id, array['admin','project_member']))
  with check (has_project_role(project_id, array['admin','project_member']));

drop policy if exists "members read fabrication plans" on fabrication_plans;
create policy "members read fabrication plans" on fabrication_plans for select using (is_project_member(project_id));
drop policy if exists "members manage fabrication plans" on fabrication_plans;
create policy "members manage fabrication plans" on fabrication_plans for all
  using (has_project_role(project_id, array['admin','project_member']))
  with check (has_project_role(project_id, array['admin','project_member']));

drop policy if exists "members read reports" on ai_reports;
create policy "members read reports" on ai_reports for select using (is_project_member(project_id));
drop policy if exists "members create reports" on ai_reports;
create policy "members create reports" on ai_reports for insert
  with check (has_project_role(project_id, array['admin','project_member','lab_technician']));

drop policy if exists "authenticated read active models" on model_registry;
create policy "authenticated read active models" on model_registry for select
  using (auth.uid() is not null and active);

insert into storage.buckets (id, name, public)
values
  ('project-files','project-files',false),
  ('material-tests','material-tests',false),
  ('bim-files','bim-files',false),
  ('site-images','site-images',false),
  ('reports','reports',false)
on conflict (id) do update set public = false;

drop policy if exists "members read project storage" on storage.objects;
create policy "members read project storage" on storage.objects for select
  using (
    bucket_id in ('project-files','material-tests','bim-files','site-images','reports')
    and exists (
      select 1 from project_members
      where user_id = auth.uid() and project_id::text = (storage.foldername(name))[1]
    )
  );

drop policy if exists "members upload project storage" on storage.objects;
create policy "members upload project storage" on storage.objects for insert
  with check (
    bucket_id in ('project-files','material-tests','bim-files','site-images','reports')
    and exists (
      select 1 from project_members
      where user_id = auth.uid()
        and project_id::text = (storage.foldername(name))[1]
        and role in ('admin','project_member','lab_technician')
    )
  );

drop policy if exists "members update project storage" on storage.objects;
create policy "members update project storage" on storage.objects for update
  using (
    bucket_id in ('project-files','material-tests','bim-files','site-images','reports')
    and exists (
      select 1 from project_members
      where user_id = auth.uid()
        and project_id::text = (storage.foldername(name))[1]
        and role in ('admin','project_member','lab_technician')
    )
  );

drop policy if exists "admins delete project storage" on storage.objects;
create policy "admins delete project storage" on storage.objects for delete
  using (
    bucket_id in ('project-files','material-tests','bim-files','site-images','reports')
    and exists (
      select 1 from project_members
      where user_id = auth.uid()
        and project_id::text = (storage.foldername(name))[1]
        and role = 'admin'
    )
  );

create index if not exists project_members_user_idx on project_members(user_id);
