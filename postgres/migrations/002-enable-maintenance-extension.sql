-- Execute ONLY against the postgres database; pg_cron is configured there.
\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS pg_cron;
