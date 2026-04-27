-- Permanent uniqueness for athletes.member_number.
--
-- Before: nextMemberNumber() returned max(member_number) + 1, which would
-- silently reissue a freed number after an athlete was deleted.
--
-- After: a sequence advances monotonically. Even if an athlete row is
-- deleted, the sequence has already moved past their number — so it
-- never gets handed out to a new athlete. Pair this with the existing
-- UNIQUE constraint and the result is true lifetime uniqueness.

do $$
declare seed_start int;
begin
    select coalesce(max(member_number), 1000) + 1 into seed_start from athletes;
    if not exists (select 1 from pg_class where relkind = 'S' and relname = 'athlete_member_number_seq') then
        execute format(
            'create sequence athlete_member_number_seq start with %s increment 1 minvalue 1001 maxvalue 1999',
            seed_start
        );
    end if;
end$$;

alter table athletes alter column member_number set default nextval('athlete_member_number_seq');
alter sequence athlete_member_number_seq owned by athletes.member_number;

-- RPC for the iOS client to read the next available number before inserting
-- (so the form can preview what's about to be assigned). security definer
-- because we want any authenticated user with insert rights on athletes to
-- be able to peek the sequence; explicit grant below limits it.
create or replace function next_member_number() returns int
    language sql security definer set search_path = public
    as $$ select nextval('athlete_member_number_seq')::int $$;

revoke all on function next_member_number() from public;
grant execute on function next_member_number() to authenticated;
