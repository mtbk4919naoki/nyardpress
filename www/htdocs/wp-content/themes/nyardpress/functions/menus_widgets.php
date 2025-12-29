<?php
/**
 * メニューとウィジェットエリアの登録
 *
 * 関連フック
 * - init (メニュー登録)
 * - widgets_init (ウィジェットエリア登録)
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * メニュー位置を登録する
 */
add_action('init', function() {
    $menus = [
        'header' => 'ヘッダーメニュー',
        'drawer' => 'ドロワーメニュー',
        'footer'  => 'フッターメニュー',
    ];
    // メニューを登録
    register_nav_menus($menus);

    // 記事更新時にキャッシュを削除するアクションを登録
    add_action('save_post', function() use ($menus) {
        foreach ($menus as $location => $name) {
            delete_transient('menu_' . $location);
        }
    });

    // ナビゲーションメニュー更新時にキャッシュを削除
    add_action('wp_update_nav_menu', function() use ($menus) {
        foreach ($menus as $location => $name) {
            delete_transient('menu_' . $location);
        }
    });
});

/**
 * ウィジェットエリアを登録する
 */
// add_action('widgets_init', function() {
//     register_sidebar(array(
//         'name'          => 'サイドバー',
//         'id'            => 'sidebar-1',
//         'description'   => 'メインサイドバー',
//         'before_widget' => '<section id="%1$s" class="widget %2$s">',
//         'after_widget'  => '</section>',
//         'before_title'  => '<h2 class="widget-title">',
//         'after_title'   => '</h2>',
//     ));
// });

