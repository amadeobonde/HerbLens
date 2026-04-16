-- Recipe Generations — audit + quota backing for the `generate-recipes` edge fn.
--
-- Each row records one Gemini call. Free-tier users are capped at 3 rows per
-- UTC day via a count query inside the edge function. Premium users are
-- uncapped but still logged for analytics.
create table public.recipe_generations (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.user_profiles(id) on delete cascade,
    plant_id uuid references public.plants(id) on delete set null,
    plant_name text,
    model text not null,
    count integer not null default 0,
    generated_at timestamptz not null default now()
);

create index idx_recipe_generations_user_day
    on public.recipe_generations (user_id, generated_at desc);

alter table public.recipe_generations enable row level security;

-- Users can read their own generations (for local caching + quota display)
-- but the edge function inserts on their behalf via the service-role key.
create policy "Users can read own generations"
    on public.recipe_generations for select using (auth.uid() = user_id);
