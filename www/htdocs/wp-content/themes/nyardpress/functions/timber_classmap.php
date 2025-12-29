<?php
/**
 * Timberのクラスマッピング
 *
 * Post、Term、Menu、MenuItem、Userの各クラスを拡張するためのclassmap設定
 * 実際のクラス実装は classes/ ディレクトリに分離されています
 *
 * 関連フック
 * - timber/post/classmap
 * - timber/term/classmap
 * - timber/menu/classmap
 * - timber/menuitem/classmap
 * - timber/user/classmap
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// カスタムクラスを読み込む
load_php_files(get_template_directory() . '/classes');

/**
 * TimberのPostクラスマッピング
 *
 * 投稿タイプごとにカスタムPostクラスをマッピングします。
 * 例: 'product' 投稿タイプには Product クラスを使用
 */
add_filter('timber/post/classmap', function($classmap) {
    // カスタム投稿タイプ 'product' に Product クラスをマッピングする例
    // $classmap['product'] = 'Product';

    // カスタム投稿タイプ 'example' に ExamplePost クラスをマッピングする例
    // $classmap['example'] = 'ExamplePost';

    return $classmap;
});

/**
 * TimberのTermクラスマッピング
 *
 * タクソノミーごとにカスタムTermクラスをマッピングします。
 * 例: 'product_category' タクソノミーには ProductCategory クラスを使用
 */
add_filter('timber/term/classmap', function($classmap) {
    // タクソノミー 'product_category' に ProductCategory クラスをマッピングする例
    // $classmap['product_category'] = 'ProductCategory';

    // タクソノミー 'example_category' に ExampleCategory クラスをマッピングする例
    // $classmap['example_category'] = 'ExampleCategory';

    return $classmap;
});

/**
 * TimberのMenuクラスマッピング
 *
 * メニュー位置ごとにカスタムMenuクラスをマッピングします。
 * 例: 'primary' メニューには PrimaryMenu クラスを使用
 */
add_filter('timber/menu/classmap', function($classmap) {
    // メニュー位置 'primary' に PrimaryMenu クラスをマッピングする例
    // $classmap['primary'] = 'PrimaryMenu';

    // メニュー位置 'footer' に FooterMenu クラスをマッピングする例
    // $classmap['footer'] = 'FooterMenu';

    return $classmap;
});

/**
 * TimberのMenuItemクラスマッピング
 *
 * メニュー項目のタイプごとにカスタムMenuItemクラスをマッピングします。
 * 例: カスタム投稿タイプのメニュー項目には CustomMenuItem クラスを使用
 */
add_filter('timber/menuitem/classmap', function($classmap) {
    // カスタムメニュー項目クラスをマッピングする例
    // $classmap['custom'] = 'CustomMenuItem';

    return $classmap;
});

/**
 * TimberのUserクラスマッピング
 *
 * ユーザーロールごとにカスタムUserクラスをマッピングします。
 * 例: 'administrator' ロールには AdminUser クラスを使用
 */
add_filter('timber/user/classmap', function($classmap) {
    // ユーザーロール 'administrator' に AdminUser クラスをマッピングする例
    // $classmap['administrator'] = 'AdminUser';

    // ユーザーロール 'editor' に EditorUser クラスをマッピングする例
    // $classmap['editor'] = 'EditorUser';

    return $classmap;
});
