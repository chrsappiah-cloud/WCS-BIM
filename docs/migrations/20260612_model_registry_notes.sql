-- Adds human-readable training and deployment notes to existing registries.

alter table model_registry
  add column if not exists notes text;
