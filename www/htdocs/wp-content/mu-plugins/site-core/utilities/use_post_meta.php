<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fields/ACF/SCFのメタデータを取得する
 *
 * @param int $post_id 投稿ID
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
if (!function_exists('use_post_meta')) {
    function use_post_meta($post_id, $key, $ttl = 86400) {
        return use_transient('post_meta_' . $post_id . '_' . $key, function() use ($post_id, $key) {
            $meta = null;
            if (function_exists('carbon_get_post_meta')) {
                $meta = carbon_get_post_meta($post_id, $key);
            }
            if (function_exists('get_field') && !isset($meta)) {
                $meta = get_field($key, $post_id);
            }
            return $meta ?? get_post_meta($post_id, $key, true);
        }, $ttl);
    }

    // メタデータ更新時にキャッシュを削除
    // WordPress標準のメタデータ更新フック（Carbon Fieldsは通常このフックで動作）
    add_action('updated_post_meta', function ($meta_id, $object_id, $meta_key, $meta_value) {
        delete_transient('post_meta_' . $object_id . '_' . $meta_key);
    }, 10, 4);

    // ACFの投稿メタデータ更新時にキャッシュを削除
    // ACFは独自の保存メカニズムを使用するため、acf/update_valueフックが必要
    if (function_exists('get_field')) {
        add_filter('acf/update_value', function ($value, $post_id, $field) {
            // 投稿の場合のみキャッシュを削除（オプションページやターム、ユーザーは除外）
            if (is_numeric($post_id) && get_post_type($post_id) !== false) {
                $field_name = is_array($field) ? (isset($field['name']) ? $field['name'] : '') : $field;
                if ($field_name) {
                    delete_transient('post_meta_' . $post_id . '_' . $field_name);
                }
            }
            return $value;
        }, 10, 3);
    }

    // メタデータ削除時にキャッシュを削除
    add_action('delete_post_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
        delete_transient('post_meta_' . $object_id . '_' . $meta_key);
    }, 10, 4);
}
