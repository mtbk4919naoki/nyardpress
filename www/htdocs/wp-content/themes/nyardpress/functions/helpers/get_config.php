<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Vite設定を取得（.envファイルから読み込む）
 *
 * @param string $key 環境変数のキー
 * @param mixed $default デフォルト値
 * @return array Vite設定の配列
 */
function get_config($key, $default = null) {
    if(function_exists('getenv')) {
        $value = getenv($key) ? getenv($key) : $default;
    } else {
        $value = defined($key) ? constant($key) : null;
    }
    return $value ?? $default;
}
