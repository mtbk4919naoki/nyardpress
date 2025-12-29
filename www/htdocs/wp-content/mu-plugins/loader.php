<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// site-coreディレクトリ内のsite-core.phpを読み込む
$site_core_file = __DIR__ . '/site-core/site-core.php';
if (file_exists($site_core_file)) {
    require_once $site_core_file;
}

