-- =====================================================================
-- 0017_competition_history.sql
--
-- Pillar 7: competition history. Adds event-level metadata to tournaments
-- and per-event result fields to registrations. Per-event win/loss totals
-- and points-for/against are derived from `matches.tournament_id` joins,
-- not stored, to avoid drift.
-- =====================================================================

alter table tournaments
    add column if not exists level             text
        check (level is null or level in ('local','national','regional','international')),
    add column if not exists sanctioning_body  text;

alter table tournament_registrations
    add column if not exists age_division_entered text,
    add column if not exists bracket_size         int  check (bracket_size  is null or bracket_size  between 1 and 1024),
    add column if not exists final_position       int  check (final_position is null or final_position between 1 and 1024),
    add column if not exists medal                text
        check (medal is null or medal in ('gold','silver','bronze','none'));

create index if not exists tournaments_level_idx
    on tournaments (level, starts_at desc);

create index if not exists tournament_registrations_athlete_position_idx
    on tournament_registrations (athlete_id, final_position);
