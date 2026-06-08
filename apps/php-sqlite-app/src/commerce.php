<?php
declare(strict_types=1);

function app_raw_input(): string {
    return file_get_contents('php://input') ?: '';
}

function app_verify_hmac_sha256(string $raw, string $signature, string $secret): bool {
    if ($signature === '' || $secret === '') return false;
    $expected = hash_hmac('sha256', $raw, $secret);
    return hash_equals($expected, $signature);
}

function app_handle_lemon_webhook(string $raw): array {
    $secret = app_env('LEMON_SQUEEZY_WEBHOOK_SECRET', '') ?? '';
    $signature = $_SERVER['HTTP_X_SIGNATURE'] ?? '';
    if (!is_string($signature) || !app_verify_hmac_sha256($raw, $signature, $secret)) {
        app_json(['error' => 'invalid_signature'], 401);
    }

    $payload = json_decode($raw, true);
    if (!is_array($payload)) app_json(['error' => 'bad_json'], 400);

    $eventName = app_lemon_event_name($payload);
    $eventId = app_lemon_event_id($payload, $eventName);
    app_store_webhook_event('lemon-squeezy', $eventId, $eventName, $raw);

    if (str_starts_with($eventName, 'order_')) {
        app_store_lemon_order($payload, $eventName, $raw);
    }

    return ['ok' => true, 'event' => $eventName];
}

function app_lemon_event_name(array $payload): string {
    $meta = $payload['meta'] ?? [];
    $event = is_array($meta) ? ($meta['event_name'] ?? null) : null;
    if (is_string($event) && $event !== '') return $event;
    $header = $_SERVER['HTTP_X_EVENT_NAME'] ?? null;
    return is_string($header) && $header !== '' ? $header : 'unknown';
}

function app_lemon_event_id(array $payload, string $eventName): string {
    $data = $payload['data'] ?? [];
    $id = is_array($data) ? ($data['id'] ?? null) : null;
    $base = is_string($id) && $id !== '' ? $id : hash('sha256', json_encode($payload) ?: '');
    return $eventName . ':' . $base;
}

function app_store_webhook_event(string $provider, string $eventId, string $eventName, string $raw): void {
    $stmt = app_db()->prepare(
        'INSERT OR IGNORE INTO webhook_events
         (provider, provider_event_id, event_name, payload_json, handled_at)
         VALUES (:provider, :event_id, :event_name, :payload_json, :handled_at)'
    );
    $stmt->execute([
        ':provider' => $provider,
        ':event_id' => $eventId,
        ':event_name' => $eventName,
        ':payload_json' => $raw,
        ':handled_at' => time(),
    ]);
}

function app_store_lemon_order(array $payload, string $eventName, string $raw): void {
    $data = $payload['data'] ?? [];
    $attrs = is_array($data) ? ($data['attributes'] ?? []) : [];
    $orderId = is_array($data) && isset($data['id']) ? (string) $data['id'] : hash('sha256', $raw);
    $status = is_array($attrs) && isset($attrs['status']) ? (string) $attrs['status'] : $eventName;
    $email = is_array($attrs) && isset($attrs['user_email']) ? (string) $attrs['user_email'] : null;

    $stmt = app_db()->prepare(
        'INSERT OR IGNORE INTO commerce_orders
         (provider, provider_order_id, event_name, status, email_hash, payload_json, created_at)
         VALUES (:provider, :order_id, :event_name, :status, :email_hash, :payload_json, :created_at)'
    );
    $stmt->execute([
        ':provider' => 'lemon-squeezy',
        ':order_id' => $orderId,
        ':event_name' => $eventName,
        ':status' => $status,
        ':email_hash' => $email ? hash('sha256', strtolower(trim($email))) : null,
        ':payload_json' => $raw,
        ':created_at' => time(),
    ]);
}
