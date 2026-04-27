-- Extend athletes with the full profile schema (identity / family / medical /
-- technical). All new columns are optional or have safe defaults so existing
-- rows survive without migration data.

alter table athletes
    add column if not exists passport_number text,
    add column if not exists blood_type text,
    add column if not exists federation_licence_number text,
    add column if not exists parent_user_ids jsonb not null default '[]'::jsonb,
    add column if not exists emergency_contacts jsonb not null default '[]'::jsonb,
    add column if not exists school text,
    add column if not exists image_rights_consent bool not null default false,
    add column if not exists image_rights_consent_date timestamptz,
    add column if not exists travel_permission bool not null default false,
    add column if not exists travel_permission_date timestamptz,
    add column if not exists height_cm numeric,
    add column if not exists weight_history jsonb not null default '[]'::jsonb,
    add column if not exists allergies jsonb not null default '[]'::jsonb,
    add column if not exists medical_conditions jsonb not null default '[]'::jsonb,
    add column if not exists medications jsonb not null default '[]'::jsonb,
    add column if not exists fit_to_train bool not null default true,
    add column if not exists injuries jsonb not null default '[]'::jsonb,
    add column if not exists weight_class text,
    add column if not exists dominant_stance text,
    add column if not exists poomsae_syllabus text,
    add column if not exists kyorugi_tier text,
    add column if not exists training_group_id uuid;

create index if not exists athletes_fit_idx on athletes (fit_to_train);
create index if not exists athletes_kyorugi_tier_idx on athletes (kyorugi_tier);
