<?php
declare(strict_types=1);

require __DIR__ . '/../src/bootstrap.php';

app_apply_schema(app_db());
echo "SQLite schema applied to " . app_db_path() . PHP_EOL;
