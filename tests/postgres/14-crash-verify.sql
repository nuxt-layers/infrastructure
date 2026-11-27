\set ON_ERROR_STOP on
DO $$ BEGIN
 IF (SELECT count(*) FROM infra_phase2_crash.durable WHERE id=1) <> 1 THEN RAISE EXCEPTION 'Committed durable data lost'; END IF;
 IF EXISTS(SELECT 1 FROM infra_phase2_crash.cache) THEN RAISE EXCEPTION 'UNLOGGED cache not reset after crash'; END IF;
END $$;
DROP SCHEMA infra_phase2_crash CASCADE;
\echo 'PASS: abrupt crash recovery and regenerable cache reset'
