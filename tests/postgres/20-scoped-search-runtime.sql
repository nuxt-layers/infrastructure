\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = infra_scoped_search, public;
SELECT set_config('app.tenant_id','a',true);
DO $$
DECLARE ids int[];
BEGIN
 SELECT array_agg(id ORDER BY id) INTO ids FROM (SELECT id FROM documents ORDER BY body <@> to_bm25query('database','scoped_bm25') LIMIT 10) s;
 IF ids IS NULL OR NOT (1=ANY(ids)) OR 3=ANY(ids) THEN RAISE EXCEPTION 'BM25 isolation failed: %',ids; END IF;
 SELECT array_agg(id ORDER BY id) INTO ids FROM (SELECT id FROM documents ORDER BY embedding <-> '[1,0]'::vector LIMIT 10) s;
 IF ids IS DISTINCT FROM ARRAY[1,2] THEN RAISE EXCEPTION 'Vector isolation failed: %',ids; END IF;
END $$;
SET LOCAL enable_seqscan=off;
DO $$
DECLARE ids int[];
BEGIN
 SELECT array_agg(id ORDER BY id) INTO ids FROM (SELECT id FROM documents ORDER BY embedding <-> '[1,0]'::vector LIMIT 10) s;
 IF ids IS NULL OR NOT (1=ANY(ids)) OR 3=ANY(ids) THEN RAISE EXCEPTION 'Vector indexed candidate isolation failed: %',ids; END IF;
END $$;
COMMIT;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM infra_scoped_search.documents) THEN RAISE EXCEPTION 'Search missing scope leaked'; END IF;
END $$;
\echo 'PASS: scoped BM25/vector row results (not ranking side-channel proof)'
