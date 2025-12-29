<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * transientAPIを介してメニューを取得する
 * 更新時のキャッシュの削除は別途行うこと
 *
 * @param string $location メニューの位置
 * @return array メニューの配列
 */
function use_menu($location, $ttl = 86400 * 7) { // 7日
    return use_transient('menu_' . $location, function() use ($location) {
        return Timber\Timber::get_menu($location);
    }, $ttl);
}
