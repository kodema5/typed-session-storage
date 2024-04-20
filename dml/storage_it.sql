------------------------------------------------------------
-- storage input type to get storage items
--
create type storage_it as (
    sid text,
    keys text[]
);

------------------------------------------------------------
-- new storage_it
--
create function storage_it(
    sid text,
    keys text[] default null
)
    returns storage_it
    language sql
    set search_path from current
    stable
as $$
    select (
        sid,
        keys
    )::storage_it
$$;

------------------------------------------------------------
-- override storage_it
--
create function storage_it(
    it storage_it,
    sid text default null,
    keys text[] default null
)
    returns storage_it
    language sql
    set search_path from current
    stable
as $$
    select (
        coalesce(sid, it.sid),
        coalesce(keys, it.keys)
    )::storage_it
$$;

------------------------------------------------------------
-- get storage items based on storage_it
--
create function storage_items (
    it storage_it
)
    returns setof storage_item
    language sql
    set search_path from current
    stable
as $$
    select *
    from  storage_item
    where sid = it.sid
    and (it.keys is null or key ~ any(it.keys))
$$;

------------------------------------------------------------
-- get storage-items jsonb
--
create function storage_get_item (
    it storage_it
)
    returns jsonb
    language sql
    set search_path from current
    stable
as $$
    select jsonb_object_agg (key, value)
    from storage_items(it)
$$;

