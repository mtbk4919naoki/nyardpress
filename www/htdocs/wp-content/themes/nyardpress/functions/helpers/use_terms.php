<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してTimberのターム一覧を取得する
 * 更新時のキャッシュの削除は別途行うこと
 *
 * @param array $query_args クエリの引数
 * @param string $key キャッシュキー
 * @param int $ttl キャッシュの有効期限(秒)
 * @return array メニューの配列
 */
function use_terms($query_args, $key, $ttl = 86400) {
    return use_transient('terms_' . $key, function() use ($query_args) {
        return Timber\Timber::get_terms($query_args);
    }, $ttl);
}
