\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA infra_scoped_search;
REVOKE ALL ON SCHEMA infra_scoped_search FROM PUBLIC;
CREATE TABLE infra_scoped_search.documents(id int PRIMARY KEY, tenant text NOT NULL, body text NOT NULL, embedding vector(2) NOT NULL);
INSERT INTO infra_scoped_search.documents VALUES
(1,'a','database graph search','[1,0]'),(2,'a','flowers','[0,1]'),(3,'b','database graph search','[1,0]');
ALTER TABLE infra_scoped_search.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE infra_scoped_search.documents FORCE ROW LEVEL SECURITY;
CREATE POLICY scope ON infra_scoped_search.documents USING (tenant = nullif(current_setting('app.tenant_id',true),''));
CREATE INDEX scoped_bm25 ON infra_scoped_search.documents USING bm25(body) WITH (text_config='english');
CREATE INDEX scoped_vector ON infra_scoped_search.documents USING hnsw(embedding vector_l2_ops);
GRANT USAGE ON SCHEMA infra_scoped_search TO nl_accept_runtime;
GRANT SELECT ON infra_scoped_search.documents TO nl_accept_runtime;
