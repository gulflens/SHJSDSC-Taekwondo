-- Restore Supabase default GRANTs that get lost when the public schema
-- is dropped/recreated. RLS policies are evaluated on top of these
-- table-level privileges — without the GRANTs, every authenticated
-- request returns "42501 permission denied for table X" before the
-- policy is even consulted.
--
-- Run via:  supabase db query --linked --file supabase/migrations/0003_grants.sql
--
-- Idempotent — safe to re-run.

grant all on all tables    in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
grant all on all functions in schema public to anon, authenticated, service_role;

alter default privileges in schema public grant all on tables    to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
