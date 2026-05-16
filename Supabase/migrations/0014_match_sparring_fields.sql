-- =====================================================================
-- 0014_match_sparring_fields.sql
--
-- Pillar 3: extend `matches` with the full sparring metric set. All new
-- columns are nullable so existing rows (basic tournament summaries) keep
-- working unchanged. Column names match the Swift `Match` Codable encoding
-- via the repository's snake_case strategy.
-- =====================================================================

alter table matches
    -- Sparring metadata
    add column if not exists context                 text not null default 'competition'
        check (context in ('training','friendly','competition')),
    add column if not exists match_type              text
        check (match_type is null or match_type in ('bestOf3','bestOf5','goldenPoint','single')),
    add column if not exists win_method              text
        check (win_method is null or win_method in ('points','knockout','refereeStop','disqualification','withdrawal')),
    add column if not exists outcome                 text
        check (outcome is null or outcome in ('win','loss','draw')),
    add column if not exists rounds_won              int,
    add column if not exists rounds_lost             int,

    -- Aggregate counts
    add column if not exists kicks_attempted         int,
    add column if not exists kicks_landed            int,
    add column if not exists punches_attempted       int,
    add column if not exists punches_landed          int,

    -- Points scored, by technique value
    add column if not exists our_punch_points         int,
    add column if not exists our_body_kick_points     int,
    add column if not exists our_head_kick_points     int,
    add column if not exists our_spinning_body_points int,
    add column if not exists our_spinning_head_points int,

    -- Points conceded, same breakdown
    add column if not exists opp_punch_points         int,
    add column if not exists opp_body_kick_points     int,
    add column if not exists opp_head_kick_points     int,
    add column if not exists opp_spinning_body_points int,
    add column if not exists opp_spinning_head_points int,

    -- Discipline
    add column if not exists penalties_given         int,
    add column if not exists penalties_received      int,
    add column if not exists knockdowns_scored       int,
    add column if not exists knockdowns_received     int,

    -- Tactical
    add column if not exists lead_leg_kicks          int,
    add column if not exists back_leg_kicks          int,
    add column if not exists opening_attacks         int,
    add column if not exists counter_attacks         int,
    add column if not exists top_techniques          text[],
    add column if not exists combinations            text,
    add column if not exists offence_seconds         int,
    add column if not exists defence_seconds         int,
    add column if not exists ring_control_rating     int check (ring_control_rating is null or ring_control_rating between 1 and 5),
    add column if not exists composure_rating        int check (composure_rating is null or composure_rating between 1 and 5),
    add column if not exists score_management_rating int check (score_management_rating is null or score_management_rating between 1 and 5),
    add column if not exists coach_notes             text;

create index if not exists matches_context_idx on matches (context, date desc);
