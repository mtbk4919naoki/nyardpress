<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fieldsのオプションデータを取得する
 * ACF/SCFのオプションデータも取得可能
 * 更新時のキャッシュの削除は別途行うこと
 *
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
function use_option($key, $ttl = 86400 * 7) { // 7日
    return use_transient('option_' . $key, function() use ($key) {
        if (function_exists('carbon_get_theme_option')) {
            return carbon_get_theme_option($key) ?? get_option($key);
        } elseif (function_exists('get_field')) {
            return get_field($key, 'option') ?? get_option($key);
        } else {
            return get_option($key);
        }
    }, $ttl);
}
