\set ON_ERROR_STOP on
CREATE TABLE IF NOT EXISTS infra_acceptance.durable_fixture (
 id integer PRIMARY KEY,
 value text NOT NULL
);
TRUNCATE infra_acceptance.durable_fixture;
INSERT INTO infra_acceptance.durable_fixture VALUES (1,'survives-clean-restart');
CREATE UNLOGGED TABLE IF NOT EXISTS infra_acceptance.cache_fixture (
 id integer PRIMARY KEY,
 value text NOT NULL
);
TRUNCATE infra_acceptance.cache_fixture;
INSERT INTO infra_acceptance.cache_fixture VALUES (1,'regenerable');
\echo 'PASS: persistence fixtures prepared'
