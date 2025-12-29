<?php
/**
 * テンプレートのルーティング
 *
 * 関連フック
 * - template_redirect
 * - template_include
 * - body_class
 * - post_class
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// テンプレートのルーティング例
// add_action('template_redirect', function() {
//     // テンプレートのリダイレクト処理
// });

// add_filter('template_include', function($template) {
//     // テンプレートの変更
//     return $template;
// });

