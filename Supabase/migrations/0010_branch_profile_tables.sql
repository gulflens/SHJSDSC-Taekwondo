-- Stage 1.5 created Swift models + a BranchProfileRepository for facility,
-- hours, programs, inventory, compliance, pricing, financials, media,
-- social_links, safeguarding and milestones — but never created the matching
-- Postgres tables. Until this migration runs, every read returns nothing and
-- every write fails with PGRST205 ("table not found").
--
-- All tables are scoped by branch_id with on-delete cascade so removing a
-- branch tidies up its profile fan-out.
--
-- Conventions chosen to match the live snake_case decoder in
-- SupabaseRepository (snakeToCamel handles _id ↔ ID, _ids ↔ IDs).

-- =====================================================================
-- branch_facilities (one per branch)
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

-- =====================================================================
-- branch_hours (one per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_programs (many per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_inventories (one per branch; items live as jsonb because the
-- editor saves the whole list atomically)
-- =====================================================================
create table if not exists branch_inventories (
    id uuid primary key default gen_random_uuid(),
    branch_id uuid not null unique references branches(id) on delete cascade,
    items jsonb not null default '[]'::jsonb,
    last_audit_at timestamptz not null default now(),
    last_audit_by_user_id uuid not null,
    created_at timestamptz default now()
);

-- =====================================================================
-- branch_compliances (one per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_pricings (one per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_financials (one row per branch per month — admin-gated by RLS)
-- =====================================================================
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

-- =====================================================================
-- branch_medias (one per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_social_links (one per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_safeguardings (one per branch)
-- =====================================================================
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

-- =====================================================================
-- branch_milestones (many per branch — timeline)
-- =====================================================================
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
-- RLS: read for any signed-in user; write for admins only (mirrors
-- existing branches policy from 0002_rls.sql).
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

        -- Drop+recreate so re-runs apply the latest policy text.
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
