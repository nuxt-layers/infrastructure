\set ON_ERROR_STOP on
SELECT cron.unschedule('infra_acceptance_probe')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname='infra_acceptance_probe');
DROP TABLE IF EXISTS public.infra_acceptance_cron_events;
\echo 'PASS: pg_cron fixture removed'
