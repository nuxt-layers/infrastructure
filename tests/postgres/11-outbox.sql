\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA infra_phase2_outbox;
CREATE TABLE infra_phase2_outbox.source_record(id int PRIMARY KEY);
CREATE TABLE infra_phase2_outbox.outbox(event_id int PRIMARY KEY, source_id int NOT NULL REFERENCES infra_phase2_outbox.source_record(id), dispatched boolean NOT NULL DEFAULT false);
SELECT pgmq.create('infra_phase2_outbox_q');
SAVEPOINT failed_write;
INSERT INTO infra_phase2_outbox.source_record VALUES(1);
INSERT INTO infra_phase2_outbox.outbox VALUES(1,1,false);
ROLLBACK TO SAVEPOINT failed_write;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM infra_phase2_outbox.source_record) OR EXISTS(SELECT 1 FROM infra_phase2_outbox.outbox) THEN RAISE EXCEPTION 'Rollback failed'; END IF;
END $$;
INSERT INTO infra_phase2_outbox.source_record VALUES(2);
INSERT INTO infra_phase2_outbox.outbox VALUES(2,2,false);
-- Demonstrates same-DB atomic relay only, not a shared production outbox.
SELECT pgmq.send('infra_phase2_outbox_q',jsonb_build_object('event_id',event_id)) FROM infra_phase2_outbox.outbox WHERE NOT dispatched;
UPDATE infra_phase2_outbox.outbox SET dispatched=true WHERE NOT dispatched;
DO $$ DECLARE n int; BEGIN
 SELECT count(*) INTO n FROM pgmq.read('infra_phase2_outbox_q',30,10) WHERE message->>'event_id'='2';
 IF n<>1 THEN RAISE EXCEPTION 'Relay fixture failed'; END IF;
END $$;
ROLLBACK;
\echo 'PASS: transactional source/outbox and same-database transport fixture'
