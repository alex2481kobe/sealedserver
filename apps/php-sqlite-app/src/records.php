<?php
declare(strict_types=1);

function app_record_event(string $eventType, ?string $subject, array $metadata): void {
    $stmt = app_db()->prepare(
        'INSERT INTO events (event_type, subject, metadata_json, ip_hash, user_agent, created_at)
         VALUES (:event_type, :subject, :metadata_json, :ip_hash, :user_agent, :created_at)'
    );
    $stmt->execute([
        ':event_type' => $eventType,
        ':subject' => $subject,
        ':metadata_json' => json_encode($metadata, JSON_UNESCAPED_SLASHES) ?: '{}',
        ':ip_hash' => app_client_ip_hash(),
        ':user_agent' => app_user_agent(),
        ':created_at' => time(),
    ]);
}

function app_record_download(string $assetKey, ?string $license, ?string $source): void {
    $stmt = app_db()->prepare(
        'INSERT INTO downloads (asset_key, license, source, ip_hash, user_agent, created_at)
         VALUES (:asset_key, :license, :source, :ip_hash, :user_agent, :created_at)'
    );
    $stmt->execute([
        ':asset_key' => $assetKey,
        ':license' => $license,
        ':source' => $source,
        ':ip_hash' => app_client_ip_hash(),
        ':user_agent' => app_user_agent(),
        ':created_at' => time(),
    ]);
}

function app_admin_summary(): array {
    $db = app_db();
    return [
        'events' => (int) $db->query('SELECT COUNT(*) FROM events')->fetchColumn(),
        'downloads' => (int) $db->query('SELECT COUNT(*) FROM downloads')->fetchColumn(),
        'assets' => (int) $db->query('SELECT COUNT(*) FROM assets')->fetchColumn(),
        'webhooks' => (int) $db->query('SELECT COUNT(*) FROM webhook_events')->fetchColumn(),
        'orders' => (int) $db->query('SELECT COUNT(*) FROM commerce_orders')->fetchColumn(),
    ];
}

function app_admin_recent(): array {
    $db = app_db();
    return [
        'events' => app_fetch_recent($db, 'events', 'created_at'),
        'downloads' => app_fetch_recent($db, 'downloads', 'created_at'),
        'orders' => app_fetch_recent($db, 'commerce_orders', 'created_at'),
        'webhooks' => app_fetch_recent($db, 'webhook_events', 'handled_at'),
    ];
}

function app_fetch_recent(PDO $db, string $table, string $timeColumn): array {
    $allowed = [
        'events' => 'created_at',
        'downloads' => 'created_at',
        'commerce_orders' => 'created_at',
        'webhook_events' => 'handled_at',
    ];
    if (($allowed[$table] ?? null) !== $timeColumn) return [];
    return $db->query("SELECT * FROM $table ORDER BY $timeColumn DESC LIMIT 20")->fetchAll();
}
