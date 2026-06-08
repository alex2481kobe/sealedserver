CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    subject TEXT,
    metadata_json TEXT NOT NULL DEFAULT '{}',
    ip_hash TEXT,
    user_agent TEXT,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_events_type_time ON events (event_type, created_at DESC);

CREATE TABLE IF NOT EXISTS downloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    asset_key TEXT NOT NULL,
    license TEXT,
    source TEXT,
    ip_hash TEXT,
    user_agent TEXT,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_downloads_asset_time ON downloads (asset_key, created_at DESC);

CREATE TABLE IF NOT EXISTS assets (
    asset_key TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    license TEXT NOT NULL,
    price_tier TEXT NOT NULL CHECK (price_tier IN ('free','premium')),
    public_url TEXT,
    r2_key TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS webhook_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL,
    provider_event_id TEXT NOT NULL,
    event_name TEXT,
    payload_json TEXT NOT NULL,
    handled_at INTEGER NOT NULL,
    UNIQUE (provider, provider_event_id)
);

CREATE TABLE IF NOT EXISTS commerce_orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL,
    provider_order_id TEXT NOT NULL,
    event_name TEXT NOT NULL,
    status TEXT NOT NULL,
    email_hash TEXT,
    payload_json TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    UNIQUE (provider, provider_order_id, event_name)
);
