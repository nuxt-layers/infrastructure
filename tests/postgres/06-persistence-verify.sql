\set ON_ERROR_STOP on
DO $$
DECLARE v text;
DECLARE kind char;
BEGIN
 SELECT value INTO v FROM infra_acceptance.durable_fixture WHERE id=1;
 IF v IS DISTINCT FROM 'survives-clean-restart' THEN
   RAISE EXCEPTION 'Durable fixture lost across clean restart';
 END IF;
 SELECT relpersistence INTO kind
 FROM pg_class WHERE oid='infra_acceptance.cache_fixture'::regclass;
 IF kind <> 'u' THEN RAISE EXCEPTION 'Cache fixture is not UNLOGGED'; END IF;
 SELECT value INTO v FROM infra_acceptance.cache_fixture WHERE id=1;
 IF v IS DISTINCT FROM 'regenerable' THEN
   RAISE EXCEPTION 'UNLOGGED fixture unexpectedly absent after CLEAN restart';
 END IF;
END $$;
DROP SCHEMA infra_acceptance CASCADE;
\echo 'PASS: clean restart and UNLOGGED classification (crash test NOT performed)'
