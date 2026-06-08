<?php
declare(strict_types=1);

function app_asset_download_response(string $assetKey): array {
    $asset = app_find_asset($assetKey);
    if (!$asset) app_json(['error' => 'asset_not_found'], 404);

    $priceTier = (string) $asset['price_tier'];
    if ($priceTier === 'premium') app_require_download_token();

    app_record_download(
        (string) $asset['asset_key'],
        (string) $asset['license'],
        $priceTier
    );

    return [
        'asset_key' => $asset['asset_key'],
        'title' => $asset['title'],
        'license' => $asset['license'],
        'price_tier' => $priceTier,
        'url' => app_asset_url($asset),
    ];
}

function app_find_asset(string $assetKey): ?array {
    $stmt = app_db()->prepare('SELECT * FROM assets WHERE asset_key = :asset_key');
    $stmt->execute([':asset_key' => $assetKey]);
    $row = $stmt->fetch();
    return is_array($row) ? $row : null;
}

function app_asset_url(array $asset): string {
    $public = $asset['public_url'] ?? null;
    if (is_string($public) && $public !== '') return $public;

    $base = rtrim(app_env('APP_PUBLIC_ASSET_BASE_URL', '') ?? '', '/');
    $key = ltrim((string) ($asset['r2_key'] ?? $asset['asset_key']), '/');
    if ($base === '') app_json(['error' => 'asset_base_url_missing'], 500);
    return $base . '/' . $key;
}

function app_require_download_token(): void {
    $expected = app_env('APP_DOWNLOAD_TOKEN');
    $actual = $_SERVER['HTTP_X_DOWNLOAD_TOKEN'] ?? '';
    if (!$expected || !is_string($actual) || !hash_equals($expected, $actual)) {
        app_json(['error' => 'download_not_authorized'], 403);
    }
}
