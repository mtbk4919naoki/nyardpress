<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してCarbon Fields/ACF/SCFのタームメタデータを取得する
 *
 * @param int $post_id 投稿ID
 * @param string $key メタデータのキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メタデータの配列
 */
if (!function_exists('use_term_meta')) {
    function use_term_meta($term_id, $key, $ttl = 86400) {
        return use_transient('term_meta_' . $term_id . '_' . $key, function() use ($term_id, $key) {
            $meta = null;
            if (function_exists('carbon_get_term_meta')) {
                $meta = carbon_get_term_meta($term_id, $key);
            }
            if (function_exists('get_field') && !isset($meta)) {
                $term = get_term($term_id);
                if ($term && !is_wp_error($term)) {
                    $meta = get_field($key, $term->taxonomy . '_' . $term_id);
                }
            }
            return $meta ?? get_term_meta($term_id, $key);
        }, $ttl);
    }
}

// タームメタデータ更新時にキャッシュを削除
add_action('updated_term_metadata', function ($meta_id, $object_id, $meta_key, $meta_value) {
	delete_transient('term_meta_' . $object_id . '_' . $meta_key);
}, 10, 4);

// タームメタデータ削除時にキャッシュを削除
add_action('delete_term_meta', function ($meta_ids, $object_id, $meta_key, $meta_value) {
	delete_transient('term_meta_' . $object_id . '_' . $meta_key);
}, 10, 4);
