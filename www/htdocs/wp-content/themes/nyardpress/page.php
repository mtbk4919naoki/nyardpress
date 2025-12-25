<?php
/**
 * The template for displaying all pages
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Timberのコンテキストを取得
$context = Timber\Timber::context();

// 現在のページを取得
$post = Timber\Timber::get_post();
$context['post'] = $post;

// テンプレートをレンダリング
Timber\Timber::render('page.twig', $context);

