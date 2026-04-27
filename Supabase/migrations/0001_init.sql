-- SHJSDSC Taekwondo schema — one table per Core model.
-- Run in the Supabase SQL editor (or via `supabase db push`).
-- Conventions:
--   • `id` is uuid pk, default `gen_random_uuid()`
--   • Snake_case columns; the Swift client decodes via .convertFromSnakeCase
--   • Nested model values (Belt, ScoreEvent[]) live in jsonb columns
--   • UUID arrays use `uuid[]`

create extension if not exists "pgcrypto";

-- =====================================================================
-- user_profiles links auth.users to a Role and (optionally) a branch
-- =====================================================================
create table if not exists user_profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    full_name_ar text not null,
    role text not null check (role in (
        'admin','technicalDirector','branchManager','coach','athlete','parent','analyst'
    )),
    primary_branch_id uuid,
    avatar_seed text,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- =====================================================================
-- branches
-- =====================================================================
create table if not exists branches (
    id uuid primary key default gen_random_uuid(),
    code text unique not null,
    name text not null,
    name_ar text not null,
    area text,
    capacity int,
    manager_id uuid references user_profiles(id),
    focus text,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- =====================================================================
-- coaches
-- =====================================================================
create table if not exists coaches (
    id uuid primary key default gen_random_uuid(),
    user_id uuid unique references auth.users(id),
    full_name text not null,
    full_name_ar text not null,
    primary_branch_id uuid references branches(id),
    secondary_branch_ids uuid[] default '{}',
    dan_rank int,
    wt_coach_licence_level int,
    first_aid_expiry timestamptz,
    safeguarding_expiry timestamptz,
    contract_type text,
    hired_at timestamptz,
    avatar_seed text,
    avatar_url text,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

alter table user_profiles
    add constraint user_profiles_branch_fk
    foreign key (primary_branch_id) references branches(id);

-- =====================================================================
-- athletes
-- =====================================================================
create table if not exists athletes (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id),
    full_name text not null,
    full_name_ar text not null,
    date_of_birth date not null,
    gender text not null check (gender in ('male','female')),
    nationality text default 'AE',
    emirates_id text,
    branch_id uuid references branches(id) on delete cascade,
    primary_coach_id uuid references coaches(id),
    joined_at date not null,
    current_belt jsonb not null,
    belt_history jsonb not null default '[]',
    weight_kg numeric,
    status text not null check (status in (
        'competitionTeam','readyToGrade','watch','rest','active'
    )),
    avatar_seed text,
    avatar_url text,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create index athletes_branch_idx on athletes (branch_id);
create index athletes_coach_idx on athletes (primary_coach_id);

-- =====================================================================
-- parent_links — many-to-many between parent users and athletes
-- =====================================================================
create table if not exists parent_links (
    parent_user_id uuid references auth.users(id) on delete cascade,
    athlete_id uuid references athletes(id) on delete cascade,
    relationship text default 'guardian',
    created_at timestamptz default now(),
    primary key (parent_user_id, athlete_id)
);

-- =====================================================================
-- class_sessions
-- =====================================================================
create table if not exists class_sessions (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    discipline text not null,
    branch_id uuid references branches(id) on delete cascade,
    coach_id uuid references coaches(id),
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    capacity int,
    enrolled_athlete_ids uuid[] default '{}',
    age_group text,
    created_at timestamptz default now()
);

create index class_sessions_branch_starts_at_idx on class_sessions (branch_id, starts_at);
create index class_sessions_coach_starts_at_idx on class_sessions (coach_id, starts_at);

-- =====================================================================
-- attendance_records
-- =====================================================================
create table if not exists attendance_records (
    id uuid primary key default gen_random_uuid(),
    session_id uuid references class_sessions(id) on delete cascade,
    athlete_id uuid references athletes(id) on delete cascade,
    state text not null check (state in ('present','absent','late','excused')),
    recorded_at timestamptz default now(),
    unique (session_id, athlete_id)
);

create index attendance_athlete_recorded_idx on attendance_records (athlete_id, recorded_at desc);

-- =====================================================================
-- performance_scores — one row per snapshot (stored history)
-- =====================================================================
create table if not exists performance_scores (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid references athletes(id) on delete cascade,
    competition numeric, technical numeric, physical numeric,
    adherence numeric, belt_progression numeric, wellness numeric,
    character numeric,
    calculated_at timestamptz default now()
);

create index performance_scores_athlete_calc_idx on performance_scores (athlete_id, calculated_at desc);

-- =====================================================================
-- matches and score_events
-- =====================================================================
create table if not exists matches (
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid,
    tournament_name text not null,
    date timestamptz not null,
    our_athlete_id uuid references athletes(id),
    opponent_athlete_id uuid references athletes(id),
    opponent_name text,
    weight_class_kg numeric,
    rounds int default 3,
    our_score int default 0,
    opponent_score int default 0,
    won bool default false,
    medal text default 'none',
    events jsonb default '[]',
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create index matches_athlete_date_idx on matches (our_athlete_id, date desc);
create index matches_tournament_idx on matches (tournament_id);

create table if not exists score_events (
    id uuid primary key default gen_random_uuid(),
    match_id uuid references matches(id) on delete cascade,
    round int not null,
    at_second int not null,
    side text not null check (side in ('chung','hong')),
    action text not null,
    created_at timestamptz default now()
);

create index score_events_match_idx on score_events (match_id, round, at_second);

-- =====================================================================
-- physical_tests, technical_assessments, wellness_entries
-- =====================================================================
create table if not exists physical_tests (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid references athletes(id) on delete cascade,
    recorded_at timestamptz not null,
    recorded_by_coach_id uuid references coaches(id),
    beep_test_stage numeric, vertical_jump_cm numeric,
    sprint_30m_sec numeric, agility_4x10_sec numeric,
    push_ups_1_min int,
    notes text
);

create table if not exists technical_assessments (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid references athletes(id) on delete cascade,
    recorded_at timestamptz not null,
    recorded_by_coach_id uuid references coaches(id),
    poomsae_form text,
    power int, accuracy int, rhythm int, balance int, expression int,
    notes text
);

create table if not exists wellness_entries (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid references athletes(id) on delete cascade,
    recorded_at timestamptz not null,
    sleep_hours numeric, mood int, soreness int, rpe_previous_session int,
    notes text
);

-- =====================================================================
-- grading
-- =====================================================================
create table if not exists grading_sessions (
    id uuid primary key default gen_random_uuid(),
    scheduled_at timestamptz not null,
    branch_id uuid references branches(id),
    examiner_coach_ids uuid[] default '{}',
    candidate_athlete_ids uuid[] default '{}',
    status text not null default 'scheduled',
    created_at timestamptz default now()
);

create table if not exists grading_scores (
    id uuid primary key default gen_random_uuid(),
    session_id uuid references grading_sessions(id) on delete cascade,
    athlete_id uuid references athletes(id),
    examiner_id uuid references coaches(id),
    poomsae int, kyorugi int, kibon int, breaking int,
    notes text,
    decision text not null,
    created_at timestamptz default now(),
    unique (session_id, athlete_id)
);

create table if not exists grading_certificates (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid references athletes(id),
    from_belt jsonb not null, to_belt jsonb not null,
    awarded_at timestamptz default now(),
    session_id uuid references grading_sessions(id),
    signed_by_coach_ids uuid[] default '{}'
);

-- =====================================================================
-- tournaments
-- =====================================================================
create table if not exists tournaments (
    id uuid primary key default gen_random_uuid(),
    name text not null, name_ar text,
    hosting_federation text not null,
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    location text, location_ar text,
    is_official bool default false,
    weight_categories_offered text[] default '{}',
    created_at timestamptz default now()
);

create table if not exists tournament_registrations (
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid references tournaments(id) on delete cascade,
    athlete_id uuid references athletes(id),
    weight_category text not null,
    seed_rank int,
    registered_at timestamptz default now(),
    status text not null default 'registered'
);

create table if not exists weight_cuts (
    id uuid primary key default gen_random_uuid(),
    registration_id uuid references tournament_registrations(id) on delete cascade,
    recorded_at timestamptz not null,
    current_kg numeric not null,
    target_kg numeric not null,
    notes text
);

create table if not exists brackets (
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid references tournaments(id) on delete cascade,
    weight_category text not null,
    seeds uuid[] default '{}',
    generated_at timestamptz default now()
);

create table if not exists bracket_matches (
    id uuid primary key default gen_random_uuid(),
    bracket_id uuid references brackets(id) on delete cascade,
    round int not null,
    position int not null,
    athlete_a_id uuid references athletes(id),
    athlete_b_id uuid references athletes(id),
    winner_id uuid references athletes(id),
    match_id uuid references matches(id)
);

-- =====================================================================
-- announcements + RSVPs
-- =====================================================================
create table if not exists announcements (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid references branches(id),
    title text not null, title_ar text not null,
    body text not null, body_ar text not null,
    audience text not null,
    published_at timestamptz default now(),
    published_by_user_id uuid references auth.users(id),
    requires_rsvp bool default false,
    rsvp_deadline timestamptz
);

create index announcements_audience_pub_idx on announcements (audience, published_at desc);

create table if not exists announcement_rsvps (
    id uuid primary key default gen_random_uuid(),
    announcement_id uuid references announcements(id) on delete cascade,
    user_id uuid references auth.users(id) on delete cascade,
    response text not null,
    responded_at timestamptz default now(),
    unique (announcement_id, user_id)
);

-- =====================================================================
-- certifications
-- =====================================================================
create table if not exists certifications (
    id uuid primary key default gen_random_uuid(),
    coach_id uuid references coaches(id) on delete cascade,
    kind text not null,
    issuer text not null,
    issued_at timestamptz not null,
    expires_at timestamptz not null,
    file_ref text
);

create index certifications_expiry_idx on certifications (expires_at);

-- =====================================================================
-- audit_log
-- =====================================================================
create table if not exists audit_log (
    id uuid primary key default gen_random_uuid(),
    at timestamptz default now(),
    actor_user_id uuid references auth.users(id),
    action text not null,
    target_entity text not null,
    target_id uuid,
    changes jsonb default '{}'
);

create index audit_log_actor_at_idx on audit_log (actor_user_id, at desc);
create index audit_log_target_idx on audit_log (target_id);
