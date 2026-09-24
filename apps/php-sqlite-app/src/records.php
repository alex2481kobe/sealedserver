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

function app_admin_summary(): array {
    $rows = app_db()->query(
        'SELECT event_type, COUNT(*) AS total FROM events GROUP BY event_type ORDER BY total DESC'
    )->fetchAll();
    $summary = [];
    foreach ($rows as $row) $summary[(string) $row['event_type']] = (int) $row['total'];
    return $summary;
}

function app_admin_recent(): array {
    return app_db()->query('SELECT * FROM events ORDER BY created_at DESC LIMIT 20')->fetchAll();
}
