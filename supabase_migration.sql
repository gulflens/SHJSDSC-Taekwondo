-- ============================================================
-- SHJSDSC Taekwondo — Full Supabase Migration
-- Paste this entire script into Supabase SQL Editor and run.
-- ============================================================

-- 1. USER PROFILES (linked to Supabase Auth)
create table if not exists user_profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    full_name_ar text not null,
    role text not null check (role in (
        'developer','admin','technicalDirector','branchManager','coach','athlete','parent','analyst'
    )),
    primary_branch_id uuid,
    avatar_seed text not null default '',
    linked_athlete_ids jsonb not null default '[]'::jsonb
);

-- 2. BRANCHES
create table if not exists branches (
    id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null,
    name_ar text not null,
    area text not null,
    capacity int not null default 0,
    manager_id uuid references user_profiles(id),
    focus text not null default ''
);

-- back-reference from user_profiles to branches
alter table user_profiles
    add constraint fk_user_primary_branch
    foreign key (primary_branch_id) references branches(id);

-- 3. ATHLETES
create table if not exists athletes (
    id uuid primary key default gen_random_uuid(),
    member_number int not null unique check (member_number between 1001 and 1999),
    full_name text not null,
    full_name_ar text not null,
    date_of_birth timestamptz not null,
    gender text not null check (gender in ('male','female')),
    nationality text not null default 'AE',
    emirates_id text,
    branch_id uuid not null references branches(id),
    primary_coach_id uuid,
    joined_at timestamptz not null default now(),
    current_belt jsonb not null,           -- Belt struct { color, kind, number, awarded_at }
    belt_history jsonb not null default '[]'::jsonb,
    weight_kg float8 not null default 0,
    status text not null check (status in (
        'competitionTeam','readyToGrade','watch','rest','active'
    )),
    avatar_seed text not null default '',
    avatar_url text
);

-- 4. COACHES
create table if not exists coaches (
    id uuid primary key default gen_random_uuid(),
    full_name text not null,
    full_name_ar text not null,
    primary_branch_id uuid not null references branches(id),
    secondary_branch_ids jsonb not null default '[]'::jsonb,  -- UUID[]
    dan_rank int not null default 0,
    wt_coach_licence_level int not null default 0,
    first_aid_expiry timestamptz not null,
    safeguarding_expiry timestamptz not null,
    contract_type text not null check (contract_type in ('fullTime','partTime','contractor')),
    hired_at timestamptz not null default now(),
    avatar_seed text not null default '',
    avatar_url text
);

-- back-reference from athletes to coaches
alter table athletes
    add constraint fk_athlete_coach
    foreign key (primary_coach_id) references coaches(id);

-- 5. CLASS SESSIONS
create table if not exists class_sessions (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    discipline text not null check (discipline in (
        'poomsae','kyorugi','fundamentals','competition','fitness'
    )),
    branch_id uuid not null references branches(id),
    coach_id uuid not null references coaches(id),
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    capacity int not null default 20,
    enrolled_athlete_ids jsonb not null default '[]'::jsonb,
    age_group text not null check (age_group in ('cubs','kids','cadets','juniors','seniors'))
);

create index if not exists idx_sessions_branch_starts on class_sessions(branch_id, starts_at);
create index if not exists idx_sessions_coach_starts on class_sessions(coach_id, starts_at);

-- 6. ATTENDANCE RECORDS
create table if not exists attendance_records (
    id uuid primary key default gen_random_uuid(),
    session_id uuid not null references class_sessions(id),
    athlete_id uuid not null references athletes(id),
    state text not null check (state in ('present','absent','late','excused')),
    recorded_at timestamptz not null default now(),
    unique (session_id, athlete_id)
);

create index if not exists idx_attendance_athlete on attendance_records(athlete_id, recorded_at);

-- 7. PERFORMANCE SCORES
create table if not exists performance_scores (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid not null references athletes(id),
    competition float8 not null default 0,
    technical float8 not null default 0,
    physical float8 not null default 0,
    adherence float8 not null default 0,
    belt_progression float8 not null default 0,
    wellness float8 not null default 0,
    character float8 not null default 0,
    calculated_at timestamptz not null default now()
);

create index if not exists idx_perf_athlete on performance_scores(athlete_id, calculated_at desc);

-- 8. MATCHES
create table if not exists matches (
    id uuid primary key default gen_random_uuid(),
    tournament_name text not null,
    tournament_id uuid,
    date timestamptz not null,
    our_athlete_id uuid not null references athletes(id),
    opponent_athlete_id uuid,
    opponent_name text,
    weight_class_kg float8 not null default 0,
    rounds int not null default 3,
    our_score int not null default 0,
    opponent_score int not null default 0,
    won bool not null default false,
    medal text not null check (medal in ('gold','silver','bronze','none')) default 'none',
    events jsonb not null default '[]'::jsonb  -- embedded ScoreEvent array
);

create index if not exists idx_matches_athlete on matches(our_athlete_id);
create index if not exists idx_matches_tournament on matches(tournament_id);

-- 9. SCORE EVENTS (separate table for realtime subscriptions)
create table if not exists score_events (
    id uuid primary key default gen_random_uuid(),
    match_id uuid not null references matches(id),
    round int not null,
    at_second int not null,
    side text not null check (side in ('chung','hong')),
    action text not null check (action in (
        'headKick','bodyKick','turnBodyKick','turnHeadKick','punch','penalty'
    ))
);

create index if not exists idx_score_events_match on score_events(match_id);

-- 10. PHYSICAL TESTS
create table if not exists physical_tests (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid not null references athletes(id),
    recorded_at timestamptz not null default now(),
    recorded_by_coach_id uuid not null references coaches(id),
    beep_test_stage float8 not null default 0,
    vertical_jump_cm float8 not null default 0,
    sprint_30m_sec float8 not null default 0,
    agility_4x10_sec float8 not null default 0,
    push_ups_1_min int not null default 0,
    notes text
);

create index if not exists idx_physical_athlete on physical_tests(athlete_id, recorded_at desc);

-- 11. TECHNICAL ASSESSMENTS
create table if not exists technical_assessments (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid not null references athletes(id),
    recorded_at timestamptz not null default now(),
    recorded_by_coach_id uuid not null references coaches(id),
    poomsae_form text not null,
    power int not null default 0,
    accuracy int not null default 0,
    rhythm int not null default 0,
    balance int not null default 0,
    expression int not null default 0,
    notes text
);

create index if not exists idx_tech_athlete on technical_assessments(athlete_id, recorded_at desc);

-- 12. WELLNESS ENTRIES
create table if not exists wellness_entries (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid not null references athletes(id),
    recorded_at timestamptz not null default now(),
    sleep_hours float8 not null default 0,
    mood int not null default 0,
    soreness int not null default 0,
    rpe_previous_session int not null default 0,
    notes text
);

create index if not exists idx_wellness_athlete on wellness_entries(athlete_id, recorded_at desc);

-- 13. GRADING SESSIONS
create table if not exists grading_sessions (
    id uuid primary key default gen_random_uuid(),
    scheduled_at timestamptz not null,
    branch_id uuid not null references branches(id),
    examiner_coach_ids jsonb not null default '[]'::jsonb,
    candidate_athlete_ids jsonb not null default '[]'::jsonb,
    status text not null check (status in ('scheduled','inProgress','completed','cancelled'))
        default 'scheduled'
);

create index if not exists idx_grading_branch on grading_sessions(branch_id);

-- 14. GRADING SCORES
create table if not exists grading_scores (
    id uuid primary key default gen_random_uuid(),
    session_id uuid not null references grading_sessions(id),
    athlete_id uuid not null references athletes(id),
    examiner_id uuid not null references coaches(id),
    poomsae int not null default 0,
    kyorugi int not null default 0,
    kibon int not null default 0,
    breaking int not null default 0,
    notes text,
    decision text not null check (decision in ('pass','fail','retry'))
);

create index if not exists idx_grading_scores_session on grading_scores(session_id);

-- 15. GRADING CERTIFICATES
create table if not exists grading_certificates (
    id uuid primary key default gen_random_uuid(),
    athlete_id uuid not null references athletes(id),
    from_belt jsonb not null,   -- Belt struct
    to_belt jsonb not null,     -- Belt struct
    awarded_at timestamptz not null default now(),
    session_id uuid not null references grading_sessions(id),
    signed_by_coach_ids jsonb not null default '[]'::jsonb
);

create index if not exists idx_certs_athlete on grading_certificates(athlete_id);

-- 16. TOURNAMENTS
create table if not exists tournaments (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    name_ar text,
    hosting_federation text not null check (hosting_federation in ('wtf','gcc','uae','clubInternal')),
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    location text not null,
    location_ar text,
    is_official bool not null default false,
    weight_categories_offered jsonb not null default '[]'::jsonb
);

-- back-reference from matches to tournaments
alter table matches
    add constraint fk_match_tournament
    foreign key (tournament_id) references tournaments(id);

-- 17. TOURNAMENT REGISTRATIONS
create table if not exists tournament_registrations (
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid not null references tournaments(id),
    athlete_id uuid not null references athletes(id),
    weight_category text not null,
    seed_rank int,
    registered_at timestamptz not null default now(),
    status text not null check (status in ('registered','weighedIn','withdrawn','disqualified'))
        default 'registered',
    unique (tournament_id, athlete_id)
);

-- 18. WEIGHT CUTS
create table if not exists weight_cuts (
    id uuid primary key default gen_random_uuid(),
    registration_id uuid not null references tournament_registrations(id),
    recorded_at timestamptz not null default now(),
    current_kg float8 not null,
    target_kg float8 not null,
    notes text
);

create index if not exists idx_weight_cuts_reg on weight_cuts(registration_id, recorded_at);

-- 19. BRACKETS
create table if not exists brackets (
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid not null references tournaments(id),
    weight_category text not null,
    seeds jsonb not null default '[]'::jsonb,
    generated_at timestamptz not null default now()
);

-- 20. BRACKET MATCHES
create table if not exists bracket_matches (
    id uuid primary key default gen_random_uuid(),
    bracket_id uuid not null references brackets(id),
    round int not null,
    position int not null,
    athlete_a_id uuid,
    athlete_b_id uuid,
    winner_id uuid,
    match_id uuid references matches(id)
);

create index if not exists idx_bracket_matches on bracket_matches(bracket_id, round);

-- 21. ANNOUNCEMENTS
create table if not exists announcements (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid references branches(id),
    title text not null,
    title_ar text not null,
    body text not null,
    body_ar text not null,
    audience text not null check (audience in ('all','coaches','parents','athletes','branchManagers')),
    published_at timestamptz not null default now(),
    published_by_user_id uuid not null references user_profiles(id),
    requires_rsvp bool not null default false,
    rsvp_deadline timestamptz
);

create index if not exists idx_announcements_audience on announcements(audience, published_at desc);

-- 22. ANNOUNCEMENT RSVPs
create table if not exists announcement_rsvps (
    id uuid primary key default gen_random_uuid(),
    announcement_id uuid not null references announcements(id),
    user_id uuid not null references user_profiles(id),
    response text not null check (response in ('yes','no','maybe')),
    responded_at timestamptz not null default now(),
    unique (announcement_id, user_id)
);

-- 23. CERTIFICATIONS
create table if not exists certifications (
    id uuid primary key default gen_random_uuid(),
    coach_id uuid not null references coaches(id),
    kind text not null check (kind in ('firstAid','safeguarding','wtCoaching','doping','refereeing')),
    issuer text not null,
    issued_at timestamptz not null,
    expires_at timestamptz not null,
    file_ref text
);

create index if not exists idx_certifications_coach on certifications(coach_id);
create index if not exists idx_certifications_expiry on certifications(expires_at);

-- 24. AUDIT LOG
create table if not exists audit_log (
    id uuid primary key default gen_random_uuid(),
    at timestamptz not null default now(),
    actor_user_id uuid not null references user_profiles(id),
    action text not null,
    target_entity text not null,
    target_id uuid not null,
    changes jsonb not null default '{}'::jsonb
);

create index if not exists idx_audit_actor on audit_log(actor_user_id, at desc);
create index if not exists idx_audit_target on audit_log(target_id, at desc);


-- ============================================================
-- ROW LEVEL SECURITY
-- Enables RLS on every table with a permissive "authenticated
-- users can do everything" starter policy. Tighten these per
-- role once your auth flow is stable.
-- ============================================================

do $$
declare
    t text;
begin
    for t in
        select unnest(array[
            'user_profiles','branches','athletes','coaches',
            'class_sessions','attendance_records','performance_scores',
            'matches','score_events',
            'physical_tests','technical_assessments','wellness_entries',
            'grading_sessions','grading_scores','grading_certificates',
            'tournaments','tournament_registrations','weight_cuts',
            'brackets','bracket_matches',
            'announcements','announcement_rsvps',
            'certifications','audit_log'
        ])
    loop
        execute format('alter table %I enable row level security', t);
        execute format(
            'create policy "Authenticated full access" on %I
             for all to authenticated
             using (true) with check (true)', t
        );
    end loop;
end$$;


-- ============================================================
-- REALTIME — enable for live match score events
-- ============================================================

alter publication supabase_realtime add table score_events;
