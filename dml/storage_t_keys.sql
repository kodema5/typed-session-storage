------------------------------------------------------------
-- returns the attributes/keys
--
create function storage_t_keys()
    returns text[]
    language sql
    set search_path from current
    stable
as $$
    select array_agg(attname)
    from pg_attribute
    where attrelid::regclass = (current_schema() || '.storage_t')::regclass
    and atttypid <> 0
$$;


------------------------------------------------------------
-- drop of attribute cascade will drop storage_t also
-- below is to dynamically remove the item
--
create procedure storage_t_remove(
    keys text[]
)
    language plpgsql
    set search_path from current
as $$
declare
    t text;
begin
    foreach t in array keys
    loop
        execute format('
            alter type %s.storage_t
            drop attribute if exists %I restrict
        ', current_schema(), t);
    end loop;
end;
$$;


\if :{?test}
\if :test
    create function tests.test_storage_t_attributes()
        returns setof text
        language plpgsql
        set search_path from current
    as $$
    declare
        keys text[];
    begin
        alter type storage_t add attribute test_n numeric;
        return next ok(
            'test_n' = any(storage_t_keys()),
            'able to create test_n');

        call storage_t_remove(array['test_n']);
        return next ok(
            'test_n' <> any(storage_t_keys()),
            'able to remove test_n');
    end;
    $$;

\endif
\endif
