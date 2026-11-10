\set ON_ERROR_STOP on
CREATE TABLE IF NOT EXISTS public.infra_acceptance_cron_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 created_at timestamptz NOT NULL DEFAULT now()
);
TRUNCATE public.infra_acceptance_cron_events;
SELECT cron.unschedule('infra_acceptance_probe')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname='infra_acceptance_probe');
SELECT cron.schedule('infra_acceptance_probe', '5 seconds',
  'INSERT INTO public.infra_acceptance_cron_events DEFAULT VALUES');
\echo 'PASS: pg_cron acceptance job scheduled'
