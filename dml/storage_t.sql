--

------------------------------------------------------------
-- base storage_t
--
create type storage_t as (
    sid text
);

-- storage_t attributes/keys can be extended/removed on app need
--
\ir storage_t_keys.sql

------------------------------------------------------------
-- get selected storage-items as storage_t
--

\ir storage_it.sql

------------------------------------------------------------
-- returns storage_t from storage-items
--
create function storage_t (
    it_ storage_it
)
    returns storage_t
    language sql
    set search_path from current
    stable
as $$
    select jsonb_populate_record(
        null::storage_t,
        jsonb_build_object('sid', it_.sid)
        || storage_get_item(it_)
    )
$$;

\if :{?test}
\if :test
    create function tests.test_storage_t_extending()
        returns setof text
        language plpgsql
        set search_path from current
    as $$
    begin
        perform storage_set_item('sid1', 'foo', '"1"');
        return next ok(
            to_jsonb(storage_t(storage_it('sid1'))) = '{"sid":"sid1"}',
            'able to create storage_t');

        alter type storage_t add attribute foo numeric;
        return next ok(
            to_jsonb(storage_t(storage_it('sid1'))) = '{"sid":"sid1", "foo":1}',
            'able to extend storage_t');

        call storage_t_remove(array['foo']);
        return next ok(
            to_jsonb(storage_t(storage_it('sid1'))) = '{"sid":"sid1"}',
            'able to reduce storage_t');
    end;
    $$;

\endif
\endif


------------------------------------------------------------
-- set/persists storage_t to storage-items
--
create function set(
    it_ storage_t,
    is_override_readonly_ boolean default false,
    is_strip_nulls_ boolean default true
)
    returns int
    language sql
    set search_path from current
    volatile
as $$
    select count(storage_set_item(
        it_.sid,
        kv.key,
        kv.value,
        is_override_readonly_ => set.is_override_readonly_
    ))
    from jsonb_each(
        case
        when is_strip_nulls_ then jsonb_strip_nulls(to_jsonb(it_))
        else to_jsonb(it_)
        end
    ) kv
    where kv.key <> 'sid'
$$;


\if :{?test}
\if :test
    create function tests.test_storage_t_set()
        returns setof text
        language plpgsql
        set search_path from current
    as $$
    declare
        s storage_t;
    begin
        perform storage_clear('sid1');
        alter type storage_t add attribute foo numeric;
        alter type storage_t add attribute bar numeric;

        s.sid = 'sid1';
        perform set(s);
        return next ok(
            to_jsonb(storage_t(storage_it('sid1'))) is null,
            'empty storage-id');

        s.foo = 1;
        perform set(s);
        return next ok(
            to_jsonb(storage_t(storage_it('sid1'))) = '{"sid":"sid1", "foo":1, "bar":null}',
            'able to get storage_t');


        perform storage_set_item('sid1', 'bar', '2', true);

        return next ok(
            (storage_t(storage_it('sid1'))).bar = 2,
            'initial value of readonly bar = 2');

        s.bar = 3;
        perform set(s);
        return next ok(
            (storage_t(storage_it('sid1'))).bar = 2,
            'initial bar is still 2');

        perform set(s, is_override_readonly_=>true);
        return next ok(
            (storage_t(storage_it('sid1'))).bar = 3,
            'able to override readeonly');


        call storage_t_remove(array['foo', 'bar']);
        perform storage_clear('sid1');
    end;
    $$;

\endif
\endif
