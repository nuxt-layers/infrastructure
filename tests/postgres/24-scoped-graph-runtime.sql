\set ON_ERROR_STOP on
DO $$ DECLARE names text[]; BEGIN
 SELECT array_agg(x) INTO names FROM infra_scoped_graph.names_a() x;
 IF names IS DISTINCT FROM ARRAY['allowed-a'] THEN RAISE EXCEPTION 'Scoped graph mismatch: %',names; END IF;
 BEGIN EXECUTE 'SELECT * FROM infra_graph_b."Person"'; RAISE EXCEPTION 'Direct cross-graph read allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
\echo 'PASS: scoped AGE graph results and cross-graph rejection'
