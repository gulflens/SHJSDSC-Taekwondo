-- =====================================================================
-- 0013_technical_skills.sql
--
-- Replace the legacy `technical_assessments` (poomsae-only, 5 sub-scores)
-- with `technical_skill`: one row per technique capture, scored on two
-- axes (form 1..10, application 1..10), with optional video and notes.
--
-- Column names match the Swift `TechnicalSkill` Codable encoding via the
-- repository's custom snake_case strategy.
-- =====================================================================

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

create index if not exists technical_skill_athlete_idx
    on technical_skill (athlete_id, recorded_at desc);

create index if not exists technical_skill_kind_idx
    on technical_skill (athlete_id, kind, recorded_at desc);

-- =====================================================================
-- Row-level security
-- Coaches and above can read/write skill captures for any athlete; parents
-- and athletes can read their own (matching physical metrics policy).
-- =====================================================================
alter table technical_skill enable row level security;

create policy "technical_skill_read"
    on technical_skill
    for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));

create policy "technical_skill_write"
    on technical_skill
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));
