-- +goose Up
CREATE TABLE endpoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL
        REFERENCES projects(id)
        ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    url VARCHAR(2048) NOT NULL,
    secret_ciphertext BYTEA NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT endpoints_name_not_empty
        CHECK (LENGTH(BTRIM(name)) > 0),

    CONSTRAINT endpoints_url_not_empty
        CHECK (LENGTH(BTRIM(url)) > 0),

    CONSTRAINT endpoints_secret_not_empty
        CHECK (OCTET_LENGTH(secret_ciphertext) > 0),

    CONSTRAINT endpoints_project_url_unique
        UNIQUE (project_id, url)
);

CREATE TABLE endpoint_subscriptions (
    endpoint_id UUID NOT NULL
        REFERENCES endpoints(id)
        ON DELETE CASCADE,

    event_type VARCHAR(100) NOT NULL,

    CONSTRAINT endpoint_subscriptions_event_type_not_empty
        CHECK (LENGTH(BTRIM(event_type)) > 0),

    PRIMARY KEY (endpoint_id, event_type)
);


-- +goose Down
DROP TABLE endpoint_subscriptions;
DROP TABLE endpoints;
