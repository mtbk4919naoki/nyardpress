<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してTimberのタームを取得する
 * 更新時のキャッシュの削除は別途行うこと
 *
 * @param int $term_id タームID
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array タームの配列
 */
function use_term($term_id, $ttl = 86400) {
    return use_transient('term_' . $term_id, function() use ($term_id) {
        return Timber\Timber::get_term($term_id);
    }, $ttl);
}
