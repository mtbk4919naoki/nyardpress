<?php
/**
 * メインクエリの処理
 *
 * 関連フック
 * - pre_get_posts
 * - posts_clauses
 * - posts_orderby
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// メインクエリのカスタマイズ例
// add_action('pre_get_posts', function($query) {
//     if (!is_admin() && $query->is_main_query()) {
//         // メインクエリのカスタマイズ
//     }
// });

