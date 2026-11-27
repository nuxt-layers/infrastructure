\set ON_ERROR_STOP on
SELECT infra_scoped_transport.send_a('{"event_id":"allowed-a"}'::jsonb);
DO $$ DECLARE items jsonb[]; BEGIN
 SELECT array_agg(x) INTO items FROM infra_scoped_transport.read_a() x;
 IF items IS DISTINCT FROM ARRAY['{"event_id":"allowed-a"}'::jsonb] THEN RAISE EXCEPTION 'Scoped delivery mismatch'; END IF;
 BEGIN PERFORM pgmq.send('infra_scope_b','{}'::jsonb); RAISE EXCEPTION 'Direct cross-queue send allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN PERFORM * FROM pgmq.q_infra_scope_b; RAISE EXCEPTION 'Direct cross-queue read allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
