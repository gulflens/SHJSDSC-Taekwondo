-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Bring an existing live SHJSDSC Supabase project up to the latest     ║
-- ║ schema the Swift app expects. Safe to run multiple times — every     ║
-- ║ statement uses IF NOT EXISTS / DROP+CREATE patterns.                 ║
-- ║                                                                      ║
-- ║ Paste the entire file into the Supabase SQL editor and run it.       ║
-- ║ At the end you'll see a verification table listing column counts     ║
-- ║ for every Swift-encoded table — compare against the expected count   ║
-- ║ printed in the comment block at the bottom.                          ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- =====================================================================
-- 0004 athlete profile (re-applies safely)
-- =====================================================================
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

-- =====================================================================
-- 0005-0007 athlete member-number sequence
-- =====================================================================
do $$
begin
    if not exists (select 1 from pg_class where relname = 'athlete_member_number_seq') then
        create sequence athlete_member_number_seq start with 1001 minvalue 1001 owned by athletes.member_number;
    end if;
end $$;

alter sequence athlete_member_number_seq no maxvalue;
alter table athletes drop constraint if exists athletes_member_number_check;
alter table athletes add constraint athletes_member_number_check check (member_number >= 1001);

create or replace function next_member_number() returns int
language sql security definer as $$
    select nextval('athlete_member_number_seq')::int;
$$;

grant execute on function next_member_number() to anon, authenticated, service_role;

-- =====================================================================
-- 0008 coach profile
-- =====================================================================
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

-- =====================================================================
-- 0009 branch identity / contact / branding columns
-- =====================================================================
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

create index if not exists branches_is_active_idx on branches (is_active);

-- =====================================================================
-- 0010 branch profile sub-tables (the big missing piece — these never
-- existed on live, so every BranchEditView save was a no-op)
-- =====================================================================
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

-- =====================================================================
-- RLS for the new branch profile tables (mirrors branches policies)
-- =====================================================================
do $$
declare
    t text;
begin
    for t in select unnest(array[
        'branch_facilities','branch_hours','branch_programs','branch_inventories',
        'branch_compliances','branch_pricings','branch_financials','branch_medias',
        'branch_social_links','branch_safeguardings','branch_milestones'
    ]) loop
        execute format('alter table %I enable row level security', t);

        execute format('drop policy if exists "all_read_%s" on %I', t, t);
        execute format(
            'create policy "all_read_%s" on %I for select using (auth.uid() is not null)',
            t, t
        );

        execute format('drop policy if exists "admin_write_%s" on %I', t, t);
        execute format(
            'create policy "admin_write_%s" on %I for all using (auth_is_admin()) with check (auth_is_admin())',
            t, t
        );
    end loop;
end $$;

-- =====================================================================
-- Verification: column counts per table. Compare these against the
-- "expected" numbers below — any mismatch means a column is missing
-- from your live DB and the matching Swift insert will fail.
-- =====================================================================
select table_name,
       count(*) as actual_columns
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'branches','athletes','coaches',
    'branch_facilities','branch_hours','branch_programs','branch_inventories',
    'branch_compliances','branch_pricings','branch_financials','branch_medias',
    'branch_social_links','branch_safeguardings','branch_milestones'
  )
group by table_name
order by table_name;

-- Expected column counts (matches Stage 1.5 Swift models + bookkeeping cols):
--   branches              26  (8 stage-0 + 16 stage-1.5 + 2 timestamps)
--   athletes              42  (20 stage-0/1 + 22 profile)
--   coaches               33  (14 stage-0 + 17 stage-1.5 + 2 timestamps)
--   branch_facilities     22
--   branch_hours           8
--   branch_programs       23
--   branch_inventories     6
--   branch_compliances    15
--   branch_pricings       11
--   branch_financials     14
--   branch_medias          8
--   branch_social_links   10
--   branch_safeguardings   9
--   branch_milestones     10
