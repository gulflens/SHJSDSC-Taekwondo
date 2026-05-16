-- =====================================================================
-- 0018_training_load.sql
--
-- Pillar 8: per-session training load. Acute / chronic / ACWR are
-- computed in Swift from the raw rows — not stored — to avoid drift
-- whenever an entry is edited or backdated.
-- =====================================================================

create table if not exists training_load_entry (
    id                uuid primary key default gen_random_uuid(),
    athlete_id        uuid not null references athletes(id) on delete cascade,
    session_id        uuid references class_sessions(id) on delete set null,
    recorded_at       timestamptz not null,
    session_type      text not null
        check (session_type in ('technique','sparring','fitness','poomsae','mixed')),
    duration_minutes  int  not null check (duration_minutes >= 0),
    rpe               int  not null check (rpe between 1 and 10),
    notes             text
);

create index if not exists training_load_athlete_idx
    on training_load_entry (athlete_id, recorded_at desc);

create index if not exists training_load_session_idx
    on training_load_entry (session_id);

-- =====================================================================
-- Row-level security — coaches manage; athletes/parents read their own.
-- =====================================================================
alter table training_load_entry enable row level security;

create policy "training_load_read"
    on training_load_entry
    for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));

create policy "training_load_write"
    on training_load_entry
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));
