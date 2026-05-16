-- Extend branches with the full profile schema (contact / location / branding).
-- All new columns are optional or have safe defaults so existing rows survive
-- without migration data.

alter table branches
    add column if not exists street_address text not null default '',
    add column if not exists street_address_ar text not null default '',
    add column if not exists emirate text not null default 'Sharjah',
    add column if not exists country text not null default 'AE',
    add column if not exists po_box text,
    add column if not exists latitude numeric not null default 0,
    add column if not exists longitude numeric not null default 0,
    add column if not exists google_place_id text,
    add column if not exists phone text not null default '',
    add column if not exists whatsapp_business text,
    add column if not exists email text not null default '',
    add column if not exists founded_at timestamptz not null default now(),
    add column if not exists is_active bool not null default true,
    add column if not exists brand_hex_color text,
    add column if not exists tagline_en text,
    add column if not exists tagline_ar text;
