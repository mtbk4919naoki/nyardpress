<?php
/**
 * テーマのサポート機能と画像サイズの設定
 *
 * 関連フック
 * - after_setup_theme
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * テーマのサポート機能を有効化
 */
add_action('after_setup_theme', function() {
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
});

/**
 * 画像サイズの追加
 */
add_action('after_setup_theme', function() {
    add_image_size('nyardpress-thumbnail', 300, 300, true);
    add_image_size('nyardpress-medium', 600, 400, true);
    add_image_size('nyardpress-large', 1200, 800, true);
});

