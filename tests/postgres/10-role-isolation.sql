\set ON_ERROR_STOP on
BEGIN;
-- Transaction-scoped synthetic fixtures; entire transaction rolled back.
CREATE ROLE nl_fixture_owner NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE ROLE nl_fixture_runtime NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE ROLE nl_fixture_other NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE ROLE nl_fixture_diagnostic NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE SCHEMA infra_phase2 AUTHORIZATION nl_fixture_owner;
CREATE SCHEMA infra_phase2_other AUTHORIZATION nl_fixture_other;
REVOKE ALL ON SCHEMA infra_phase2,infra_phase2_other FROM PUBLIC;
SET LOCAL ROLE nl_fixture_owner;
CREATE TABLE infra_phase2.records(id int PRIMARY KEY, tenant text NOT NULL, body text NOT NULL);
INSERT INTO infra_phase2.records VALUES (1,'a','café database'),(2,'b','café database');
ALTER TABLE infra_phase2.records ENABLE ROW LEVEL SECURITY;
ALTER TABLE infra_phase2.records FORCE ROW LEVEL SECURITY;
CREATE POLICY scoped ON infra_phase2.records USING (tenant = nullif(current_setting('app.tenant_id',true),'')) WITH CHECK (tenant = nullif(current_setting('app.tenant_id',true),''));
GRANT USAGE ON SCHEMA infra_phase2 TO nl_fixture_runtime;
GRANT SELECT,INSERT,UPDATE,DELETE ON infra_phase2.records TO nl_fixture_runtime;
RESET ROLE;
SET LOCAL ROLE nl_fixture_other;
CREATE TABLE infra_phase2_other.secret(id int);
RESET ROLE;
SET LOCAL ROLE nl_fixture_runtime;
DO $$ BEGIN
 IF (SELECT count(*) FROM infra_phase2.records) <> 0 THEN RAISE EXCEPTION 'Missing tenant leaked rows'; END IF;
END $$;
SELECT set_config('app.tenant_id','a',true);
DO $$ BEGIN
 IF (SELECT array_agg(id ORDER BY id) FROM infra_phase2.records) IS DISTINCT FROM ARRAY[1] THEN RAISE EXCEPTION 'RLS read failed'; END IF;
 IF (SELECT count(*) FROM infra_phase2.records WHERE to_tsvector('simple',body) @@ plainto_tsquery('simple','café')) <> 1 THEN RAISE EXCEPTION 'Search isolation failed'; END IF;
 BEGIN INSERT INTO infra_phase2.records VALUES (3,'b','forbidden'); RAISE EXCEPTION 'Cross-tenant insert allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 UPDATE infra_phase2.records SET body='forbidden' WHERE id=2;
 IF FOUND THEN RAISE EXCEPTION 'Cross-tenant update allowed'; END IF;
 BEGIN PERFORM * FROM infra_phase2_other.secret; RAISE EXCEPTION 'Cross-schema read allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN EXECUTE 'ALTER TABLE infra_phase2.records DISABLE ROW LEVEL SECURITY'; RAISE EXCEPTION 'Runtime changed RLS'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
SET LOCAL ROLE nl_fixture_diagnostic;
DO $$ BEGIN
 BEGIN PERFORM * FROM infra_phase2.records; RAISE EXCEPTION 'Diagnostic read allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
-- Explicitly test the optional vector extension without permanently enabling it.
CREATE EXTENSION IF NOT EXISTS vector;
DO $$ BEGIN
 IF (SELECT '[1,0]'::vector <-> '[1,0]'::vector) <> 0 THEN RAISE EXCEPTION 'Vector distance failed'; END IF;
 IF similarity('postgres','postgres') <> 1 THEN RAISE EXCEPTION 'Trigram similarity failed'; END IF;
END $$;
ROLLBACK;
\echo 'PASS: synthetic PostgreSQL isolation, native search, trigram and vector fixtures'
