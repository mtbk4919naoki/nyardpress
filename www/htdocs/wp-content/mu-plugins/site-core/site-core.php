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

/**
 * ディレクトリ内のPHPファイルを読み込む（example-で始まるファイルは除外）
 * 
 * @param string $dir ディレクトリパス
 */
function load_php_files($dir) {
    if (!is_dir($dir)) {
        return;
    }
    
    $files = glob($dir . '/*.php');
    foreach ($files as $file) {
        // example-で始まるファイルは除外
        $basename = basename($file);
        if (strpos($basename, 'example-') === 0) {
            continue;
        }
        require_once $file;
    }
}

// カスタム投稿タイプを読み込む
load_php_files(__DIR__ . '/posttypes');

// カスタムタクソノミーを読み込む
load_php_files(__DIR__ . '/taxonomies');

// カスタムフィールドを読み込む
load_php_files(__DIR__ . '/fields');

// ユーティリティ関数を読み込む
load_php_files(__DIR__ . '/utilities');

