-- =====================================================================
-- 0015_poomsae.sql
--
-- Pillar 4: poomsae repertoire + assessments. Repertoire (the set of
-- forms an athlete can perform) lives on the `athletes` row as a text[]
-- so it survives without a separate join. Detailed assessments — one row
-- per recorded performance — live in `poomsae_assessment`.
-- =====================================================================

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

create index if not exists poomsae_assessment_athlete_idx
    on poomsae_assessment (athlete_id, recorded_at desc);

create index if not exists poomsae_assessment_form_idx
    on poomsae_assessment (athlete_id, form, recorded_at desc);

-- =====================================================================
-- Row-level security — same pattern as physical metrics / technical skills.
-- =====================================================================
alter table poomsae_assessment enable row level security;

create policy "poomsae_assessment_read"
    on poomsae_assessment
    for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));

create policy "poomsae_assessment_write"
    on poomsae_assessment
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));
