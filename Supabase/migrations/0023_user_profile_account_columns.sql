-- =====================================================================
-- 0023_user_profile_account_columns.sql
--
-- Closes the schema gap that caused profile-photo + account-edit saves to
-- silently fail in Supabase mode. The Swift `User` struct (Core/Models/
-- CoreEntities.swift) carries five fields that the original 0001_init
-- schema didn't have columns for. Every `client.from("user_profiles").
-- upsert(user)` call therefore returned PGRST204 ("Could not find the
-- 'avatar_url' column"), and AppSession.updateProfile swallowed the error
-- via `print("AppSession.updateProfile:", error)` — leaving the in-memory
-- currentUser unchanged and the new avatar invisible after dismiss.
--
-- This migration also creates the two storage buckets the repository
-- assumes exist (`userAvatars`, `athletePhotos`) plus permissive policies:
-- public read so AsyncImage can fetch via the returned getPublicURL,
-- authenticated write because the Swift code already controls the path
-- (UUID-based) and content type.
-- =====================================================================

-- 1. Account profile columns ------------------------------------------------

alter table user_profiles
    add column if not exists avatar_url text,
    add column if not exists email text,
    add column if not exists phone text,
    add column if not exists preferred_language text not null default 'system',
    add column if not exists notification_prefs jsonb not null default jsonb_build_object(
        'classReminders', true,
        'announcements', true,
        'weeklyDigest', false,
        'promotionAlerts', true
    ),
    add column if not exists linked_athlete_ids jsonb not null default '[]'::jsonb;

-- preferred_language is constrained to the PreferredLanguage enum cases.
do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'user_profiles_preferred_language_chk'
    ) then
        alter table user_profiles
            add constraint user_profiles_preferred_language_chk
            check (preferred_language in ('system', 'english', 'arabic'));
    end if;
end$$;

-- 2. Storage buckets --------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    ('userAvatars',  'userAvatars',  true, 5242880, array['image/jpeg','image/png','image/heic','image/webp']),
    ('athletePhotos','athletePhotos',true, 5242880, array['image/jpeg','image/png','image/heic','image/webp'])
on conflict (id) do update
    set public = excluded.public,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- 3. Storage policies -------------------------------------------------------
-- Drop-then-create so the migration is rerunnable.

drop policy if exists "public_read_profile_assets" on storage.objects;
create policy "public_read_profile_assets" on storage.objects
    for select to public
    using (bucket_id in ('userAvatars', 'athletePhotos'));

drop policy if exists "auth_upload_profile_assets" on storage.objects;
create policy "auth_upload_profile_assets" on storage.objects
    for insert to authenticated
    with check (bucket_id in ('userAvatars', 'athletePhotos'));

drop policy if exists "auth_update_profile_assets" on storage.objects;
create policy "auth_update_profile_assets" on storage.objects
    for update to authenticated
    using (bucket_id in ('userAvatars', 'athletePhotos'))
    with check (bucket_id in ('userAvatars', 'athletePhotos'));

drop policy if exists "auth_delete_profile_assets" on storage.objects;
create policy "auth_delete_profile_assets" on storage.objects
    for delete to authenticated
    using (bucket_id in ('userAvatars', 'athletePhotos'));
