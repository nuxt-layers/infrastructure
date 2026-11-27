\set ON_ERROR_STOP on
-- Separate graphs, no arbitrary Cypher supplied to a privileged function.
LOAD 'age';
SET search_path=ag_catalog,public;
SELECT ag_catalog.create_graph('infra_graph_a');
SELECT ag_catalog.create_graph('infra_graph_b');
SELECT * FROM cypher('infra_graph_a',$$ CREATE (:Person {name:'allowed-a'}) $$) AS (v agtype);
SELECT * FROM cypher('infra_graph_b',$$ CREATE (:Person {name:'private-b'}) $$) AS (v agtype);
RESET search_path;
CREATE ROLE nl_fixture_graph NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE SCHEMA infra_scoped_graph AUTHORIZATION nl_fixture_graph;
REVOKE ALL ON SCHEMA infra_scoped_graph FROM PUBLIC;
GRANT USAGE ON SCHEMA ag_catalog,infra_graph_a TO nl_fixture_graph;
GRANT SELECT ON ALL TABLES IN SCHEMA ag_catalog,infra_graph_a TO nl_fixture_graph;
GRANT EXECUTE ON FUNCTION ag_catalog.cypher(name,cstring,ag_catalog.agtype) TO nl_fixture_graph;
-- Administrator sets a database-scoped session preload only for this fixture login.
-- No global preload and no superuser or arbitrary LOAD rights for runtime.
ALTER ROLE nl_accept_runtime IN DATABASE fixture_db SET session_preload_libraries = 'age';
-- If bounded execution fails, stop acceptance; never grant superuser.
SET ROLE nl_fixture_graph;
CREATE FUNCTION infra_scoped_graph.names_a() RETURNS SETOF text LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,ag_catalog,pg_temp AS $$
 SELECT v::text FROM ag_catalog.cypher('infra_graph_a',$cypher$ MATCH (p:Person) RETURN p.name $cypher$) AS (v ag_catalog.agtype)
$$;
REVOKE ALL ON FUNCTION infra_scoped_graph.names_a() FROM PUBLIC;
GRANT USAGE ON SCHEMA infra_scoped_graph TO nl_accept_runtime;
GRANT EXECUTE ON FUNCTION infra_scoped_graph.names_a() TO nl_accept_runtime;
RESET ROLE;
