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
    register_nav_menus(array(
        'primary' => 'プライマリーメニュー',
        'footer'  => 'フッターメニュー',
    ));
});

/**
 * ウィジェットエリアを登録する
 */
add_action('widgets_init', function() {
    register_sidebar(array(
        'name'          => 'サイドバー',
        'id'            => 'sidebar-1',
        'description'   => 'メインサイドバー',
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget'  => '</section>',
        'before_title'  => '<h2 class="widget-title">',
        'after_title'   => '</h2>',
    ));
});

