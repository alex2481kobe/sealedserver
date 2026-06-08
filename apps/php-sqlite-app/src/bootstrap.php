<?php
declare(strict_types=1);

date_default_timezone_set('UTC');

function app_env(string $key, ?string $default = null): ?string {
    $value = getenv($key);
    return is_string($value) && $value !== '' ? $value : $default;
}

function app_db_path(): string {
    return app_env('APP_DB_PATH', __DIR__ . '/../var/app.sqlite') ?? __DIR__ . '/../var/app.sqlite';
}

function app_db(): PDO {
    static $pdo = null;
    if ($pdo instanceof PDO) return $pdo;

    $path = app_db_path();
    $dir = dirname($path);
    if (!is_dir($dir)) mkdir($dir, 0770, true);

    $pdo = new PDO('sqlite:' . $path, null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $pdo->exec('PRAGMA journal_mode = WAL');
    $pdo->exec('PRAGMA synchronous = NORMAL');
    $pdo->exec('PRAGMA foreign_keys = ON');
    $pdo->exec('PRAGMA busy_timeout = 5000');
    app_apply_schema($pdo);
    return $pdo;
}

function app_apply_schema(PDO $pdo): void {
    $schema = file_get_contents(__DIR__ . '/../db/schema.sql');
    if ($schema === false) throw new RuntimeException('missing schema.sql');
    $pdo->exec($schema);
    app_migrate($pdo);
}

function app_migrate(PDO $pdo): void {
    if (!app_column_exists($pdo, 'webhook_events', 'event_name')) {
        $pdo->exec('ALTER TABLE webhook_events ADD COLUMN event_name TEXT');
    }
}

function app_column_exists(PDO $pdo, string $table, string $column): bool {
    $stmt = $pdo->query("PRAGMA table_info($table)");
    foreach ($stmt->fetchAll() as $row) {
        if (($row['name'] ?? '') === $column) return true;
    }
    return false;
}

function app_json_headers(): void {
    header('Content-Type: application/json; charset=utf-8');
    header('X-Content-Type-Options: nosniff');
}

function app_json(array $value, int $status = 200): never {
    http_response_code($status);
    echo json_encode($value, JSON_UNESCAPED_SLASHES);
    exit;
}

function app_json_input(): array {
    $raw = file_get_contents('php://input') ?: '';
    $max = (int) (app_env('APP_MAX_BODY_BYTES', '65536') ?? '65536');
    if (strlen($raw) > $max) app_json(['error' => 'payload_too_large'], 413);
    if ($raw === '') return [];
    $data = json_decode($raw, true);
    if (!is_array($data)) app_json(['error' => 'bad_json'], 400);
    return $data;
}

function app_string(mixed $value, int $max): string {
    if (!is_string($value) || trim($value) === '') app_json(['error' => 'bad_input'], 400);
    return substr(trim($value), 0, $max);
}

function app_optional_string(mixed $value, int $max): ?string {
    if ($value === null || $value === '') return null;
    if (!is_string($value)) app_json(['error' => 'bad_input'], 400);
    return substr(trim($value), 0, $max);
}

function app_client_ip_hash(): ?string {
    $ip = $_SERVER['HTTP_CF_CONNECTING_IP'] ?? $_SERVER['REMOTE_ADDR'] ?? null;
    return is_string($ip) ? hash('sha256', $ip) : null;
}

function app_user_agent(): ?string {
    $ua = $_SERVER['HTTP_USER_AGENT'] ?? null;
    return is_string($ua) ? substr($ua, 0, 255) : null;
}

function app_require_admin(): void {
    $expected = app_env('APP_ADMIN_TOKEN');
    $actual = $_SERVER['HTTP_X_ADMIN_TOKEN'] ?? '';
    if (!$expected || !is_string($actual) || !hash_equals($expected, $actual)) {
        app_json(['error' => 'unauthorized'], 401);
    }
}
