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
    // updated_post_meta は4つのパラメータ（$meta_id, $object_id, $meta_key, $meta_value）を取る
    add_action('updated_post_meta', function ($meta_id, $object_id, $meta_key, $meta_value) {
        delete_transient('post_meta_' . $object_id . '_' . $meta_key);
    }, 10, 4);

    // メタデータ削除時にキャッシュを削除
    add_action('delete_post_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
        delete_transient('post_meta_' . $object_id . '_' . $meta_key);
    }, 10, 4);
}
