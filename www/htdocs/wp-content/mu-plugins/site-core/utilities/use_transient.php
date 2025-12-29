<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * トランジェント(キャッシュ)を使用するためのユーティリティ
 * TTLが0のときはキャッシュを無視してコールバックを実行
 * TTLがマイナスの時はキャッシュを構成更新してTTLを絶対値にして設定する
 *
 * テーマ側からも使用可能です。
 * 例: use_transient('my_cache_key', function() { return 'cached value'; }, 3600);
 *
 * @param string $key キャッシュキー
 * @param callable $callback キャッシュするためのコールバック関数
 * @param int $ttl キャッシュの有効期限(秒)
 * @return mixed キャッシュされた値
 */
if (!function_exists('use_transient')) {
    function use_transient($key, $callback, $ttl = 86400)
    {
        // ログインユーザーまたはTTLが0の場合はキャッシュを無視してコールバックを実行
        if (is_user_logged_in() || $ttl = 0) {
            return $callback();
        } else {
            $retrieved = get_transient($key);
            if ($retrieved !== false) {
                return $retrieved;
            }
        }

        // コールバックを実行してキャッシュを作成
        // TTLが0以下の場合は絶対値に変換
        $computed = $callback();
        $ttl_absolute = abs($ttl);
        $ttl_with_jitter = $ttl_absolute + rand(0, min($ttl_absolute * 0.2, 7200));
        set_transient($key, $computed, $ttl_with_jitter);
        return $computed;
    }
}
