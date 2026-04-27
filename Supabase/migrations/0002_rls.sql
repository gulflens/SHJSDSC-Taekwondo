-- Row Level Security policies for SHJSDSC. Mirrors the
-- Core/Models/Permissions.swift PermissionMatrix at the database tier so that
-- a coach phone, an admin tablet, and a parent app all hit the same gates
-- regardless of UI.
--
-- Pattern:
--   • admins: full access on every table
--   • TD/analyst: read everything
--   • branchManager: local scope (branch_id matches their primary_branch_id)
--   • coach: read+update their own athletes/sessions; write attendance/
--     grading scores; read everything in their branch
--   • athlete: read self
--   • parent: read children via parent_links
--
-- Audit log policy: append-only for any authenticated user; read for admin+TD.

-- Helper to inline role lookups
create or replace function auth_role() returns text language sql stable as $$
    select role from user_profiles where id = auth.uid();
$$;

create or replace function auth_branch() returns uuid language sql stable as $$
    select primary_branch_id from user_profiles where id = auth.uid();
$$;

create or replace function auth_is_admin() returns bool language sql stable as $$
    select coalesce(auth_role() = 'admin', false);
$$;

create or replace function auth_can_read_all() returns bool language sql stable as $$
    select auth_role() in ('admin','technicalDirector','analyst');
$$;

-- =====================================================================
-- user_profiles
-- =====================================================================
alter table user_profiles enable row level security;
create policy "self_read_profile" on user_profiles for select using (id = auth.uid() or auth_can_read_all());
create policy "self_update_profile" on user_profiles for update using (id = auth.uid() or auth_is_admin());
create policy "admin_insert_profile" on user_profiles for insert with check (auth_is_admin() or id = auth.uid());

-- =====================================================================
-- branches — public read; admin only write
-- =====================================================================
alter table branches enable row level security;
create policy "all_read_branches" on branches for select using (auth.uid() is not null);
create policy "admin_write_branches" on branches for all using (auth_is_admin()) with check (auth_is_admin());

-- =====================================================================
-- coaches
-- =====================================================================
alter table coaches enable row level security;
create policy "all_read_coaches" on coaches for select using (auth.uid() is not null);
create policy "admin_write_coaches" on coaches for all using (auth_is_admin()) with check (auth_is_admin());
create policy "coach_update_self" on coaches for update using (user_id = auth.uid());

-- =====================================================================
-- athletes
-- =====================================================================
alter table athletes enable row level security;

create policy "admins_all_athletes" on athletes for all
    using (auth_is_admin()) with check (auth_is_admin());

create policy "td_read_athletes" on athletes for select
    using (auth_can_read_all());

create policy "branch_local_athletes" on athletes for select
    using (branch_id = auth_branch());

create policy "coach_update_own_athletes" on athletes for update
    using (primary_coach_id in (select id from coaches where user_id = auth.uid()))
    with check (primary_coach_id in (select id from coaches where user_id = auth.uid()));

create policy "athlete_self_read" on athletes for select
    using (user_id = auth.uid());

create policy "parent_children_read" on athletes for select
    using (id in (select athlete_id from parent_links where parent_user_id = auth.uid()));

-- =====================================================================
-- parent_links — admin manages, parents read their own
-- =====================================================================
alter table parent_links enable row level security;
create policy "parent_self_links" on parent_links for select using (parent_user_id = auth.uid() or auth_can_read_all());
create policy "admin_write_links" on parent_links for all using (auth_is_admin()) with check (auth_is_admin());

-- =====================================================================
-- class_sessions — branch-scoped
-- =====================================================================
alter table class_sessions enable row level security;
create policy "all_read_sessions" on class_sessions for select using (auth.uid() is not null);
create policy "admin_branch_write_sessions" on class_sessions for all
    using (auth_is_admin() or branch_id = auth_branch())
    with check (auth_is_admin() or branch_id = auth_branch());

-- =====================================================================
-- attendance_records — coaches write for their athletes; everyone reads
-- =====================================================================
alter table attendance_records enable row level security;
create policy "all_read_attendance" on attendance_records for select using (auth.uid() is not null);
create policy "coach_write_attendance" on attendance_records for all
    using (
        auth_is_admin()
        or athlete_id in (
            select a.id from athletes a
            join coaches c on c.id = a.primary_coach_id
            where c.user_id = auth.uid()
        )
    )
    with check (
        auth_is_admin()
        or athlete_id in (
            select a.id from athletes a
            join coaches c on c.id = a.primary_coach_id
            where c.user_id = auth.uid()
        )
    );

-- =====================================================================
-- performance_scores, matches, score_events, physical_tests,
-- technical_assessments, wellness_entries — readable by everyone
-- authenticated; writable by admin + coaches for their own athletes
-- =====================================================================
alter table performance_scores enable row level security;
create policy "all_read_perf" on performance_scores for select using (auth.uid() is not null);
create policy "admin_write_perf" on performance_scores for all using (auth_is_admin()) with check (auth_is_admin());

alter table matches enable row level security;
create policy "all_read_matches" on matches for select using (auth.uid() is not null);
create policy "admin_coach_write_matches" on matches for all
    using (
        auth_is_admin()
        or our_athlete_id in (
            select a.id from athletes a
            join coaches c on c.id = a.primary_coach_id
            where c.user_id = auth.uid()
        )
    )
    with check (
        auth_is_admin()
        or our_athlete_id in (
            select a.id from athletes a
            join coaches c on c.id = a.primary_coach_id
            where c.user_id = auth.uid()
        )
    );

alter table score_events enable row level security;
create policy "all_read_events" on score_events for select using (auth.uid() is not null);
create policy "admin_coach_write_events" on score_events for all
    using (auth_is_admin() or auth_role() in ('coach','technicalDirector'))
    with check (auth_is_admin() or auth_role() in ('coach','technicalDirector'));

alter table physical_tests enable row level security;
create policy "all_read_physical" on physical_tests for select using (auth.uid() is not null);
create policy "coach_write_physical" on physical_tests for all
    using (auth_is_admin() or recorded_by_coach_id in (select id from coaches where user_id = auth.uid()))
    with check (auth_is_admin() or recorded_by_coach_id in (select id from coaches where user_id = auth.uid()));

alter table technical_assessments enable row level security;
create policy "all_read_technical" on technical_assessments for select using (auth.uid() is not null);
create policy "coach_write_technical" on technical_assessments for all
    using (auth_is_admin() or recorded_by_coach_id in (select id from coaches where user_id = auth.uid()))
    with check (auth_is_admin() or recorded_by_coach_id in (select id from coaches where user_id = auth.uid()));

alter table wellness_entries enable row level security;
create policy "self_read_wellness" on wellness_entries for select
    using (
        auth_can_read_all()
        or athlete_id in (select id from athletes where user_id = auth.uid())
        or athlete_id in (select athlete_id from parent_links where parent_user_id = auth.uid())
    );
create policy "self_write_wellness" on wellness_entries for all
    using (
        auth_is_admin()
        or athlete_id in (select id from athletes where user_id = auth.uid())
    )
    with check (
        auth_is_admin()
        or athlete_id in (select id from athletes where user_id = auth.uid())
    );

-- =====================================================================
-- grading
-- =====================================================================
alter table grading_sessions enable row level security;
create policy "all_read_grading_sessions" on grading_sessions for select using (auth.uid() is not null);
create policy "td_write_grading_sessions" on grading_sessions for all
    using (auth_is_admin() or auth_role() in ('technicalDirector','branchManager'))
    with check (auth_is_admin() or auth_role() in ('technicalDirector','branchManager'));

alter table grading_scores enable row level security;
create policy "all_read_grading_scores" on grading_scores for select using (auth.uid() is not null);
create policy "examiner_write_grading_scores" on grading_scores for all
    using (auth_is_admin() or examiner_id in (select id from coaches where user_id = auth.uid()))
    with check (auth_is_admin() or examiner_id in (select id from coaches where user_id = auth.uid()));

alter table grading_certificates enable row level security;
create policy "all_read_grading_certs" on grading_certificates for select using (auth.uid() is not null);
create policy "td_write_grading_certs" on grading_certificates for all
    using (auth_is_admin() or auth_role() in ('technicalDirector','branchManager'))
    with check (auth_is_admin() or auth_role() in ('technicalDirector','branchManager'));

-- =====================================================================
-- tournaments + brackets
-- =====================================================================
alter table tournaments enable row level security;
create policy "all_read_tournaments" on tournaments for select using (auth.uid() is not null);
create policy "td_write_tournaments" on tournaments for all
    using (auth_is_admin() or auth_role() = 'technicalDirector')
    with check (auth_is_admin() or auth_role() = 'technicalDirector');

alter table tournament_registrations enable row level security;
create policy "all_read_registrations" on tournament_registrations for select using (auth.uid() is not null);
create policy "td_write_registrations" on tournament_registrations for all
    using (auth_is_admin() or auth_role() in ('technicalDirector','branchManager','coach'))
    with check (auth_is_admin() or auth_role() in ('technicalDirector','branchManager','coach'));

alter table weight_cuts enable row level security;
create policy "all_read_weightcuts" on weight_cuts for select using (auth.uid() is not null);
create policy "coach_write_weightcuts" on weight_cuts for all
    using (auth_is_admin() or auth_role() in ('coach','branchManager','technicalDirector'))
    with check (auth_is_admin() or auth_role() in ('coach','branchManager','technicalDirector'));

alter table brackets enable row level security;
create policy "all_read_brackets" on brackets for select using (auth.uid() is not null);
create policy "td_write_brackets" on brackets for all
    using (auth_is_admin() or auth_role() = 'technicalDirector')
    with check (auth_is_admin() or auth_role() = 'technicalDirector');

alter table bracket_matches enable row level security;
create policy "all_read_bracket_matches" on bracket_matches for select using (auth.uid() is not null);
create policy "td_write_bracket_matches" on bracket_matches for all
    using (auth_is_admin() or auth_role() in ('technicalDirector','coach'))
    with check (auth_is_admin() or auth_role() in ('technicalDirector','coach'));

-- =====================================================================
-- announcements
-- =====================================================================
alter table announcements enable row level security;
create policy "all_read_announcements" on announcements for select using (auth.uid() is not null);
create policy "manager_write_announcements" on announcements for all
    using (auth_is_admin() or auth_role() in ('technicalDirector','branchManager'))
    with check (auth_is_admin() or auth_role() in ('technicalDirector','branchManager'));

alter table announcement_rsvps enable row level security;
create policy "self_rsvp_read" on announcement_rsvps for select
    using (user_id = auth.uid() or auth_can_read_all());
create policy "self_rsvp_write" on announcement_rsvps for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());

-- =====================================================================
-- certifications — coach reads own; admin writes
-- =====================================================================
alter table certifications enable row level security;
create policy "self_or_admin_read_certs" on certifications for select
    using (
        auth_is_admin()
        or auth_can_read_all()
        or coach_id in (select id from coaches where user_id = auth.uid())
    );
create policy "admin_write_certs" on certifications for all
    using (auth_is_admin()) with check (auth_is_admin());

-- =====================================================================
-- audit_log — append-only for everyone authenticated, read for admin+TD
-- =====================================================================
alter table audit_log enable row level security;
create policy "any_user_insert_audit" on audit_log for insert with check (auth.uid() = actor_user_id);
create policy "admin_td_read_audit" on audit_log for select using (auth_can_read_all());
