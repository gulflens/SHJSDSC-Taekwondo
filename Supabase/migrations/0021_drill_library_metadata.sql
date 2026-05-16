-- =====================================================================
-- 0021_drill_library_metadata.sql
--
-- Pillar 11: extend `drill_library_entry` with weakness tags, belt-rank
-- gates, equipment, and difficulty. Belt ranks live as jsonb so the Swift
-- `BeltRank` value type round-trips without a join table.
-- =====================================================================

alter table drill_library_entry
    add column if not exists addresses_weakness_tags text[] not null default '{}',
    add column if not exists min_belt                jsonb,
    add column if not exists max_belt                jsonb,
    add column if not exists equipment_required      text[] not null default '{}',
    add column if not exists difficulty              text
        check (difficulty is null or difficulty in ('beginner','intermediate','advanced'));

create index if not exists drill_library_difficulty_idx
    on drill_library_entry (difficulty);

-- GIN index lets us search "drills addressing tag X" without a sequential scan.
create index if not exists drill_library_tags_idx
    on drill_library_entry using gin (addresses_weakness_tags);
