\set ON_ERROR_STOP on
SELECT pgmq.drop_queue('infra_accept_q')
 WHERE EXISTS (SELECT 1 FROM pgmq.list_queues() WHERE queue_name='infra_accept_q');
SELECT pgmq.create('infra_accept_q');
SELECT pgmq.send('infra_accept_q', '{"kind":"acceptance"}'::jsonb);
DO $$
DECLARE msg pgmq.message_record;
DECLARE seen integer;
BEGIN
 SELECT * INTO msg FROM pgmq.read('infra_accept_q', 2, 1) LIMIT 1;
 IF msg.msg_id IS NULL OR msg.message->>'kind' <> 'acceptance' THEN
   RAISE EXCEPTION 'pgmq first delivery missing or invalid';
 END IF;
 SELECT count(*) INTO seen FROM pgmq.read('infra_accept_q', 2, 1);
 IF seen <> 0 THEN RAISE EXCEPTION 'pgmq message visible during VT'; END IF;
END $$;
\echo 'PASS: pgmq initial delivery and visibility timeout'
