-- Enable the pg_cron extension if not already enabled
create extension if not exists pg_cron;

-- Schedule a daily job to invoke the edge function at 2:00 AM
select cron.schedule(
    'generate-daily-images',
    '0 2 * * *',
    $$
    select net.http_post(
        url := 'https://project-ref.supabase.co/functions/v1/cron-daily-images',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
    );
    $$
);
