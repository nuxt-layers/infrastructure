\set ON_ERROR_STOP on
\connect temporal
REVOKE INSERT, UPDATE, DELETE ON schema_version, schema_update_history FROM temporal_execution;
\connect temporal_visibility
REVOKE INSERT, UPDATE, DELETE ON schema_version, schema_update_history FROM temporal_visibility_runtime;
\connect postgres
ALTER ROLE temporal_migration NOLOGIN;
