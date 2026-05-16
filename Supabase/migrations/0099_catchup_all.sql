-- =====================================================================
-- CATCH-UP MIGRATION: applies all schema changes from 0004 through 0022
-- in a single pass. Every statement uses IF NOT EXISTS / IF NOT EXISTS
-- so it is safe to run even if some migrations were already applied.
--
-- Paste this into the Supabase SQL Editor and run it once.
-- =====================================================================

-- =========================
-- 0004: athletes profile
-- =========================
alter table athletes
    add column if not exists passport_number text,
    add column if not exists blood_type text,
    add column if not exists federation_licence_number text,
    add column if not exists parent_user_ids jsonb not null default '[]'::jsonb,
    add column if not exists emergency_contacts jsonb not null default '[]'::jsonb,
    add column if not exists school text,
    add column if not exists image_rights_consent bool not null default false,
    add column if not exists image_rights_consent_date timestamptz,
    add column if not exists travel_permission bool not null default false,
    add column if not exists travel_permission_date timestamptz,
    add column if not exists height_cm numeric,
    add column if not exists weight_history jsonb not null default '[]'::jsonb,
    add column if not exists allergies jsonb not null default '[]'::jsonb,
    add column if not exists medical_conditions jsonb not null default '[]'::jsonb,
    add column if not exists medications jsonb not null default '[]'::jsonb,
    add column if not exists fit_to_train bool not null default true,
    add column if not exists injuries jsonb not null default '[]'::jsonb,
    add column if not exists weight_class text,
    add column if not exists dominant_stance text,
    add column if not exists poomsae_syllabus text,
    add column if not exists kyorugi_tier text,
    add column if not exists training_group_id uuid;

create index if not exists athletes_fit_idx on athletes (fit_to_train);
create index if not exists athletes_kyorugi_tier_idx on athletes (kyorugi_tier);

-- =========================
-- 0005: member number sequence
-- =========================
do $$
declare seed_start int;
begin
    select coalesce(max(member_number), 1000) + 1 into seed_start from athletes;
    if not exists (select 1 from pg_class where relkind = 'S' and relname = 'athlete_member_number_seq') then
        execute format(
            'create sequence athlete_member_number_seq start with %s increment 1 minvalue 1001',
            seed_start
        );
    end if;
end$$;

alter table athletes alter column member_number set default nextval('athlete_member_number_seq');
alter sequence athlete_member_number_seq owned by athletes.member_number;

create or replace function next_member_number() returns int
    language sql security definer set search_path = public
    as $$ select nextval('athlete_member_number_seq')::int $$;

revoke all on function next_member_number() from public;
grant execute on function next_member_number() to authenticated;

-- =========================
-- 0006: open-ended member numbers
-- =========================
alter sequence athlete_member_number_seq no maxvalue;
alter table athletes drop constraint if exists athletes_member_number_check;
alter table athletes add constraint athletes_member_number_check check (member_number >= 1001);

-- =========================
-- 0008: coaches profile
-- =========================
alter table coaches
    add column if not exists kukkiwon_cert_number text,
    add column if not exists kukkiwon_issued_at timestamptz,
    add column if not exists wt_coach_licence_expiry timestamptz,
    add column if not exists poomsae_referee_level int,
    add column if not exists poomsae_referee_expiry timestamptz,
    add column if not exists kyorugi_referee_level int,
    add column if not exists kyorugi_referee_expiry timestamptz,
    add column if not exists anti_doping_expiry timestamptz,
    add column if not exists weekly_hours_target int,
    add column if not exists on_call bool not null default false,
    add column if not exists bio text,
    add column if not exists bio_ar text,
    add column if not exists cpd_hours_this_year numeric not null default 0,
    add column if not exists parent_satisfaction_avg numeric,
    add column if not exists peer_review_avg numeric;

create index if not exists coaches_wt_licence_expiry_idx on coaches (wt_coach_licence_expiry);
create index if not exists coaches_anti_doping_expiry_idx on coaches (anti_doping_expiry);
create index if not exists coaches_on_call_idx on coaches (on_call);

-- =========================
-- 0009: branches profile
-- =========================
alter table branches
    add column if not exists street_address text not null default '',
    add column if not exists street_address_ar text not null default '',
    add column if not exists emirate text not null default 'Sharjah',
    add column if not exists country text not null default 'AE',
    add column if not exists po_box text,
    add column if not exists latitude numeric not null default 0,
    add column if not exists longitude numeric not null default 0,
    add column if not exists google_place_id text,
    add column if not exists phone text not null default '',
    add column if not exists whatsapp_business text,
    add column if not exists email text not null default '',
    add column if not exists founded_at timestamptz not null default now(),
    add column if not exists is_active bool not null default true,
    add column if not exists brand_hex_color text,
    add column if not exists tagline_en text,
    add column if not exists tagline_ar text;

-- =========================
-- 0010: branch profile tables
-- =========================
create table if not exists branch_facilities (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    floor_area_sqm numeric not null default 0,
    hall_count int not null default 1,
    hall_dimensions jsonb not null default '[]'::jsonb,
    has_mirror_walls bool not null default false,
    has_sound_system bool not null default false,
    has_ac bool not null default true,
    has_installed_scoreboard bool not null default false,
    has_pss bool not null default false,
    pss_brand text,
    pss_last_calibration_at timestamptz,
    changing_rooms_m int not null default 0,
    changing_rooms_f int not null default 0,
    spectator_seats int not null default 0,
    parking_spots int not null default 0,
    has_prayer_room bool not null default false,
    has_wudu bool not null default false,
    floor_plan_file_ref text,
    photo_urls jsonb not null default '[]'::jsonb,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create table if not exists branch_hours (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    regular jsonb not null default '[]'::jsonb,
    ramadan jsonb,
    ramadan_start timestamptz,
    ramadan_end timestamptz,
    holiday_closures jsonb not null default '[]'::jsonb,
    term_breaks jsonb not null default '[]'::jsonb,
    created_at timestamptz default now()
);

create table if not exists branch_programs (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null references branches(id) on delete cascade,
    name_key text,
    custom_name text,
    custom_name_ar text,
    description_en text not null default '',
    description_ar text not null default '',
    age_group text not null,
    disciplines jsonb not null default '[]'::jsonb,
    schedule_pattern jsonb not null default '[]'::jsonb,
    start_time text not null,
    end_time text not null,
    capacity int not null default 0,
    current_enrolment int not null default 0,
    monthly_fee_aed numeric not null default 0,
    trial_class_fee_aed numeric,
    registration_fee_aed numeric,
    equipment_package_fee_aed numeric,
    sibling_discount_pct numeric,
    annual_prepay_discount_pct numeric,
    is_active bool not null default true,
    is_women_only bool not null default false,
    created_at timestamptz default now()
);
create index if not exists branch_programs_branch_idx on branch_programs (branch_id);

create table if not exists branch_inventories (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    items jsonb not null default '[]'::jsonb,
    last_audit_at timestamptz not null default now(),
    last_audit_by_user_id uuid not null,
    created_at timestamptz default now()
);

create table if not exists branch_compliances (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    civil_defence_cert_number text,
    civil_defence_expiry timestamptz,
    sharjah_sports_council_reg_number text,
    sharjah_sports_council_expiry timestamptz,
    insurance_policy_number text,
    insurance_provider text,
    insurance_expiry timestamptz,
    last_health_safety_inspection_at timestamptz,
    last_emergency_plan_review_at timestamptz,
    has_aed bool not null default false,
    aed_last_service_at timestamptz,
    first_aid_kit_last_checked_at timestamptz,
    created_at timestamptz default now()
);

create table if not exists branch_pricings (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    base_monthly_fee_aed numeric not null default 0,
    trial_class_fee_aed numeric not null default 0,
    registration_fee_aed numeric not null default 0,
    equipment_package_fee_aed numeric not null default 0,
    sibling_discount_pct numeric not null default 0,
    annual_prepay_discount_pct numeric not null default 0,
    promotions jsonb not null default '[]'::jsonb,
    effective_from timestamptz not null default now(),
    created_at timestamptz default now()
);

create table if not exists branch_financials (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null references branches(id) on delete cascade,
    month timestamptz not null,
    revenue_aed numeric not null default 0,
    rent_aed numeric not null default 0,
    utilities_aed numeric not null default 0,
    staff_cost_aed numeric not null default 0,
    equipment_aed numeric not null default 0,
    marketing_aed numeric not null default 0,
    other_expenses_aed numeric not null default 0,
    outstanding_fees_aed numeric not null default 0,
    active_payment_plans int not null default 0,
    created_at timestamptz default now(),
    unique (branch_id, month)
);
create index if not exists branch_financials_branch_month_idx on branch_financials (branch_id, month desc);

create table if not exists branch_medias (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    logo_url text,
    hero_photo_url text,
    gallery_urls jsonb not null default '[]'::jsonb,
    video_tour_url text,
    floor_plan_url text,
    created_at timestamptz default now()
);

create table if not exists branch_social_links (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    whatsapp_parents_link text,
    whatsapp_athletes_link text,
    telegram_channel_link text,
    instagram_handle text,
    tiktok_handle text,
    youtube_channel_url text,
    website_url text,
    created_at timestamptz default now()
);

create table if not exists branch_safeguardings (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    safeguarding_officer_coach_id uuid references coaches(id) on delete set null,
    last_team_training_at timestamptz,
    policy_document_url text,
    staff_check_current_pct numeric not null default 0,
    open_incident_count int not null default 0,
    last_incident_at timestamptz,
    created_at timestamptz default now()
);

create table if not exists branch_milestones (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null references branches(id) on delete cascade,
    occurred_at timestamptz not null,
    title_en text not null,
    title_ar text not null,
    description_en text,
    description_ar text,
    category text not null,
    created_at timestamptz default now()
);
create index if not exists branch_milestones_branch_idx on branch_milestones (branch_id, occurred_at desc);

-- =========================
-- 0011: athlete identity fields
-- =========================
alter table athletes
    add column if not exists dominant_leg text,
    add column if not exists specialty text,
    add column if not exists years_training int;

-- =========================
-- 0012: physical metrics (replaces physical_tests)
-- =========================
drop table if exists physical_tests cascade;

create table if not exists athlete_physical_metric (
    id                      uuid primary key default gen_random_uuid(),
    athlete_id              uuid not null references athletes(id) on delete cascade,
    recorded_at             timestamptz not null,
    recorded_by_coach_id    uuid references coaches(id),
    kind                    text not null,
    value                   numeric not null,
    leg                     text check (leg is null or leg in ('left','right')),
    notes                   text
);
create index if not exists athlete_physical_metric_athlete_idx on athlete_physical_metric (athlete_id, recorded_at desc);
create index if not exists athlete_physical_metric_kind_idx on athlete_physical_metric (athlete_id, kind, recorded_at desc);

-- =========================
-- 0013: technical skills (replaces technical_assessments)
-- =========================
drop table if exists technical_assessments cascade;

create table if not exists technical_skill (
    id                      uuid primary key default gen_random_uuid(),
    athlete_id              uuid not null references athletes(id) on delete cascade,
    recorded_at             timestamptz not null,
    recorded_by_coach_id    uuid references coaches(id),
    kind                    text not null,
    form_score              int  not null check (form_score between 1 and 10),
    application_score       int  not null check (application_score between 1 and 10),
    video_url               text,
    notes                   text
);
create index if not exists technical_skill_athlete_idx on technical_skill (athlete_id, recorded_at desc);
create index if not exists technical_skill_kind_idx on technical_skill (athlete_id, kind, recorded_at desc);

-- =========================
-- 0014: match sparring fields
-- =========================
alter table matches
    add column if not exists context                 text not null default 'competition',
    add column if not exists match_type              text,
    add column if not exists win_method              text,
    add column if not exists outcome                 text,
    add column if not exists rounds_won              int,
    add column if not exists rounds_lost             int,
    add column if not exists kicks_attempted         int,
    add column if not exists kicks_landed            int,
    add column if not exists punches_attempted       int,
    add column if not exists punches_landed          int,
    add column if not exists our_punch_points         int,
    add column if not exists our_body_kick_points     int,
    add column if not exists our_head_kick_points     int,
    add column if not exists our_spinning_body_points int,
    add column if not exists our_spinning_head_points int,
    add column if not exists opp_punch_points         int,
    add column if not exists opp_body_kick_points     int,
    add column if not exists opp_head_kick_points     int,
    add column if not exists opp_spinning_body_points int,
    add column if not exists opp_spinning_head_points int,
    add column if not exists penalties_given         int,
    add column if not exists penalties_received      int,
    add column if not exists knockdowns_scored       int,
    add column if not exists knockdowns_received     int,
    add column if not exists lead_leg_kicks          int,
    add column if not exists back_leg_kicks          int,
    add column if not exists opening_attacks         int,
    add column if not exists counter_attacks         int,
    add column if not exists top_techniques          text[],
    add column if not exists combinations            text,
    add column if not exists offence_seconds         int,
    add column if not exists defence_seconds         int,
    add column if not exists ring_control_rating     int,
    add column if not exists composure_rating        int,
    add column if not exists score_management_rating int,
    add column if not exists coach_notes             text;

create index if not exists matches_context_idx on matches (context, date desc);

-- =========================
-- 0015: poomsae
-- =========================
alter table athletes
    add column if not exists poomsae_known text[] not null default '{}';

create table if not exists poomsae_assessment (
    id                      uuid primary key default gen_random_uuid(),
    athlete_id              uuid not null references athletes(id) on delete cascade,
    recorded_at             timestamptz not null,
    recorded_by_coach_id    uuid references coaches(id),
    form                    text not null,
    accuracy                int  not null check (accuracy between 1 and 10),
    presentation            int  not null check (presentation between 1 and 10),
    balance                 int  not null check (balance between 1 and 10),
    expression              int  not null check (expression between 1 and 10),
    time_seconds            int  not null check (time_seconds >= 0),
    video_url               text,
    notes                   text
);
create index if not exists poomsae_assessment_athlete_idx on poomsae_assessment (athlete_id, recorded_at desc);
create index if not exists poomsae_assessment_form_idx on poomsae_assessment (athlete_id, form, recorded_at desc);

-- =========================
-- 0016: mental / behavioural
-- =========================
alter table wellness_entries
    add column if not exists motivation int,
    add column if not exists stress     int;

alter table attendance_records
    add column if not exists warmup_rating    int,
    add column if not exists listening_rating int,
    add column if not exists effort_rating    int,
    add column if not exists respect_rating   int;

alter table matches
    add column if not exists pre_match_nerves          int,
    add column if not exists inter_round_recovery      int,
    add column if not exists response_to_losing_point  int,
    add column if not exists response_to_winning_point int;

create table if not exists goal (
    id           uuid primary key default gen_random_uuid(),
    athlete_id   uuid not null references athletes(id) on delete cascade,
    title        text not null,
    target_date  timestamptz,
    status       text not null default 'active' check (status in ('active','completed','abandoned')),
    created_at   timestamptz not null default now(),
    completed_at timestamptz,
    notes        text
);
create index if not exists goal_athlete_idx on goal (athlete_id, created_at desc);
create index if not exists goal_status_idx  on goal (athlete_id, status);

-- =========================
-- 0017: competition history
-- =========================
alter table tournaments
    add column if not exists level             text,
    add column if not exists sanctioning_body  text;

alter table tournament_registrations
    add column if not exists age_division_entered text,
    add column if not exists bracket_size         int,
    add column if not exists final_position       int,
    add column if not exists medal                text;

create index if not exists tournaments_level_idx on tournaments (level, starts_at desc);
create index if not exists tournament_registrations_athlete_position_idx on tournament_registrations (athlete_id, final_position);

-- =========================
-- 0018: training load
-- =========================
create table if not exists training_load_entry (
    id                uuid primary key default gen_random_uuid(),
    athlete_id        uuid not null references athletes(id) on delete cascade,
    session_id        uuid references class_sessions(id) on delete set null,
    recorded_at       timestamptz not null,
    session_type      text not null,
    duration_minutes  int  not null,
    rpe               int  not null,
    notes             text
);
create index if not exists training_load_athlete_idx on training_load_entry (athlete_id, recorded_at desc);
create index if not exists training_load_session_idx on training_load_entry (session_id);

-- =========================
-- 0019: belt progression
-- =========================
alter table athletes
    add column if not exists grading_readiness        int,
    add column if not exists next_grading_target_date timestamptz;

create index if not exists athletes_grading_target_idx on athletes (next_grading_target_date);

-- =========================
-- 0020: improvement plans + drill library
-- =========================
create table if not exists drill_library_entry (
    id                uuid primary key default gen_random_uuid(),
    name              text not null,
    name_ar           text,
    category          text not null,
    summary           text not null default '',
    video_url         text,
    duration_minutes  int
);
create index if not exists drill_library_category_idx on drill_library_entry (category, name);

create table if not exists improvement_plan (
    id                      uuid primary key default gen_random_uuid(),
    athlete_id              uuid not null references athletes(id) on delete cascade,
    created_at              timestamptz not null default now(),
    created_by_coach_id     uuid references coaches(id),
    weaknesses              jsonb not null default '[]'::jsonb,
    recommended_drill_ids   uuid[] not null default '{}',
    notes                   text  not null default '',
    target_date             timestamptz,
    review_date             timestamptz,
    status                  text  not null default 'active'
);
create index if not exists improvement_plan_athlete_idx on improvement_plan (athlete_id, created_at desc);
create index if not exists improvement_plan_status_idx on improvement_plan (athlete_id, status);

-- =========================
-- 0021: drill library metadata
-- =========================
alter table drill_library_entry
    add column if not exists addresses_weakness_tags text[] not null default '{}',
    add column if not exists min_belt                jsonb,
    add column if not exists max_belt                jsonb,
    add column if not exists equipment_required      text[] not null default '{}',
    add column if not exists difficulty              text;

-- =========================
-- 0022: peer benchmarks
-- =========================
create table if not exists peer_benchmark (
    id                  uuid primary key default gen_random_uuid(),
    belt_rank           jsonb,
    age_division        text,
    weight_class        text,
    metric_key          text not null,
    mean                numeric not null,
    standard_deviation  numeric not null,
    sample_size         int not null,
    computed_at         timestamptz not null default now()
);
create index if not exists peer_benchmark_lookup_idx on peer_benchmark (metric_key, age_division, weight_class);
create index if not exists peer_benchmark_metric_idx on peer_benchmark (metric_key);
