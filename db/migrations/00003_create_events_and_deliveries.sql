-- +goose Up
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL
        REFERENCES projects(id)
        ON DELETE CASCADE,

    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    idempotency_key VARCHAR(255) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT events_event_type_not_empty
        CHECK (LENGTH(BTRIM(event_type)) > 0),

    CONSTRAINT events_idempotency_key_not_empty
        CHECK (LENGTH(BTRIM(idempotency_key)) > 0),

    CONSTRAINT events_payload_is_object
        CHECK (JSONB_TYPEOF(payload) = 'object'),

    CONSTRAINT events_project_idempotency_key_unique
        UNIQUE (project_id, idempotency_key)
);

CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    event_id UUID NOT NULL
        REFERENCES events(id)
        ON DELETE CASCADE,

    endpoint_id UUID NOT NULL
        REFERENCES endpoints(id)
        ON DELETE CASCADE,

    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    delivered_at TIMESTAMPTZ,
    last_error TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT deliveries_status_valid
        CHECK (
            status IN (
                'pending',
                'processing',
                'succeeded',
                'failed'
            )
        ),

    CONSTRAINT deliveries_attempt_count_non_negative
        CHECK (attempt_count >= 0),

    CONSTRAINT deliveries_event_endpoint_unique
        UNIQUE (event_id, endpoint_id)
);

CREATE TABLE delivery_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    delivery_id UUID NOT NULL
        REFERENCES deliveries(id)
        ON DELETE CASCADE,

    attempt_number INTEGER NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,

    duration_ms INTEGER,
    response_status SMALLINT,
    response_body TEXT,
    error_message TEXT,

    succeeded BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT delivery_attempts_number_positive
        CHECK (attempt_number > 0),

    CONSTRAINT delivery_attempts_duration_non_negative
        CHECK (duration_ms IS NULL OR duration_ms >= 0),

    CONSTRAINT delivery_attempts_response_status_valid
        CHECK (
            response_status IS NULL
            OR response_status BETWEEN 100 AND 599
        ),

    CONSTRAINT delivery_attempts_completion_valid
        CHECK (
            completed_at IS NULL
            OR completed_at >= started_at
        ),

    CONSTRAINT delivery_attempts_delivery_number_unique
        UNIQUE (delivery_id, attempt_number)
);	

-- +goose Down
DROP TABLE delivery_attempts;
DROP TABLE deliveries;
DROP TABLE events;
