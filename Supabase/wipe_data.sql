-- Truncate every data table in the public schema. Keeps the schema +
-- RLS policies + storage bucket intact so you can re-populate from scratch.
--
-- Run via:
--   supabase db query --linked --file Supabase/wipe_data.sql
--
-- Does NOT touch:
--   • auth.users          (users keep their accounts)
--   • storage.buckets     (athletePhotos bucket stays)
--   • Schema definitions  (tables, indexes, policies, helper functions)
--
-- DOES wipe:
--   • All 24 application tables
--   • All uploaded athlete photos in the athletePhotos bucket
--   • The user_profiles table — note this resets every user's role
--     (next sign-in lands them on RoleClaimView again)

truncate table
    audit_log,
    announcement_rsvps,
    announcements,
    certifications,
    bracket_matches,
    brackets,
    weight_cuts,
    tournament_registrations,
    tournaments,
    grading_certificates,
    grading_scores,
    grading_sessions,
    wellness_entries,
    technical_assessments,
    physical_tests,
    score_events,
    matches,
    performance_scores,
    attendance_records,
    class_sessions,
    athletes,
    coaches,
    branches,
    user_profiles
restart identity cascade;

-- Wipe uploaded photos (object rows; the bucket itself stays).
delete from storage.objects where bucket_id = 'athletePhotos';

-- Sanity check: every count below should be 0.
select 'athletes'             as table_name, count(*)::int as rows from athletes union all
select 'coaches',                            count(*)      from coaches union all
select 'branches',                           count(*)      from branches union all
select 'user_profiles',                      count(*)      from user_profiles union all
select 'matches',                            count(*)      from matches union all
select 'tournaments',                        count(*)      from tournaments union all
select 'announcements',                      count(*)      from announcements union all
select 'audit_log',                          count(*)      from audit_log union all
select 'storage.objects (athletePhotos)',    count(*)      from storage.objects where bucket_id = 'athletePhotos'
order by table_name;
