-- +goose Up
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT projects_name_not_empty
        CHECK (LENGTH(BTRIM(name)) > 0)
);

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES projects(id)
        ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    prefix VARCHAR(16) NOT NULL,
    key_hash BYTEA NOT NULL,

    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT api_keys_name_not_empty
        CHECK (LENGTH(BTRIM(name)) > 0),

    CONSTRAINT api_keys_prefix_valid
        CHECK (
            prefix = BTRIM(prefix)
            AND LENGTH(prefix) BETWEEN 8 AND 16
        ),

    CONSTRAINT api_keys_hash_length
        CHECK (OCTET_LENGTH(key_hash) = 32),

    CONSTRAINT api_keys_prefix_unique
        UNIQUE (prefix),

    CONSTRAINT api_keys_hash_unique
        UNIQUE (key_hash)
);

CREATE INDEX api_keys_project_id_idx
    ON api_keys (project_id);


-- +goose Down
DROP TABLE api_keys;
DROP TABLE projects;
