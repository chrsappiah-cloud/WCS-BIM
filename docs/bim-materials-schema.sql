-- Standalone schema for a new WCS-BIM materials AI database.

create extension if not exists pgcrypto;

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  location text,
  client_name text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists bim_elements (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  external_guid text,
  external_id text,
  element_type text not null,
  name text,
  level_name text,
  metadata jsonb not null default '{}'::jsonb,
  dimensions jsonb not null default '{}'::jsonb,
  quantity numeric not null default 1,
  material_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists materials (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  name text not null,
  category text not null,
  spec jsonb not null default '{}'::jsonb,
  supplier text,
  unit_cost numeric check (unit_cost is null or unit_cost >= 0),
  co2_factor numeric check (co2_factor is null or co2_factor >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table bim_elements drop constraint if exists bim_elements_material_id_fkey;
alter table bim_elements add constraint bim_elements_material_id_fkey
  foreign key (material_id) references materials(id) on delete set null;

create table if not exists material_tests (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  material_id uuid references materials(id) on delete set null,
  bim_element_id uuid references bim_elements(id) on delete set null,
  test_type text not null,
  age_days integer check (age_days is null or age_days > 0),
  input_features jsonb not null default '{}'::jsonb,
  measured_values jsonb not null default '{}'::jsonb,
  predicted_values jsonb not null default '{}'::jsonb,
  model_name text,
  ai_model text,
  confidence numeric check (confidence is null or confidence between 0 and 1),
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists mix_optimizations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  material_id uuid references materials(id) on delete set null,
  target_strength numeric check (target_strength is null or target_strength >= 0),
  max_cost numeric check (max_cost is null or max_cost >= 0),
  max_co2 numeric check (max_co2 is null or max_co2 >= 0),
  candidate_mixes jsonb not null default '[]'::jsonb,
  chosen_mix jsonb,
  optimizer_name text,
  model_name text,
  status text not null default 'generated'
    check (status in ('generated', 'selected', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists fabrication_plans (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  bim_element_id uuid references bim_elements(id) on delete set null,
  module_name text not null,
  process_type text,
  estimated_time_hours numeric check (estimated_time_hours is null or estimated_time_hours >= 0),
  waste_percent numeric check (waste_percent is null or waste_percent between 0 and 100),
  qa_checkpoints jsonb not null default '[]'::jsonb,
  risks jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists ai_reports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  report_type text not null,
  title text,
  content_md text not null,
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists model_registry (
  id uuid primary key default gen_random_uuid(),
  model_name text not null,
  version text not null,
  task text not null,
  feature_set jsonb not null default '[]'::jsonb,
  metrics jsonb not null default '{}'::jsonb,
  artifact_path text,
  trained_at timestamptz not null default now(),
  active boolean not null default false,
  notes text,
  unique (model_name, version, task)
);

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists projects_set_updated_at on projects;
create trigger projects_set_updated_at
before update on projects
for each row execute function set_updated_at();

drop trigger if exists materials_set_updated_at on materials;
create trigger materials_set_updated_at
before update on materials
for each row execute function set_updated_at();

drop trigger if exists mix_optimizations_set_updated_at on mix_optimizations;
create trigger mix_optimizations_set_updated_at
before update on mix_optimizations
for each row execute function set_updated_at();

create index if not exists bim_elements_project_idx
  on bim_elements(project_id);

create unique index if not exists bim_elements_project_external_id_idx
  on bim_elements(project_id, external_id)
  where external_id is not null;

create index if not exists materials_project_idx
  on materials(project_id);

create index if not exists material_tests_project_idx
  on material_tests(project_id);

create index if not exists material_tests_material_idx
  on material_tests(material_id);

create index if not exists material_tests_bim_element_idx
  on material_tests(bim_element_id);

create index if not exists mix_optimizations_project_idx
  on mix_optimizations(project_id);

create index if not exists mix_optimizations_material_idx
  on mix_optimizations(material_id);

create index if not exists fabrication_plans_project_idx
  on fabrication_plans(project_id);

create index if not exists ai_reports_project_idx
  on ai_reports(project_id, created_at desc);

create index if not exists model_registry_task_active_idx
  on model_registry(task, active);
