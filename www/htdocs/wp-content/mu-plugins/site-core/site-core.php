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

// Composerのオートローダーを読み込む
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
}

// Carbon Fieldsの初期化
require_once __DIR__ . '/bootstrap/carbon-fields.php';

// Mail: Mailpit設定（開発環境用）
require_once __DIR__ . '/mail/mailpit.php';

// ユーティリティ関数を読み込む（優先読み込み）
require_once __DIR__ . '/utilities/load_php_files.php';
require_once __DIR__ . '/utilities/use_transient.php';

// ユーティリティ関数を読み込む
load_php_files(__DIR__ . '/utilities');

// ブロック管理
require_once __DIR__ . '/blocks/blocks.php';

add_action('carbon_fields_register_fields', function () {
    // カスタム投稿タイプを読み込む
    load_php_files(__DIR__ . '/posttypes');

    // カスタムタクソノミーを読み込む
    load_php_files(__DIR__ . '/taxonomies');

    // カスタムフィールドを読み込む
    load_php_files(__DIR__ . '/fields');
});
