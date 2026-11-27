\set ON_ERROR_STOP on
BEGIN;
DO $$ BEGIN
 IF session_user <> 'nl_accept_runtime' OR current_user <> session_user THEN RAISE EXCEPTION 'Not a real runtime login'; END IF;
 IF (SELECT count(*) FROM infra_login.records) <> 0 THEN RAISE EXCEPTION 'Missing scope leaked'; END IF;
END $$;
SELECT set_config('app.tenant_id','a',true);
DO $$ BEGIN
 IF (SELECT array_agg(id) FROM infra_login.records) IS DISTINCT FROM ARRAY[1] THEN RAISE EXCEPTION 'Wrong tenant rows'; END IF;
 BEGIN EXECUTE 'SET ROLE nl_accept_migration'; RAISE EXCEPTION 'Runtime escalated'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN PERFORM pgmq.create('forbidden'); RAISE EXCEPTION 'Unscoped queue access'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN PERFORM ag_catalog.create_graph('forbidden'); RAISE EXCEPTION 'Unscoped graph access'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
COMMIT;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM infra_login.records) THEN RAISE EXCEPTION 'Tenant scope leaked across transaction'; END IF;
END $$;
