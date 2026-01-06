<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fieldsのメタデータを取得する
 * 更新時のキャッシュの削除は別途行うこと。
 *
 * @param int $post_id 投稿ID
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
if (!function_exists('use_meta')) {
    function use_meta($post_id, $key, $ttl = 86400) {
        return use_transient('meta_' . $post_id . '_' . $key, function() use ($post_id, $key) {
            if (function_exists('carbon_get_post_meta')) {
                return carbon_get_post_meta($post_id, $key);
            } else {
                return get_post_meta($post_id, $key);
            }
        }, $ttl);
    }
}
