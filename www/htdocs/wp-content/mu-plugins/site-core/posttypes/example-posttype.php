<?php
/**
 * カスタム投稿タイプのサンプル
 * 
 * このファイルをコピーして、新しいカスタム投稿タイプを作成してください。
 * ファイル名は投稿タイプのスラッグに合わせて変更してください。
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * カスタム投稿タイプを登録
 */
function register_example_post_type() {
    $labels = array(
        'name'                  => 'サンプル投稿',
        'singular_name'         => 'サンプル投稿',
        'menu_name'             => 'サンプル投稿',
        'name_admin_bar'        => 'サンプル投稿',
        'add_new'               => '新規追加',
        'add_new_item'          => '新しいサンプル投稿を追加',
        'new_item'              => '新しいサンプル投稿',
        'edit_item'             => 'サンプル投稿を編集',
        'view_item'             => 'サンプル投稿を表示',
        'all_items'             => 'すべてのサンプル投稿',
        'search_items'          => 'サンプル投稿を検索',
        'not_found'             => 'サンプル投稿が見つかりませんでした',
        'not_found_in_trash'    => 'ゴミ箱にサンプル投稿はありませんでした',
    );

    $args = array(
        'labels'                => $labels,
        'public'                => true,
        'publicly_queryable'    => true,
        'show_ui'               => true,
        'show_in_menu'          => true,
        'query_var'             => true,
        'rewrite'               => array('slug' => 'example'),
        'capability_type'       => 'post',
        'has_archive'           => true,
        'hierarchical'          => false,
        'menu_position'         => 5,
        'menu_icon'             => 'dashicons-admin-post',
        'supports'              => array('title', 'editor', 'thumbnail', 'excerpt', 'custom-fields'),
        'show_in_rest'          => true, // Gutenbergエディタを有効化
    );

    register_post_type('example', $args);
}
add_action('init', 'register_example_post_type');

