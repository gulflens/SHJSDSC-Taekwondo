-- Extend coaches with the full profile schema (credentials / assignment /
-- performance). All new columns are optional or have safe defaults so
-- existing rows survive without backfill.
--
-- Mirrors 0004_athlete_profile.sql in style: every ADD COLUMN guarded with
-- IF NOT EXISTS so the migration is idempotent and re-runs are safe.

alter table coaches
    -- Credentials
    add column if not exists kukkiwon_cert_number text,
    add column if not exists kukkiwon_issued_at timestamptz,
    add column if not exists wt_coach_licence_expiry timestamptz,
    add column if not exists poomsae_referee_level int,
    add column if not exists poomsae_referee_expiry timestamptz,
    add column if not exists kyorugi_referee_level int,
    add column if not exists kyorugi_referee_expiry timestamptz,
    add column if not exists anti_doping_expiry timestamptz,
    -- Assignment
    add column if not exists weekly_hours_target int,
    add column if not exists on_call bool not null default false,
    add column if not exists bio text,
    add column if not exists bio_ar text,
    -- Performance (snapshot)
    add column if not exists cpd_hours_this_year numeric not null default 0,
    add column if not exists parent_satisfaction_avg numeric,
    add column if not exists peer_review_avg numeric;

-- Speed up "expiring soon" lookups across the certification expiries that
-- actually drive the dashboard nag.
create index if not exists coaches_wt_licence_expiry_idx on coaches (wt_coach_licence_expiry);
create index if not exists coaches_anti_doping_expiry_idx on coaches (anti_doping_expiry);
create index if not exists coaches_on_call_idx on coaches (on_call);
