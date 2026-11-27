\set ON_ERROR_STOP on
CREATE SCHEMA infra_phase2_crash;
CREATE TABLE infra_phase2_crash.durable(id int PRIMARY KEY);
CREATE UNLOGGED TABLE infra_phase2_crash.cache(id int PRIMARY KEY);
INSERT INTO infra_phase2_crash.durable VALUES(1);
INSERT INTO infra_phase2_crash.cache VALUES(1);
CHECKPOINT;
