<?php
declare(strict_types=1);

require __DIR__ . '/../src/bootstrap.php';
require __DIR__ . '/../src/records.php';

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

app_json_headers();

try {
    if ($path === '/api/healthz' && $method === 'GET') {
        app_json(['ok' => true, 'service' => app_env('APP_NAME', 'php-sqlite-app')]);
    }

    if ($path === '/api/events' && $method === 'POST') {
        $body = app_json_input();
        app_record_event(
            app_string($body['event_type'] ?? 'event', 64),
            app_optional_string($body['subject'] ?? null, 128),
            is_array($body['metadata'] ?? null) ? $body['metadata'] : []
        );
        app_json(['ok' => true], 201);
    }

    if ($path === '/api/admin/summary' && $method === 'GET') {
        app_require_admin();
        app_json(app_admin_summary());
    }

    if ($path === '/api/admin/recent' && $method === 'GET') {
        app_require_admin();
        app_json(app_admin_recent());
    }

    app_json(['error' => 'not_found'], 404);
} catch (Throwable $e) {
    error_log((string) $e);
    app_json(['error' => 'server_error'], 500);
}
