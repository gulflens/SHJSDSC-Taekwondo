-- =====================================================================
-- 0012_physical_metrics.sql
--
-- Replace the legacy `physical_tests` snapshot table with a per-measurement
-- model. One row = one captured metric, allowing per-kind frequency
-- detection, charting, and unilateral (left/right) tracking.
--
-- The Swift model `PhysicalMetric` encodes camelCase → snake_case via the
-- repository's custom JSONEncoder; column names below match the encoded
-- field names directly.
-- =====================================================================

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

create index if not exists athlete_physical_metric_athlete_idx
    on athlete_physical_metric (athlete_id, recorded_at desc);

create index if not exists athlete_physical_metric_kind_idx
    on athlete_physical_metric (athlete_id, kind, recorded_at desc);

-- =====================================================================
-- Row-level security
-- Coaches and above can read/write metrics for any athlete; parents and
-- athletes can read their own (matching the existing physical-test policy).
-- =====================================================================
alter table athlete_physical_metric enable row level security;

create policy "physical_metric_read"
    on athlete_physical_metric
    for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));

create policy "physical_metric_write"
    on athlete_physical_metric
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));
