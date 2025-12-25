<?php
/**
 * カスタムタクソノミーのサンプル
 * 
 * このファイルをコピーして、新しいカスタムタクソノミーを作成してください。
 * ファイル名はタクソノミーのスラッグに合わせて変更してください。
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * カスタムタクソノミーを登録
 */
function register_example_category_taxonomy() {
    $labels = array(
        'name'                       => 'サンプルカテゴリー',
        'singular_name'              => 'サンプルカテゴリー',
        'menu_name'                  => 'サンプルカテゴリー',
        'all_items'                  => 'すべてのサンプルカテゴリー',
        'parent_item'                => '親サンプルカテゴリー',
        'parent_item_colon'          => '親サンプルカテゴリー:',
        'new_item_name'              => '新しいサンプルカテゴリー',
        'add_new_item'               => '新しいサンプルカテゴリーを追加',
        'edit_item'                  => 'サンプルカテゴリーを編集',
        'update_item'                => 'サンプルカテゴリーを更新',
        'view_item'                  => 'サンプルカテゴリーを表示',
        'separate_items_with_commas' => 'カンマで区切ってサンプルカテゴリーを追加',
        'add_or_remove_items'        => 'サンプルカテゴリーを追加または削除',
        'choose_from_most_used'      => 'よく使われるサンプルカテゴリーから選択',
        'popular_items'              => '人気のサンプルカテゴリー',
        'search_items'               => 'サンプルカテゴリーを検索',
        'not_found'                  => 'サンプルカテゴリーが見つかりませんでした',
        'no_terms'                   => 'サンプルカテゴリーがありません',
        'items_list'                 => 'サンプルカテゴリー一覧',
        'items_list_navigation'      => 'サンプルカテゴリー一覧ナビゲーション',
    );

    $args = array(
        'labels'                     => $labels,
        'hierarchical'               => true, // true の場合はカテゴリー型、false の場合はタグ型
        'public'                     => true,
        'show_ui'                    => true,
        'show_admin_column'          => true,
        'show_in_nav_menus'          => true,
        'show_tagcloud'              => true,
        'show_in_rest'               => true, // Gutenbergエディタで使用可能にする
        'rewrite'                    => array('slug' => 'example-category'),
    );

    // 'example' カスタム投稿タイプに紐付け
    register_taxonomy('example_category', array('example'), $args);
}
add_action('init', 'register_example_category_taxonomy', 0);

