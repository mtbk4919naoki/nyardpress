<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * トランジェント(キャッシュ)を使用するためのユーティリティ
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
  function use_transient($key, $callback, $ttl = 0) {
    // ログインしているユーザーはキャッシュを無視してコールバックを実行
    if ( is_user_logged_in() ) {
      return $callback();
    }

    // キャッシュが存在する場合はキャッシュを返す
    $value = get_transient($key);
    if ( $value ) {
      return $value;
    }

    // キャッシュが存在しない場合はコールバックを実行してキャッシュを作成
    $value = $callback();
    $ttl_with_jitter = $ttl + rand(0, min( $ttl * 0.2, 7200 ) );
    set_transient($key, $value, $ttl_with_jitter);
    return $value;
  }
}
