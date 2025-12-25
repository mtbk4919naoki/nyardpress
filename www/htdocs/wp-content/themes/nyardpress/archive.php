<?php
/**
 * The template for displaying archive pages
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Timberのコンテキストを取得
$context = Timber\Timber::context();

// アーカイブのタイトルを取得
$context['title'] = 'アーカイブ';
if (is_category()) {
    $context['title'] = single_cat_title('', false);
} elseif (is_tag()) {
    $context['title'] = single_tag_title('', false);
} elseif (is_author()) {
    $context['title'] = '投稿者: ' . get_the_author();
} elseif (is_post_type_archive()) {
    $context['title'] = post_type_archive_title('', false);
} elseif (is_tax()) {
    $context['title'] = single_term_title('', false);
}

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
Timber\Timber::render('archive.twig', $context);

