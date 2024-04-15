-- contains simple API to access storage-item

------------------------------------------------------------
-- sets a stored item
--
create function storage_set_item (
    sid_ text,
    key_ text,
    value_ jsonb,
    is_readonly_ boolean default null,
    is_override_readonly_ boolean default false
)
    returns int
    language sql
    set search_path from current
    volatile
as $$
    with
    upserted as (
        insert into storage_item as item
            ( sid, key, value, is_readonly )
            values
            ( sid_, key_, value_, coalesce(is_readonly_, false))
        on conflict (sid, key)
        do update set
            value = value_,
            is_readonly = coalesce(is_readonly_, item.is_readonly)
        where not item.is_readonly
            or is_override_readonly_
        returning *
    )
    select count(1) from upserted
$$;


------------------------------------------------------------
-- get a stored item
--
create function storage_get_item (
    sid_ text,
    key_ text
)
    returns jsonb
    language sql
    set search_path from current
    stable
as $$
    select value
    from storage_item
    where sid = sid_
    and key = key_
$$;

------------------------------------------------------------
-- removes a storage-item
--
create function storage_remove_item (
    sid_ text,
    key_ text
)
    returns int
    language sql
    set search_path from current
    volatile
as $$
    with
    deleted as (
        delete from storage_item
        where sid = sid_
        and key = key_
        and not is_readonly
        returning *
    )

    select count(1)
    from deleted
$$;

------------------------------------------------------------
-- returns array of keys of stored items
--
create function storage_keys(
    sid_ text
)
    returns text[]
    language sql
    set search_path from current
    volatile
as $$
    select array_agg(key)
    from storage_item
    where sid = sid_
$$;

------------------------------------------------------------
-- clears a stored session (ex: session-ended)
--
create function storage_clear(
    sid_ text
)
    returns int
    language sql
    set search_path from current
    volatile
as $$
    with
    deleted as (
        delete from storage_item
        where sid = sid_
        returning *
    )
    select count(1)
    from deleted
$$;



\if :{?test}
\if :test
    create function tests.test_storage()
        returns setof text
        language plpgsql
        set search_path from current
    as $$
    declare
        keys text[];
    begin
        perform storage_set_item('sid1', 'key1', '{"a":1}');
        perform storage_set_item('sid1', 'key2', '{"a":2}');

        return next ok(
            storage_keys('sid1')=array['key1', 'key2'],
            'able to set items');

        return next ok(
            storage_get_item('sid1', 'key1') = '{"a":1}',
            'able to get item');

        return next ok(storage_remove_item('sid1', 'key2') = 1, 'deleting item');
        return next ok(
            storage_keys('sid1')=array['key1'],
            'able to remove item');


        return next ok(storage_clear('sid1') = 1, 'clearing storage');
        return next ok( storage_keys('sid1') is null,
            'able to clear storage');
    end;
    $$;

    create function tests.test_storage_readonly()
        returns setof text
        language plpgsql
        set search_path from current
    as $$
    begin
        perform storage_set_item('sid1', 'key1', '{"a":1}',
            true); -- readonly
        return next ok(
            storage_get_item('sid1', 'key1') = '{"a":1}',
            'able to get item');

        return next ok(
            storage_remove_item('sid1', 'key1') = 0,
            'disallows removing readonly item');

        return next ok(
            storage_set_item('sid1', 'key1', '{"a":2}') = 0,
            'disallows re-setting readonly item');

        return next ok(
            storage_set_item('sid1', 'key1', '{"a":2}', is_override_readonly_ => true) = 1,
            'override  readonly item');

        return next ok(
            storage_get_item('sid1', 'key1') = '{"a":2}',
            'final value');

    end;
    $$;

\endif
\endif

