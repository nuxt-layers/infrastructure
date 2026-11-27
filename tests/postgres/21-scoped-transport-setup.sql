\set ON_ERROR_STOP on
-- Fixed-name, fixed-queue SECURITY DEFINER fixture, not a public production API.
-- Owner is a dedicated non-login role; the runtime cannot choose a queue name.
CREATE ROLE nl_fixture_transport NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE SCHEMA infra_scoped_transport AUTHORIZATION nl_fixture_transport;
REVOKE ALL ON SCHEMA infra_scoped_transport FROM PUBLIC;
SELECT pgmq.create('infra_scope_a');
SELECT pgmq.create('infra_scope_b');
SELECT pgmq.send('infra_scope_b','{"event_id":"private-b"}'::jsonb);
GRANT USAGE ON SCHEMA pgmq TO nl_fixture_transport;
GRANT EXECUTE ON FUNCTION pgmq.send(text,jsonb,integer),pgmq.read(text,integer,integer) TO nl_fixture_transport;
-- PGMQ functions execute against queue tables; only grant the chosen queue.
GRANT SELECT,INSERT,UPDATE,DELETE ON pgmq.q_infra_scope_a TO nl_fixture_transport;
GRANT USAGE,SELECT ON SEQUENCE pgmq.q_infra_scope_a_msg_id_seq TO nl_fixture_transport;
SET ROLE nl_fixture_transport;
CREATE FUNCTION infra_scoped_transport.send_a(payload jsonb) RETURNS bigint LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT pgmq.send('infra_scope_a',payload,0)
$$;
CREATE FUNCTION infra_scoped_transport.read_a() RETURNS SETOF jsonb LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT message FROM pgmq.read('infra_scope_a',30,10)
$$;
REVOKE ALL ON FUNCTION infra_scoped_transport.send_a(jsonb),infra_scoped_transport.read_a() FROM PUBLIC;
GRANT USAGE ON SCHEMA infra_scoped_transport TO nl_accept_runtime;
GRANT EXECUTE ON FUNCTION infra_scoped_transport.send_a(jsonb),infra_scoped_transport.read_a() TO nl_accept_runtime;
RESET ROLE;
