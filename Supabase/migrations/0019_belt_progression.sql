-- =====================================================================
-- 0019_belt_progression.sql
--
-- Pillar 9: belt progression / grading. Adds two coach-managed fields
-- on the athlete row — readiness rating + planned next grading date.
-- Belt history, current belt, and time-at-rank are already covered by
-- existing columns; curriculum mastery for poomsae forms is computed
-- in Swift from `poomsae_known` against the Kukkiwon syllabus map.
-- =====================================================================

alter table athletes
    add column if not exists grading_readiness        int
        check (grading_readiness is null or grading_readiness between 1 and 5),
    add column if not exists next_grading_target_date timestamptz;

create index if not exists athletes_grading_target_idx
    on athletes (next_grading_target_date);
