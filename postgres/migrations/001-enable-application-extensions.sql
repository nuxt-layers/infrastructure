-- Apply as a privileged migration role, separately per application database.
-- Creates no graph, queue, search index or business objects.
\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS age;
CREATE EXTENSION IF NOT EXISTS pg_textsearch;
CREATE EXTENSION IF NOT EXISTS pgmq CASCADE;
