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

// ユーティリティ関数を読み込む
require_once __DIR__ . '/utilities/load_php_files.php';

// ユーティリティ関数を読み込む
load_php_files(__DIR__ . '/utilities');

// カスタム投稿タイプを読み込む
load_php_files(__DIR__ . '/posttypes');

// カスタムタクソノミーを読み込む
load_php_files(__DIR__ . '/taxonomies');

// カスタムフィールドを読み込む
load_php_files(__DIR__ . '/fields');

