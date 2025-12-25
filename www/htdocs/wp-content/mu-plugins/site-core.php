<?php
/**
 * Plugin Name: Site Core
 * Description: カスタム投稿タイプ、カスタムタクソノミー、Carbon Fieldsを管理するMUプラグイン
 * Version: 1.0.0
 * Author: Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// site-coreディレクトリ内のsite-core.phpを読み込む
$site_core_file = __DIR__ . '/site-core/site-core.php';
if (file_exists($site_core_file)) {
    require_once $site_core_file;
}

