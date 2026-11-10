\set ON_ERROR_STOP on
DROP SCHEMA IF EXISTS infra_acceptance CASCADE;
CREATE SCHEMA infra_acceptance;
CREATE TABLE infra_acceptance.documents (
 id integer PRIMARY KEY,
 tenant_id text NOT NULL,
 content text NOT NULL
);
INSERT INTO infra_acceptance.documents VALUES
 (1,'tenant-a','PostgreSQL graph search database engine'),
 (2,'tenant-a','garden flowers soil plants'),
 (3,'tenant-b','PostgreSQL graph search database engine');
CREATE INDEX infra_accept_bm25_idx
 ON infra_acceptance.documents USING bm25(content)
 WITH (text_config='english');
-- Explicit index lookup in pg_textsearch follows PostgreSQL schema visibility.
-- The BM25 index was created in infra_acceptance, not the default public schema.
SET search_path = infra_acceptance, public;
DO $$
DECLARE winning integer;
DECLARE n integer;
BEGIN
 SELECT id INTO winning
 FROM infra_acceptance.documents
 WHERE tenant_id='tenant-a'
 ORDER BY content <@> to_bm25query('postgresql database', 'infra_accept_bm25_idx')
 LIMIT 1;
 IF winning IS DISTINCT FROM 1 THEN
   RAISE EXCEPTION 'BM25 ranked search failed: %', winning;
 END IF;
 SELECT count(*) INTO n FROM infra_acceptance.documents WHERE tenant_id='tenant-a';
 IF n <> 2 THEN
   RAISE EXCEPTION 'Tenant predicate failed: %', n;
 END IF;
END $$;
RESET search_path;
\echo 'PASS: BM25 ranking and example tenant predicate'
