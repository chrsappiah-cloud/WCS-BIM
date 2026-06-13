-- WCS-BIM four-pillar Supabase/PostgreSQL schema
create extension if not exists pgcrypto;

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  region text,
  status text check (status in ('active','completed','paused')) default 'active',
  created_at timestamptz default now()
);

create table if not exists bim_elements (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  external_guid text,
  element_type text not null,
  dimensions jsonb not null default '{}'::jsonb,
  quantity numeric default 1,
  material_id uuid,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists materials (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  name text not null,
  category text check (category in (
    'concrete','geopolymer','asphalt','soil',
    'steel','FRP','smart_glass','smart_brick'
  )),
  spec jsonb not null default '{}'::jsonb,
  created_at timestamptz default now()
);

alter table bim_elements
  add constraint bim_elements_material_fk
  foreign key (material_id) references materials(id);

create table if not exists material_tests (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  material_id uuid references materials(id),
  bim_element_id uuid references bim_elements(id),
  test_type text not null,
  input_features jsonb not null default '{}'::jsonb,
  measured_values jsonb,
  predicted_values jsonb,
  image_analysis jsonb,
  ai_model text,
  status text default 'pending',
  created_at timestamptz default now()
);

create table if not exists concrete_mixes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  name text not null,
  binder_type text not null default 'OPC',
  cement_kg numeric default 0,
  fly_ash_kg numeric default 0,
  ggbss_kg numeric default 0,
  silica_fume_kg numeric default 0,
  water_kg numeric default 0,
  superplasticizer_kg numeric default 0,
  fine_aggregate_kg numeric default 0,
  coarse_aggregate_kg numeric default 0,
  w_b_ratio numeric,
  scm_ratio numeric,
  sp_ratio numeric,
  age_days int default 28,
  naoh_molarity numeric,
  curing_temperature_c numeric,
  alkali_content_kg numeric,
  compressive_strength_mpa numeric,
  tensile_strength_mpa numeric,
  slump_mm numeric,
  rcpt_coulombs numeric,
  water_absorption_pct numeric,
  created_at timestamptz default now()
);

create table if not exists soil_tests (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  input_features jsonb not null,
  cbr numeric,
  created_at timestamptz default now()
);

create table if not exists asphalt_mixes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  input_features jsonb not null,
  rut_depth_mm numeric,
  stability_kn numeric,
  created_at timestamptz default now()
);

create table if not exists frp_tests (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  input_features jsonb not null,
  tensile_strength_mpa numeric,
  compressive_strength_mpa numeric,
  created_at timestamptz default now()
);

create table if not exists ml_model_registry (
  id uuid primary key default gen_random_uuid(),
  target text not null,
  model_name text not null,
  artifact_uri text not null,
  metrics jsonb not null default '{}'::jsonb,
  feature_schema jsonb not null default '[]'::jsonb,
  is_active boolean default false,
  trained_at timestamptz default now(),
  unique(target, model_name, trained_at)
);

create table if not exists design_alternatives (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  name text not null,
  strategy jsonb not null,
  performance_estimates jsonb not null default '{}'::jsonb,
  bim_view_filter jsonb not null default '{}'::jsonb,
  selected boolean default false,
  created_at timestamptz default now()
);

create table if not exists fabrication_modules (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  name text not null,
  bim_element_ids uuid[] not null default '{}',
  process text check (process in ('CNC','AM','rebar_bending','precast','other')),
  fabrication_hours numeric,
  waste_percentage numeric,
  qa_checkpoints jsonb not null default '[]'::jsonb,
  risks jsonb not null default '[]'::jsonb,
  as_built_feedback jsonb,
  created_at timestamptz default now()
);

create index if not exists material_tests_project_idx on material_tests(project_id);
create index if not exists bim_elements_project_idx on bim_elements(project_id);
create index if not exists fabrication_modules_project_idx on fabrication_modules(project_id);
create index if not exists concrete_mixes_project_idx on concrete_mixes(project_id);
create index if not exists ml_model_registry_target_idx on ml_model_registry(target, is_active);
