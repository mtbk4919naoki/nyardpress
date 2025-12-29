<?php
/**
 * レンダリング時のフィルター
 *
 * 関連フック
 * - the_content
 * - the_excerpt
 * - the_title
 * - wp_title
 * - excerpt_length
 * - excerpt_more
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// レンダリングフィルターの例
// add_filter('the_content', function($content) {
//     // コンテンツの加工
//     return $content;
// });

// add_filter('excerpt_length', function($length) {
//     return 40;
// });

// add_filter('excerpt_more', function($more) {
//     return '...';
// });

