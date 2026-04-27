-- Row Level Security for SHJSDSC, matching the schema in supabase_migration.sql.
-- Identity model: user_profiles.id = auth.uid(). Coaches and athletes have no
-- direct auth column; linkage to a person is via user_profiles.role plus
-- user_profiles.linked_athlete_ids (jsonb uuid[]) for athlete/parent reads.

-- =====================================================================
-- Helper functions (security definer wrappers around user_profiles lookups)
-- =====================================================================

create or replace function auth_role() returns text language sql stable as $$
    select role from user_profiles where id = auth.uid();
$$;

create or replace function auth_branch() returns uuid language sql stable as $$
    select primary_branch_id from user_profiles where id = auth.uid();
$$;

create or replace function auth_linked_athletes() returns jsonb language sql stable as $$
    select coalesce(linked_athlete_ids, '[]'::jsonb) from user_profiles where id = auth.uid();
$$;

create or replace function auth_is_admin() returns bool language sql stable as $$
    select coalesce(auth_role() in ('admin','developer'), false);
$$;

create or replace function auth_can_read_all() returns bool language sql stable as $$
    select coalesce(auth_role() in ('admin','developer','technicalDirector','analyst'), false);
$$;

create or replace function auth_can_manage_branch(target_branch uuid) returns bool language sql stable as $$
    select auth_is_admin()
        or auth_role() = 'technicalDirector'
        or (auth_role() = 'branchManager' and auth_branch() = target_branch);
$$;

create or replace function auth_is_linked_to(athlete_id uuid) returns bool language sql stable as $$
    select auth_linked_athletes() ? athlete_id::text;
$$;

-- =====================================================================
-- user_profiles
-- =====================================================================
alter table user_profiles enable row level security;
create policy "self_read_profile" on user_profiles for select using (id = auth.uid() or auth_can_read_all());
create policy "self_update_profile" on user_profiles for update using (id = auth.uid() or auth_is_admin());
create policy "self_or_admin_insert_profile" on user_profiles for insert with check (id = auth.uid() or auth_is_admin());

-- =====================================================================
-- branches
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

-- =====================================================================
-- athletes — branch-scoped writes for managers/coaches; linked-only reads for athletes/parents
-- =====================================================================
alter table athletes enable row level security;

create policy "athletes_read_for_staff" on athletes for select
    using (auth_can_read_all() or auth_can_manage_branch(branch_id));

create policy "athletes_read_for_linked" on athletes for select
    using (auth_is_linked_to(id));

create policy "athletes_write_for_staff" on athletes for insert
    with check (auth_can_manage_branch(branch_id));

create policy "athletes_update_for_staff" on athletes for update
    using (auth_can_manage_branch(branch_id))
    with check (auth_can_manage_branch(branch_id));

create policy "athletes_delete_for_admin" on athletes for delete using (auth_is_admin());

-- =====================================================================
-- class_sessions
-- =====================================================================
alter table class_sessions enable row level security;
create policy "all_read_sessions" on class_sessions for select using (auth.uid() is not null);
create policy "branch_write_sessions" on class_sessions for all
    using (auth_can_manage_branch(branch_id))
    with check (auth_can_manage_branch(branch_id));

-- =====================================================================
-- attendance_records
-- =====================================================================
alter table attendance_records enable row level security;
create policy "staff_read_attendance" on attendance_records for select
    using (auth_can_read_all() or auth.uid() is not null);
create policy "staff_write_attendance" on attendance_records for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

-- =====================================================================
-- performance_scores, matches, score_events
-- =====================================================================
alter table performance_scores enable row level security;
create policy "all_read_perf" on performance_scores for select using (auth.uid() is not null);
create policy "admin_td_write_perf" on performance_scores for all
    using (auth_role() in ('admin','developer','technicalDirector'))
    with check (auth_role() in ('admin','developer','technicalDirector'));

alter table matches enable row level security;
create policy "all_read_matches" on matches for select using (auth.uid() is not null);
create policy "staff_write_matches" on matches for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table score_events enable row level security;
create policy "all_read_events" on score_events for select using (auth.uid() is not null);
create policy "staff_write_events" on score_events for all
    using (auth_role() in ('admin','developer','technicalDirector','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','coach'));

-- =====================================================================
-- physical_tests, technical_assessments, wellness_entries
-- =====================================================================
alter table physical_tests enable row level security;
create policy "staff_read_physical" on physical_tests for select using (auth.uid() is not null);
create policy "coach_write_physical" on physical_tests for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table technical_assessments enable row level security;
create policy "staff_read_technical" on technical_assessments for select using (auth.uid() is not null);
create policy "coach_write_technical" on technical_assessments for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table wellness_entries enable row level security;
create policy "wellness_read" on wellness_entries for select
    using (auth_can_read_all() or auth_is_linked_to(athlete_id));
create policy "wellness_write" on wellness_entries for all
    using (auth_is_admin() or auth_is_linked_to(athlete_id))
    with check (auth_is_admin() or auth_is_linked_to(athlete_id));

-- =====================================================================
-- grading
-- =====================================================================
alter table grading_sessions enable row level security;
create policy "all_read_grading_sessions" on grading_sessions for select using (auth.uid() is not null);
create policy "td_write_grading_sessions" on grading_sessions for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager'));

alter table grading_scores enable row level security;
create policy "all_read_grading_scores" on grading_scores for select using (auth.uid() is not null);
create policy "examiner_write_grading_scores" on grading_scores for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table grading_certificates enable row level security;
create policy "all_read_grading_certs" on grading_certificates for select using (auth.uid() is not null);
create policy "td_write_grading_certs" on grading_certificates for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager'));

-- =====================================================================
-- tournaments + brackets
-- =====================================================================
alter table tournaments enable row level security;
create policy "all_read_tournaments" on tournaments for select using (auth.uid() is not null);
create policy "td_write_tournaments" on tournaments for all
    using (auth_role() in ('admin','developer','technicalDirector'))
    with check (auth_role() in ('admin','developer','technicalDirector'));

alter table tournament_registrations enable row level security;
create policy "all_read_registrations" on tournament_registrations for select using (auth.uid() is not null);
create policy "staff_write_registrations" on tournament_registrations for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table weight_cuts enable row level security;
create policy "all_read_weightcuts" on weight_cuts for select using (auth.uid() is not null);
create policy "coach_write_weightcuts" on weight_cuts for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));

alter table brackets enable row level security;
create policy "all_read_brackets" on brackets for select using (auth.uid() is not null);
create policy "td_write_brackets" on brackets for all
    using (auth_role() in ('admin','developer','technicalDirector'))
    with check (auth_role() in ('admin','developer','technicalDirector'));

alter table bracket_matches enable row level security;
create policy "all_read_bracket_matches" on bracket_matches for select using (auth.uid() is not null);
create policy "td_write_bracket_matches" on bracket_matches for all
    using (auth_role() in ('admin','developer','technicalDirector','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','coach'));

-- =====================================================================
-- announcements
-- =====================================================================
alter table announcements enable row level security;
create policy "all_read_announcements" on announcements for select using (auth.uid() is not null);
create policy "manager_write_announcements" on announcements for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager'));

alter table announcement_rsvps enable row level security;
create policy "self_or_admin_read_rsvp" on announcement_rsvps for select
    using (user_id = auth.uid() or auth_can_read_all());
create policy "self_write_rsvp" on announcement_rsvps for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());

-- =====================================================================
-- certifications
-- =====================================================================
alter table certifications enable row level security;
create policy "staff_read_certs" on certifications for select
    using (auth_can_read_all() or auth.uid() is not null);
create policy "admin_write_certs" on certifications for all
    using (auth_is_admin()) with check (auth_is_admin());

-- =====================================================================
-- audit_log — append-only for any authenticated user; read for admin/TD/dev
-- =====================================================================
alter table audit_log enable row level security;
create policy "any_user_insert_audit" on audit_log for insert with check (auth.uid() = actor_user_id);
create policy "admin_td_read_audit" on audit_log for select using (auth_can_read_all());
