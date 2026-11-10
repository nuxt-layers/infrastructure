\set ON_ERROR_STOP on
LOAD 'age';
SET search_path = ag_catalog, public;
SELECT ag_catalog.drop_graph('infra_accept_graph', true)
WHERE EXISTS (SELECT 1 FROM ag_catalog.ag_graph WHERE name='infra_accept_graph');
SELECT ag_catalog.create_graph('infra_accept_graph');
SELECT * FROM cypher('infra_accept_graph', $$
    CREATE (:Person {name: 'Ada'}), (:Person {name: 'Grace'})
$$) AS (v agtype);
SELECT * FROM cypher('infra_accept_graph', $$
    MATCH (a:Person {name: 'Ada'}), (b:Person {name: 'Grace'})
    CREATE (a)-[:KNOWS]->(b)
$$) AS (v agtype);
DO $$
DECLARE matching integer;
BEGIN
  SELECT count(*) INTO matching
    FROM cypher('infra_accept_graph', $cypher$
      MATCH (:Person {name: 'Ada'})-[:KNOWS]->(:Person {name: 'Grace'})
      RETURN 1
    $cypher$) AS (value agtype);
  IF matching <> 1 THEN
    RAISE EXCEPTION 'AGE traversal returned % matches, expected 1', matching;
  END IF;
END $$;
SELECT ag_catalog.drop_graph('infra_accept_graph', true);
RESET search_path;
\echo 'PASS: Apache AGE graph traversal'
