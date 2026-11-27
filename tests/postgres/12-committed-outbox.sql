\set ON_ERROR_STOP on
-- Disposable project only. Real commits and retry boundaries.
CREATE SCHEMA infra_phase2_commit;
CREATE TABLE infra_phase2_commit.source(id int PRIMARY KEY);
CREATE TABLE infra_phase2_commit.outbox(event_id int PRIMARY KEY, source_id int NOT NULL REFERENCES infra_phase2_commit.source(id), dispatched boolean NOT NULL DEFAULT false);
CREATE TABLE infra_phase2_commit.receipt(event_id int PRIMARY KEY);
SELECT pgmq.create('infra_phase2_commit_q');
BEGIN;
INSERT INTO infra_phase2_commit.source VALUES(1);
INSERT INTO infra_phase2_commit.outbox VALUES(1,1,false);
COMMIT;
BEGIN;
SELECT pgmq.send('infra_phase2_commit_q',jsonb_build_object('event_id',event_id)) FROM infra_phase2_commit.outbox WHERE NOT dispatched;
UPDATE infra_phase2_commit.outbox SET dispatched=true;
ROLLBACK;
DO $$ BEGIN
 IF (SELECT dispatched FROM infra_phase2_commit.outbox WHERE event_id=1) THEN RAISE EXCEPTION 'Failed relay marked dispatched'; END IF;
 IF EXISTS(SELECT 1 FROM pgmq.read('infra_phase2_commit_q',0,10)) THEN RAISE EXCEPTION 'Failed relay leaked message'; END IF;
END $$;
BEGIN;
SELECT pgmq.send('infra_phase2_commit_q',jsonb_build_object('event_id',event_id)) FROM infra_phase2_commit.outbox WHERE NOT dispatched;
UPDATE infra_phase2_commit.outbox SET dispatched=true WHERE NOT dispatched;
COMMIT;
-- A repeated dispatch finds no pending event.
SELECT pgmq.send('infra_phase2_commit_q',jsonb_build_object('event_id',event_id)) FROM infra_phase2_commit.outbox WHERE NOT dispatched;
-- Simulate delivery followed by worker failure, without acknowledgement.
CREATE TABLE infra_phase2_commit.first_delivery AS SELECT * FROM pgmq.read('infra_phase2_commit_q',1,10);
DO $$ BEGIN
 IF (SELECT count(*) FROM infra_phase2_commit.first_delivery) <> 1 THEN RAISE EXCEPTION 'Expected exactly one initial delivery'; END IF;
END $$;
INSERT INTO infra_phase2_commit.receipt SELECT (message->>'event_id')::int FROM infra_phase2_commit.first_delivery ON CONFLICT DO NOTHING;
SELECT pg_sleep(2);
CREATE TABLE infra_phase2_commit.second_delivery AS SELECT * FROM pgmq.read('infra_phase2_commit_q',30,10);
DO $$ BEGIN
 IF (SELECT count(*) FROM infra_phase2_commit.second_delivery) <> 1 OR (SELECT msg_id FROM infra_phase2_commit.second_delivery) IS DISTINCT FROM (SELECT msg_id FROM infra_phase2_commit.first_delivery) THEN RAISE EXCEPTION 'Redelivery mismatch'; END IF;
END $$;
INSERT INTO infra_phase2_commit.receipt SELECT (message->>'event_id')::int FROM infra_phase2_commit.second_delivery ON CONFLICT DO NOTHING;
DO $$ BEGIN
 IF (SELECT count(*) FROM infra_phase2_commit.receipt) <> 1 THEN RAISE EXCEPTION 'Consumer deduplication failed'; END IF;
END $$;
SELECT pgmq.archive('infra_phase2_commit_q',msg_id) FROM infra_phase2_commit.second_delivery;
SELECT pgmq.drop_queue('infra_phase2_commit_q');
DROP SCHEMA infra_phase2_commit CASCADE;
\echo 'PASS: committed outbox rollback, retry and consumer deduplication fixture'
