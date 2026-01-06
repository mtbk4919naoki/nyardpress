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
}

// ユーザーメタデータ更新時にキャッシュを削除
add_action('updated_user_metadata', function ($meta_id, $object_id, $meta_key, $meta_value) {
	delete_transient('user_meta_' . $object_id . '_' . $meta_key);
}, 10, 4);

// ユーザーメタデータ削除時にキャッシュを削除
add_action('delete_user_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
	delete_transient('user_meta_' . $object_id . '_' . $meta_key);
}, 10, 4);
