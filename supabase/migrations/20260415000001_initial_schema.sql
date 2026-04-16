-- HerbLens Initial Schema
-- Based on herblens_data_structure.json

-- 1. User Profiles
create table public.user_profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text not null,
    display_name text,
    avatar_url text,
    subscription_tier text not null default 'free'
        check (subscription_tier in ('free', 'premium')),
    onboarding_completed boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. Health Profiles (1:1 with user_profiles)
create table public.health_profiles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references public.user_profiles(id) on delete cascade,
    experience_level text not null default 'beginner'
        check (experience_level in ('beginner', 'intermediate', 'advanced')),
    allergies text[] default '{}',
    medications text[] default '{}',
    conditions text[] default '{}',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 3. Health Goals
create table public.health_goals (
    id uuid primary key default gen_random_uuid(),
    health_profile_id uuid not null references public.health_profiles(id) on delete cascade,
    name text not null,
    priority integer not null default 1,
    added_at timestamptz not null default now()
);

-- 4. Plants
create table public.plants (
    id uuid primary key default gen_random_uuid(),
    common_name text not null,
    alternate_names text[] default '{}',
    origin text,
    regions_found text[] default '{}',
    climates text[] default '{}',
    growing_conditions text,
    image_url text,
    thumbnail_url text,
    description text,
    tags text[] default '{}',
    category text check (category in ('Herb', 'Root', 'Flower', 'Bark', 'Leaf', 'Berry', 'Mushroom')),
    featured boolean not null default false,
    access_tier text not null default 'free',
    suggested_prompts text[] default '{}',
    last_updated timestamptz not null default now()
);

-- 5. Plant Uses
create table public.plant_uses (
    id uuid primary key default gen_random_uuid(),
    plant_id uuid not null references public.plants(id) on delete cascade,
    category text not null,
    description text not null,
    access_tier text not null default 'free'
);

-- 6. Plant Contraindications
create table public.plant_contraindications (
    id uuid primary key default gen_random_uuid(),
    plant_id uuid not null references public.plants(id) on delete cascade,
    condition text not null,
    details text not null,
    severity text not null check (severity in ('low', 'moderate', 'high'))
);

-- 7. Recipes
create table public.recipes (
    id uuid primary key default gen_random_uuid(),
    plant_id uuid not null references public.plants(id) on delete cascade,
    title text not null,
    type text not null check (type in ('tea', 'tincture')),
    difficulty text not null check (difficulty in ('beginner', 'intermediate', 'advanced')),
    prep_time text,
    steep_or_cure_time text,
    yield text,
    access_tier text not null default 'premium',
    image_url text
);

-- 8. Recipe Ingredients
create table public.recipe_ingredients (
    id uuid primary key default gen_random_uuid(),
    recipe_id uuid not null references public.recipes(id) on delete cascade,
    name text not null,
    amount text not null,
    notes text,
    sort_order integer not null default 0
);

-- 9. Recipe Steps
create table public.recipe_steps (
    id uuid primary key default gen_random_uuid(),
    recipe_id uuid not null references public.recipes(id) on delete cascade,
    step_number integer not null,
    instruction text not null,
    tip text
);

-- 10. Scans (Vault)
create table public.scans (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.user_profiles(id) on delete cascade,
    photo_url text not null,
    scanned_at timestamptz not null default now(),
    identified_plant_id uuid references public.plants(id),
    confidence_score float,
    user_notes text,
    is_favorited boolean not null default false,
    health_score_at_scan integer
);

-- 11. Highlight Collections
create table public.highlight_collections (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    subtitle text,
    cover_image_url text,
    display_order integer not null default 0,
    access_tier text not null default 'free'
);

-- 12. Highlight Collection Plants (junction)
create table public.highlight_collection_plants (
    collection_id uuid not null references public.highlight_collections(id) on delete cascade,
    plant_id uuid not null references public.plants(id) on delete cascade,
    primary key (collection_id, plant_id)
);

-- 13. Conversations (AI Chat)
create table public.conversations (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.user_profiles(id) on delete cascade,
    context_plant_id uuid references public.plants(id),
    started_at timestamptz not null default now(),
    last_message_at timestamptz not null default now()
);

-- 14. Messages
create table public.messages (
    id uuid primary key default gen_random_uuid(),
    conversation_id uuid not null references public.conversations(id) on delete cascade,
    role text not null check (role in ('user', 'assistant')),
    content text not null,
    timestamp timestamptz not null default now()
);

-- ============================================================
-- Indexes
-- ============================================================

create index idx_plants_common_name on public.plants (common_name);
create index idx_plants_category on public.plants (category);
create index idx_plants_featured on public.plants (featured) where featured = true;

create index idx_scans_user_id on public.scans (user_id);
create index idx_scans_scanned_at on public.scans (scanned_at desc);
create index idx_scans_user_favorited on public.scans (user_id) where is_favorited = true;

create index idx_conversations_user_id on public.conversations (user_id);
create index idx_conversations_last_message on public.conversations (last_message_at desc);

create index idx_messages_conversation_id on public.messages (conversation_id);

create index idx_health_goals_profile on public.health_goals (health_profile_id);

create index idx_plant_uses_plant on public.plant_uses (plant_id);
create index idx_plant_contraindications_plant on public.plant_contraindications (plant_id);

create index idx_recipes_plant on public.recipes (plant_id);
create index idx_recipe_ingredients_recipe on public.recipe_ingredients (recipe_id);
create index idx_recipe_steps_recipe on public.recipe_steps (recipe_id);

-- ============================================================
-- Row Level Security
-- ============================================================

-- Public content: plants, uses, contraindications, recipes, highlights
alter table public.plants enable row level security;
create policy "Plants are publicly readable"
    on public.plants for select using (true);

alter table public.plant_uses enable row level security;
create policy "Plant uses are publicly readable"
    on public.plant_uses for select using (true);

alter table public.plant_contraindications enable row level security;
create policy "Contraindications are publicly readable"
    on public.plant_contraindications for select using (true);

alter table public.recipes enable row level security;
create policy "Recipes are publicly readable"
    on public.recipes for select using (true);

alter table public.recipe_ingredients enable row level security;
create policy "Recipe ingredients are publicly readable"
    on public.recipe_ingredients for select using (true);

alter table public.recipe_steps enable row level security;
create policy "Recipe steps are publicly readable"
    on public.recipe_steps for select using (true);

alter table public.highlight_collections enable row level security;
create policy "Highlights are publicly readable"
    on public.highlight_collections for select using (true);

alter table public.highlight_collection_plants enable row level security;
create policy "Highlight plants are publicly readable"
    on public.highlight_collection_plants for select using (true);

-- User-owned data
alter table public.user_profiles enable row level security;
create policy "Users can read own profile"
    on public.user_profiles for select using (auth.uid() = id);
create policy "Users can insert own profile"
    on public.user_profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile"
    on public.user_profiles for update using (auth.uid() = id);

alter table public.health_profiles enable row level security;
create policy "Users can read own health profile"
    on public.health_profiles for select using (auth.uid() = user_id);
create policy "Users can insert own health profile"
    on public.health_profiles for insert with check (auth.uid() = user_id);
create policy "Users can update own health profile"
    on public.health_profiles for update using (auth.uid() = user_id);

alter table public.health_goals enable row level security;
create policy "Users can manage own health goals"
    on public.health_goals for all using (
        health_profile_id in (
            select id from public.health_profiles where user_id = auth.uid()
        )
    );

alter table public.scans enable row level security;
create policy "Users can read own scans"
    on public.scans for select using (auth.uid() = user_id);
create policy "Users can insert own scans"
    on public.scans for insert with check (auth.uid() = user_id);
create policy "Users can update own scans"
    on public.scans for update using (auth.uid() = user_id);
create policy "Users can delete own scans"
    on public.scans for delete using (auth.uid() = user_id);

alter table public.conversations enable row level security;
create policy "Users can read own conversations"
    on public.conversations for select using (auth.uid() = user_id);
create policy "Users can insert own conversations"
    on public.conversations for insert with check (auth.uid() = user_id);
create policy "Users can update own conversations"
    on public.conversations for update using (auth.uid() = user_id);

alter table public.messages enable row level security;
create policy "Users can manage own messages"
    on public.messages for all using (
        conversation_id in (
            select id from public.conversations where user_id = auth.uid()
        )
    );

-- ============================================================
-- Updated_at triggers
-- ============================================================

create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger set_updated_at before update on public.user_profiles
    for each row execute function public.handle_updated_at();

create trigger set_updated_at before update on public.health_profiles
    for each row execute function public.handle_updated_at();
