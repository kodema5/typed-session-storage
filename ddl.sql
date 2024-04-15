create table if not exists storage_item (
    sid text not null,
    key text not null,
    primary key (sid, key),

    value jsonb,

    is_readonly boolean
        default false
);
