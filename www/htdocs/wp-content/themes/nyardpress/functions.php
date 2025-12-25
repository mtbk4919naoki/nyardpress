<?php
/**
 * Nyardpress Theme Functions
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Composerのオートローダーを読み込む
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
}

// Timberの初期化
if (class_exists('Timber\Timber')) {
    Timber\Timber::init();
}

/**
 * Timberのコンテキストを設定
 */
function nyardpress_context($context) {
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
}
add_filter('timber/context', 'nyardpress_context');

/**
 * Timberのテンプレートディレクトリを設定
 * Timber 2.0以降では連想配列を使用する必要があります
 * $locsは連想配列で、各値はパスの配列です
 */
function nyardpress_timber_locations($locs) {
    // デフォルトの名前空間（0）にパスを追加
    if (!isset($locs[0]) || !is_array($locs[0])) {
        $locs[0] = [];
    }
    $views_path = get_template_directory() . '/views';
    if (!in_array($views_path, $locs[0], true)) {
        $locs[0][] = $views_path;
    }
    return $locs;
}
add_filter('timber/locations', 'nyardpress_timber_locations');

/**
 * テーマのサポート機能を有効化
 */
function nyardpress_theme_support() {
    // タイトルタグのサポート
    add_theme_support('title-tag');
    
    // アイキャッチ画像のサポート
    add_theme_support('post-thumbnails');
    
    // HTML5マークアップのサポート
    add_theme_support('html5', array(
        'search-form',
        'comment-form',
        'comment-list',
        'gallery',
        'caption',
    ));
    
    // カスタムロゴのサポート
    add_theme_support('custom-logo', array(
        'height'      => 100,
        'width'       => 400,
        'flex-height' => true,
        'flex-width'  => true,
    ));
    
    // フィードリンクのサポート
    add_theme_support('automatic-feed-links');
}
add_action('after_setup_theme', 'nyardpress_theme_support');

/**
 * メニューの登録
 */
function nyardpress_register_menus() {
    register_nav_menus(array(
        'primary' => 'プライマリーメニュー',
        'footer'  => 'フッターメニュー',
    ));
}
add_action('init', 'nyardpress_register_menus');

/**
 * ウィジェットエリアの登録
 */
function nyardpress_register_sidebars() {
    register_sidebar(array(
        'name'          => 'サイドバー',
        'id'            => 'sidebar-1',
        'description'   => 'メインサイドバー',
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget'  => '</section>',
        'before_title'  => '<h2 class="widget-title">',
        'after_title'   => '</h2>',
    ));
}
add_action('widgets_init', 'nyardpress_register_sidebars');

/**
 * スタイルとスクリプトの読み込み
 */
function nyardpress_enqueue_scripts() {
    // テーマのスタイルシート
    wp_enqueue_style(
        'nyardpress-style',
        get_stylesheet_uri(),
        array(),
        wp_get_theme()->get('Version')
    );
    
    // メインのJavaScript
    if (file_exists(get_template_directory() . '/assets/js/main.js')) {
        wp_enqueue_script(
            'nyardpress-main',
            get_template_directory_uri() . '/assets/js/main.js',
            array(),
            wp_get_theme()->get('Version'),
            true
        );
    }
}
add_action('wp_enqueue_scripts', 'nyardpress_enqueue_scripts');

/**
 * 画像サイズの追加
 */
function nyardpress_image_sizes() {
    add_image_size('nyardpress-thumbnail', 300, 300, true);
    add_image_size('nyardpress-medium', 600, 400, true);
    add_image_size('nyardpress-large', 1200, 800, true);
}
add_action('after_setup_theme', 'nyardpress_image_sizes');

