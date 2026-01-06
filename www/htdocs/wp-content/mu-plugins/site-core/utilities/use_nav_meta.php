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
    add_action('updated_post_meta', function ($meta_id, $object_id, $meta_key, $meta_value) {
        // メニューアイテムかどうかをチェック
        if (get_post_type($object_id) === 'nav_menu_item') {
            delete_transient('menu_meta_' . $object_id . '_' . $meta_key);
        }
    }, 10, 4);

    // メニューメタデータ削除時にキャッシュを削除
    // メニューアイテムのメタデータはpost_metaとして保存されるため、delete_post_metaフックを使用
    add_action('delete_post_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
        // メニューアイテムかどうかをチェック
        if (get_post_type($object_id) === 'nav_menu_item') {
            delete_transient('menu_meta_' . $object_id . '_' . $meta_key);
        }
    }, 10, 4);
}
