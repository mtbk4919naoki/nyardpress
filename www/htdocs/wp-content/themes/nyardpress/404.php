<?php
/**
 * The template for displaying 404 pages (not found)
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Timberのコンテキストを取得
$context = Timber\Timber::context();

// 404ページのタイトル
$context['title'] = '404 - ページが見つかりません';

// テンプレートをレンダリング
Timber\Timber::render('404.twig', $context);

