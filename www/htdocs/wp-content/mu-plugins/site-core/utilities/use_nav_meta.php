<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fieldsのメニューメタデータを取得する
 * 更新時のキャッシュの削除は別途行うこと。
 *
 * @param int $post_id 投稿ID
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
if (!function_exists('use_menu_meta')) {
    function use_menu_meta($menu_id, $key, $ttl = 86400) {
        return use_transient('menu_meta_' . $menu_id . '_' . $key, function() use ($menu_id, $key) {
            $meta = null;
            if (function_exists('carbon_get_nav_menu_item_meta')) {
                $meta = carbon_get_nav_menu_item_meta($menu_id, $key);
            }
            return $meta ?? get_post_meta($menu_id, $key, true);
        }, $ttl);
    }

    // メニューメタデータ更新時にキャッシュを削除
    // メニューアイテムのメタデータはpost_metaとして保存されるため、updated_post_metaフックを使用
    // WordPress標準のメタデータ更新フック（Carbon Fieldsは通常このフックで動作）
    add_action('updated_post_meta', function ($meta_id, $object_id, $meta_key, $meta_value) {
        // メニューアイテムかどうかをチェック
        if (get_post_type($object_id) === 'nav_menu_item') {
            delete_transient('menu_meta_' . $object_id . '_' . $meta_key);
        }
    }, 10, 4);

    // ACFのメニューメタデータ更新時にキャッシュを削除
    // ACFは独自の保存メカニズムを使用するため、acf/update_valueフックが必要
    // メニューアイテムは投稿として扱われるため、投稿と同じフックを使用
    if (function_exists('get_field')) {
        add_filter('acf/update_value', function ($value, $post_id, $field) {
            // メニューアイテムの場合のみキャッシュを削除
            if (is_numeric($post_id) && get_post_type($post_id) === 'nav_menu_item') {
                $field_name = is_array($field) ? (isset($field['name']) ? $field['name'] : '') : $field;
                if ($field_name) {
                    delete_transient('menu_meta_' . $post_id . '_' . $field_name);
                }
            }
            return $value;
        }, 10, 3);
    }

    // メニューメタデータ削除時にキャッシュを削除
    // メニューアイテムのメタデータはpost_metaとして保存されるため、delete_post_metaフックを使用
    add_action('delete_post_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
        // メニューアイテムかどうかをチェック
        if (get_post_type($object_id) === 'nav_menu_item') {
            delete_transient('menu_meta_' . $object_id . '_' . $meta_key);
        }
    }, 10, 4);
}
