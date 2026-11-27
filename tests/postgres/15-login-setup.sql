\set ON_ERROR_STOP on
-- Synthetic secrets only, inside isolated project.
ALTER ROLE nl_accept_migration LOGIN PASSWORD :'migration_secret';
ALTER ROLE nl_accept_runtime LOGIN PASSWORD :'runtime_secret';
ALTER ROLE nl_accept_diagnostic LOGIN PASSWORD :'diagnostic_secret';
REVOKE CONNECT,TEMP ON DATABASE fixture_db FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
-- Extension entrypoints are not implicitly safe for arbitrary owner logins.
REVOKE ALL ON SCHEMA pgmq,ag_catalog FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA pgmq,ag_catalog FROM PUBLIC;
