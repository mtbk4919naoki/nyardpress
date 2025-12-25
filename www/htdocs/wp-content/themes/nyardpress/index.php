<?php
/**
 * The main template file
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Timberのコンテキストを取得
$context = Timber\Timber::context();

// 投稿一覧を取得（ページネーション情報を含む）
$posts = Timber\Timber::get_posts();
$context['posts'] = $posts;

// ページネーション情報を追加（Timber 2.0対応）
if ($posts && method_exists($posts, 'pagination')) {
    $pagination_obj = $posts->pagination();
    // Paginationオブジェクトを配列に変換（Timber 2.0対応）
    if ($pagination_obj && is_object($pagination_obj)) {
        $context['pagination'] = array(
            'current' => $pagination_obj->current ?? null,
            'total' => $pagination_obj->total ?? null,
            'pages' => $pagination_obj->pages ?? array(),
            'next' => $pagination_obj->next ?? null,
            'prev' => $pagination_obj->prev ?? null,
        );
    }
}

// テンプレートをレンダリング
Timber\Timber::render('index.twig', $context);

