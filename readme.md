# typed session-storage

session-storage cache are key and json-value pairs. ex: user-profile,
current-worksheet, etc. is there a way to wrap them as a user-data-type for a
better developer's experience? a cannonical,

    s storage_t = storage_t(storage_it(
        session_id,                          -- session-id
        array['user_profile', 'permissions'] -- list of keys of interests
    ));
    ...
    ...
    call set(s); -- update storage-items
    ...
    return jsonb_build_object(
        'greeting', greeting(s.user_profile) -- pass to function
    );

approach: a base `storage_t` type. `alter type` is used to extend a base
`storage_t`, then collected storage-items are casted to `storage_t`. for
maintenance `storage_t_remove (keys)` to dynamically remove attributes.

`ddl.sql` contains storage-item table definition

`dml.sql` contains storage-api to access modify storage-item, and storage_t that
wraps storage-item as a type.
