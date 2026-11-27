\set ON_ERROR_STOP on
CREATE TABLE infra_login.records(id int PRIMARY KEY, tenant text NOT NULL);
INSERT INTO infra_login.records VALUES(1,'a'),(2,'b');
ALTER TABLE infra_login.records ENABLE ROW LEVEL SECURITY;
ALTER TABLE infra_login.records FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_scope ON infra_login.records USING (tenant = nullif(current_setting('app.tenant_id',true),'')) WITH CHECK (tenant = nullif(current_setting('app.tenant_id',true),''));
GRANT SELECT,INSERT,UPDATE,DELETE ON infra_login.records TO nl_accept_runtime;
