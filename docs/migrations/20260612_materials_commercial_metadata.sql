-- Additive WCS-BIM materials/commercial metadata migration.
-- Safe to run after docs/ai-bim-supabase-schema.sql.

create extension if not exists pgcrypto;

alter table projects
  add column if not exists description text,
  add column if not exists client_name text,
  add column if not exists updated_at timestamptz default now();

alter table bim_elements
  add column if not exists external_id text,
  add column if not exists name text,
  add column if not exists level_name text,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

alter table materials
  add column if not exists supplier text,
  add column if not exists unit_cost numeric,
  add column if not exists co2_factor numeric,
  add column if not exists updated_at timestamptz default now();

alter table material_tests
  add column if not exists age_days integer,
  add column if not exists model_name text,
  add column if not exists confidence numeric;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'materials_unit_cost_nonnegative'
  ) then
    alter table materials add constraint materials_unit_cost_nonnegative
      check (unit_cost is null or unit_cost >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'materials_co2_factor_nonnegative'
  ) then
    alter table materials add constraint materials_co2_factor_nonnegative
      check (co2_factor is null or co2_factor >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'material_tests_age_days_positive'
  ) then
    alter table material_tests add constraint material_tests_age_days_positive
      check (age_days is null or age_days > 0);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'material_tests_confidence_range'
  ) then
    alter table material_tests add constraint material_tests_confidence_range
      check (confidence is null or confidence between 0 and 1);
  end if;
end $$;

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
    check (status in ('generated','selected','approved','rejected')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
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
  created_at timestamptz default now()
);

create table if not exists ai_reports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  report_type text not null,
  title text,
  content_md text not null,
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists model_registry (
  id uuid primary key default gen_random_uuid(),
  model_name text not null,
  version text not null,
  task text not null,
  feature_set jsonb not null default '[]'::jsonb,
  metrics jsonb not null default '{}'::jsonb,
  artifact_path text,
  trained_at timestamptz default now(),
  active boolean not null default false,
  notes text,
  unique (model_name, version, task)
);

alter table model_registry add column if not exists notes text;

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
before update on projects for each row execute function set_updated_at();

drop trigger if exists materials_set_updated_at on materials;
create trigger materials_set_updated_at
before update on materials for each row execute function set_updated_at();

drop trigger if exists mix_optimizations_set_updated_at on mix_optimizations;
create trigger mix_optimizations_set_updated_at
before update on mix_optimizations for each row execute function set_updated_at();

create index if not exists material_tests_material_idx on material_tests(material_id);
create index if not exists material_tests_bim_element_idx on material_tests(bim_element_id);
create index if not exists bim_elements_external_id_idx on bim_elements(project_id, external_id);
create index if not exists mix_optimizations_project_idx on mix_optimizations(project_id);
create index if not exists mix_optimizations_material_idx on mix_optimizations(material_id);
create index if not exists fabrication_plans_project_idx on fabrication_plans(project_id);
create index if not exists ai_reports_project_idx on ai_reports(project_id, created_at desc);
create index if not exists model_registry_task_active_idx on model_registry(task, active);
