\set ON_ERROR_STOP on
-- Operator-only, per owner, per database. Required psql variables:
-- owner_schema, migration_role, runtime_role, diagnostic_role.
-- Role names must be globally unique in this cluster, distinct and dedicated.
-- Creates NOLOGIN roles; operator enables login and sets independent secrets
-- through a secure channel after reviewing the grants. No passwords in SQL.
BEGIN;
SELECT set_config('infra.owner_schema', :'owner_schema', true);
SELECT set_config('infra.migration_role', :'migration_role', true);
SELECT set_config('infra.runtime_role', :'runtime_role', true);
SELECT set_config('infra.diagnostic_role', :'diagnostic_role', true);
DO $$
DECLARE n text; names text[] := ARRAY[current_setting('infra.migration_role'),current_setting('infra.runtime_role'),current_setting('infra.diagnostic_role')];
s text := current_setting('infra.owner_schema');
BEGIN
 IF s !~ '^[a-z][a-z0-9_]{0,47}$' OR s IN ('public','information_schema') OR s LIKE 'pg_%' OR s IN ('ag_catalog','pgmq','cron') THEN RAISE EXCEPTION 'Invalid owner schema'; END IF;
 IF (SELECT count(DISTINCT x) FROM unnest(names) x) <> 3 THEN RAISE EXCEPTION 'Roles must be distinct'; END IF;
 FOREACH n IN ARRAY names LOOP
  IF n !~ '^nl_[a-z][a-z0-9_]{0,44}$' THEN RAISE EXCEPTION 'Invalid dedicated role name'; END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=n) THEN RAISE EXCEPTION 'Role already exists: reconcile separately, never seize existing role %', n; END IF;
  EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT',n);
 END LOOP;
 IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname=s) THEN RAISE EXCEPTION 'Schema already exists; reconcile explicitly'; END IF;
END $$;
CREATE SCHEMA :"owner_schema" AUTHORIZATION :"migration_role";
REVOKE ALL ON SCHEMA :"owner_schema" FROM PUBLIC;
GRANT USAGE ON SCHEMA :"owner_schema" TO :"runtime_role";
-- Deliberately no blanket table grants. Owner migration declares exact table,
-- sequence and function permissions and RLS; diagnostics get no business data.
ALTER DEFAULT PRIVILEGES FOR ROLE :"migration_role" REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
SELECT format('GRANT CONNECT ON DATABASE %I TO %I, %I, %I',current_database(),current_setting('infra.migration_role'),current_setting('infra.runtime_role'),current_setting('infra.diagnostic_role')) \gexec
COMMIT;
