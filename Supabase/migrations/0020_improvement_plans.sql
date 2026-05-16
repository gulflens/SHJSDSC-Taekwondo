-- =====================================================================
-- 0020_improvement_plans.sql
--
-- Pillar 10: improvement plans + drill library.
--
-- - drill_library_entry: a club-wide catalogue of named training drills.
-- - improvement_plan: per-athlete coach-managed plans linking weaknesses
--   (stored inline as jsonb because they're a small embedded value type)
--   to drill IDs from the library.
-- =====================================================================

create table if not exists drill_library_entry (
    id                uuid primary key default gen_random_uuid(),
    name              text not null,
    name_ar           text,
    category          text not null
        check (category in ('technique','sparring','flexibility','conditioning','poomsae','footwork')),
    summary           text not null default '',
    video_url         text,
    duration_minutes  int  check (duration_minutes is null or duration_minutes >= 0)
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
        check (status in ('active','completed','archived'))
);

create index if not exists improvement_plan_athlete_idx
    on improvement_plan (athlete_id, created_at desc);

create index if not exists improvement_plan_status_idx
    on improvement_plan (athlete_id, status);

-- =====================================================================
-- Row-level security.
-- =====================================================================
alter table drill_library_entry enable row level security;

create policy "drill_library_read"
    on drill_library_entry
    for select using (auth.uid() is not null);

create policy "drill_library_write"
    on drill_library_entry
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table improvement_plan enable row level security;

create policy "improvement_plan_read"
    on improvement_plan
    for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));

create policy "improvement_plan_write"
    on improvement_plan
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));
