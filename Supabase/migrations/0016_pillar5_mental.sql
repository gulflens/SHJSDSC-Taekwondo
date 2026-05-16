-- =====================================================================
-- 0016_pillar5_mental.sql
--
-- Pillar 5: mental / behavioural metrics. Extends three existing tables
-- with optional fields and adds a new `goal` table for goal tracking.
--
-- - wellness_entries: motivation + stress (1..10). Mood/soreness move from
--   1..5 to 1..10 in the Swift model — the column type is unchanged so
--   existing rows on the 1..5 scale remain valid (1..5 ⊂ 1..10).
-- - attendance_records: 4 coach-engagement sub-ratings (1..5).
-- - matches: 4 post-competition mental ratings (1..5).
-- - goal: per-athlete goal tracking with status + target date.
-- =====================================================================

alter table wellness_entries
    add column if not exists motivation int check (motivation is null or motivation between 1 and 10),
    add column if not exists stress     int check (stress     is null or stress     between 1 and 10);

alter table attendance_records
    add column if not exists warmup_rating    int check (warmup_rating    is null or warmup_rating    between 1 and 5),
    add column if not exists listening_rating int check (listening_rating is null or listening_rating between 1 and 5),
    add column if not exists effort_rating    int check (effort_rating    is null or effort_rating    between 1 and 5),
    add column if not exists respect_rating   int check (respect_rating   is null or respect_rating   between 1 and 5);

alter table matches
    add column if not exists pre_match_nerves          int check (pre_match_nerves          is null or pre_match_nerves          between 1 and 5),
    add column if not exists inter_round_recovery      int check (inter_round_recovery      is null or inter_round_recovery      between 1 and 5),
    add column if not exists response_to_losing_point  int check (response_to_losing_point  is null or response_to_losing_point  between 1 and 5),
    add column if not exists response_to_winning_point int check (response_to_winning_point is null or response_to_winning_point between 1 and 5);

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

-- =====================================================================
-- Row-level security: athletes / parents linked to the athlete can both
-- read and write their own goals. Coaches and above can manage any.
-- =====================================================================
alter table goal enable row level security;

create policy "goal_read"
    on goal
    for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));

create policy "goal_write"
    on goal
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach') or auth_is_linked_to(athlete_id))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach') or auth_is_linked_to(athlete_id));
