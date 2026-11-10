\set ON_ERROR_STOP on
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.infra_acceptance_cron_events) THEN
   RAISE EXCEPTION 'pg_cron did not execute the scheduled insertion';
 END IF;
 IF NOT EXISTS (
   SELECT 1 FROM cron.job_run_details d
   JOIN cron.job j ON j.jobid=d.jobid
   WHERE j.jobname='infra_acceptance_probe' AND d.status='succeeded'
 ) THEN
   RAISE EXCEPTION 'pg_cron has no successful execution record';
 END IF;
END $$;
\echo 'PASS: pg_cron execution and successful job history'
