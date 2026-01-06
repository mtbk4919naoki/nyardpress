<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fields/ACF/SCFのオプションデータを取得する
 *
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
if (!function_exists('use_option')) {
    function use_option($key, $ttl = 86400 * 7) { // 7日
        return use_transient('option_' . $key, function() use ($key) {
            $option = null;
            if (function_exists('carbon_get_theme_option')) {
                $option = carbon_get_theme_option($key);
            }
            if (function_exists('get_field') && !isset($option)) {
                $option = get_field($key, 'option');
            }
            return $option ?? get_option($key);
        }, $ttl);
    }
}

// オプション更新時にキャッシュを削除
add_action('updated_option', function ($option_name, $old_value, $value) {
	delete_transient('option_' . $option_name);
}, 10, 3);

// オプション削除時にキャッシュを削除
add_action('delete_option', function ($option_name) {
	delete_transient('option_' . $option_name);
}, 10, 1);
