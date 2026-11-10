\set ON_ERROR_STOP on
DO $$
DECLARE msg pgmq.message_record;
DECLARE archive_result boolean;
DECLARE seen integer;
BEGIN
 SELECT * INTO msg FROM pgmq.read('infra_accept_q', 10, 1) LIMIT 1;
 IF msg.msg_id IS NULL OR msg.read_ct < 2 THEN
   RAISE EXCEPTION 'pgmq redelivery after VT did not occur';
 END IF;
 SELECT pgmq.archive('infra_accept_q', msg.msg_id) INTO archive_result;
 IF archive_result IS DISTINCT FROM true THEN
   RAISE EXCEPTION 'pgmq archive returned false';
 END IF;
 SELECT count(*) INTO seen FROM pgmq.read('infra_accept_q', 1, 1);
 IF seen <> 0 THEN RAISE EXCEPTION 'Archived pgmq message still deliverable'; END IF;
END $$;
SELECT pgmq.drop_queue('infra_accept_q');
\echo 'PASS: pgmq redelivery and archiving'
