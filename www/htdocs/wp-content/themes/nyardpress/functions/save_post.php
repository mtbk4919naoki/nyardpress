<?php
/**
 * 投稿保存時の処理
 *
 * 関連フック
 * - save_post
 * - wp_insert_post_data
 * - transition_post_status
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// 投稿保存時の処理例
// add_action('save_post', function($post_id, $post, $update) {
//     // 投稿保存時の処理
// }, 10, 3);

// add_filter('wp_insert_post_data', function($data, $postarr) {
//     // 投稿データの加工
//     return $data;
// }, 10, 2);

