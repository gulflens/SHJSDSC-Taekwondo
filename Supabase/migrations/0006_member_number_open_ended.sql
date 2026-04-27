-- Remove the upper bound on athletes.member_number. The original 1001-1999
-- range gave only 999 lifetime slots which is too tight for any club that
-- expects to keep operating for years (especially with the no-reuse policy
-- — every cancelled signup eats one slot forever).
--
-- After this:
--   • Sequence has no maxvalue (bigint max ≈ 9.2 × 10^18 — effectively
--     infinite for any human-scale sports club)
--   • Check constraint enforces only the lower bound (>= 1001)
--   • Existing rows are unaffected; the unique constraint and lifetime
--     uniqueness guarantee from migration 0005 stay in place

alter sequence athlete_member_number_seq no maxvalue;
alter table athletes drop constraint if exists athletes_member_number_check;
alter table athletes add constraint athletes_member_number_check check (member_number >= 1001);
