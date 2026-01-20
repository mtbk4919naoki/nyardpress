<?php
/**
 * The template for displaying single posts
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Timberのコンテキストを取得
$context = Timber\Timber::context();

// // 現在の投稿を取得
// $post = Timber\Timber::get_post();

$context['content'] = apply_filters(
    'the_content',
    get_post_field('post_content', get_the_ID())
);
// テンプレートをレンダリング
Timber\Timber::render('single.twig', $context);

