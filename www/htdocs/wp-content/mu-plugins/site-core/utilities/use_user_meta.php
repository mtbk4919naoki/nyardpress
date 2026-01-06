<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fields/ACF/SCFのユーザーメタデータを取得する
 *
 * @param int $post_id 投稿ID
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
if (!function_exists('use_user_meta')) {
    function use_user_meta($user_id, $key, $ttl = 86400) {
        return use_transient('user_meta_' . $user_id . '_' . $key, function() use ($user_id, $key) {
            $meta = null;
            if (function_exists('carbon_get_user_meta')) {
                $meta = carbon_get_user_meta($user_id, $key);
            }
            if (function_exists('get_field') && !isset($meta)) {
                $meta = get_field($key, 'user_' . $user_id);
            }
            return $meta ?? get_user_meta($user_id, $key);
        }, $ttl);
    }

    // ユーザーメタデータ更新時にキャッシュを削除
    // WordPress標準のメタデータ更新フック（Carbon Fieldsは通常このフックで動作）
    add_action('updated_user_metadata', function ($meta_id, $object_id, $meta_key, $meta_value) {
        delete_transient('user_meta_' . $object_id . '_' . $meta_key);
    }, 10, 4);

    // ACFのユーザーメタデータ更新時にキャッシュを削除
    // ACFは独自の保存メカニズムを使用するため、acf/update_valueフックが必要
    if (function_exists('get_field')) {
        add_filter('acf/update_value', function ($value, $post_id, $field) {
            // ユーザーの場合のみキャッシュを削除（$post_idが'user_user_id'形式）
            if (is_string($post_id) && strpos($post_id, 'user_') === 0) {
                $user_id = (int)str_replace('user_', '', $post_id);
                if ($user_id > 0) {
                    $field_name = is_array($field) ? (isset($field['name']) ? $field['name'] : '') : $field;
                    if ($field_name) {
                        delete_transient('user_meta_' . $user_id . '_' . $field_name);
                    }
                }
            }
            return $value;
        }, 10, 3);
    }

    // ユーザーメタデータ削除時にキャッシュを削除
    add_action('delete_user_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
        delete_transient('user_meta_' . $object_id . '_' . $meta_key);
    }, 10, 4);
}
