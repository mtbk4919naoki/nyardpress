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

    // オプション更新時にキャッシュを削除
    // WordPress標準のオプション更新フック（Carbon Fieldsは通常このフックで動作）
    add_action('updated_option', function ($option_name, $old_value, $value) {
        delete_transient('option_' . $option_name);
    }, 10, 3);

    // ACFのオプションフィールド更新時にキャッシュを削除
    // ACFは独自の保存メカニズムを使用するため、acf/update_valueフックが必要
    if (function_exists('get_field')) {
        add_filter('acf/update_value', function ($value, $post_id, $field) {
            // オプションページの場合のみキャッシュを削除
            if ($post_id === 'option' || strpos($post_id, 'options') === 0) {
                $field_name = is_array($field) ? (isset($field['name']) ? $field['name'] : '') : $field;
                if ($field_name) {
                    delete_transient('option_' . $field_name);
                }
            }
            return $value;
        }, 10, 3);
    }

    // オプション削除時にキャッシュを削除
    add_action('delete_option', function ($option_name) {
        delete_transient('option_' . $option_name);
    }, 10, 1);
}
