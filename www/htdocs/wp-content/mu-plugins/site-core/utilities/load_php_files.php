<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * ディレクトリ内のPHPファイルを読み込む（example-で始まるファイルは除外）
 *
 * @param string $dir ディレクトリパス
 */
function load_php_files($dir, $exclude_prefixes = ['example-']) {
    if (!is_dir($dir)) {
        return;
    }

    $files = glob($dir . '/*.php');
    foreach ($files as $file) {
        // 除外するファイルのプレフィックスをチェック
        $basename = basename($file);
        foreach ($exclude_prefixes as $prefix) {
            if (strpos($basename, $prefix) === 0) {
                continue;
            }
        }
        require_once $file;
    }
}
