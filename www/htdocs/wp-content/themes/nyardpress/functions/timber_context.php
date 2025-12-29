<?php
/**
 * Timberのコンテキストとロケーション設定
 *
 * 関連フック
 * - timber/context
 * - timber/locations
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Timberのコンテキストを設定
 */
add_filter('timber/context', function($context) {
    // デフォルトのコンテキストを取得
    $context = Timber\Timber::context();

    // サイト情報を追加（既にcontextに含まれている場合は上書きしない）
    if (!isset($context['site'])) {
        $context['site'] = Timber\Timber::get_site();
    }

    // メニューを追加（メニューが存在する場合のみ）
    $menu = Timber\Timber::get_menu('primary');
    if ($menu) {
        $context['menu'] = $menu;
    }

    // サイドバーウィジェットエリア
    $context['sidebar'] = Timber\Timber::get_widgets('sidebar-1');

    return $context;
});

/**
 * Timberのテンプレートディレクトリを設定
 * Timber 2.0以降では連想配列を使用する必要があります
 * $locsは連想配列で、各値はパスの配列です
 */
add_filter('timber/locations', function($locs) {
    // デフォルトの名前空間（0）にパスを追加
    if (!isset($locs[0]) || !is_array($locs[0])) {
        $locs[0] = [];
    }
    $views_path = get_template_directory() . '/views';
    if (!in_array($views_path, $locs[0], true)) {
        $locs[0][] = $views_path;
    }
    return $locs;
});

