-- Reset the athlete_member_number_seq so the first real athlete gets 1001.
-- Use is_called=false so the very next nextval() returns 1001 itself
-- (vs returning seq+1 the way is_called=true would).
--
-- Safe to run only when athletes table is empty — otherwise the next
-- insert would collide with an existing member_number and the unique
-- constraint would reject it. Guard with a check.

do $$
begin
    if (select count(*) from athletes) > 0 then
        raise exception 'Refusing to reset member number sequence: athletes table is not empty';
    end if;
    perform setval('athlete_member_number_seq', 1001, false);
end$$;
