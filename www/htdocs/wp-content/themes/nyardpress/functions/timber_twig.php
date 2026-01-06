<?php
/**
 * TimberのTwig環境にFunctionやFilterを追加
 *
 * 関連フック
 * - timber/twig
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * TimberのTwig環境にFunctionやFilterを追加
 */
add_filter('timber/twig', function($twig) {
    // Functionの追加例
    // $twig->addFunction(new \Twig\TwigFunction('nya_function_name', function($arg) {
    //     // 処理内容
    //     return $result;
    // }));

    // Carbon Fieldsのメタデータを取得
    $twig->addFunction(new \Twig\TwigFunction('use_meta', function($post_id, $key, $ttl = 86400) {
        return use_meta($post_id, $key, $ttl);
    }));

    // ACF/SCFのメタデータを取得
    $twig->addFunction(new \Twig\TwigFunction('use_field', function($post_id, $key, $ttl = 86400) {
        return use_field($post_id, $key, $ttl);
    }));

    // Carbon Fields/ACF/SCFのオプションデータを取得
    $twig->addFunction(new \Twig\TwigFunction('use_option', function($key, $ttl = 86400) {
        return use_option($key, $ttl);
    }));

    // Timberのメニューを取得
    $twig->addFunction(new \Twig\TwigFunction('use_menu', function($location, $ttl = 86400 * 7) {
        return use_menu($location, $ttl);
    }));

    // Timberの投稿を取得
    $twig->addFunction(new \Twig\TwigFunction('use_posts', function($query_args, $key, $ttl = 86400) {
        return use_posts($query_args, $key, $ttl);
    }));

    // Timberのタームを取得
    $twig->addFunction(new \Twig\TwigFunction('use_term', function($term_id, $ttl = 86400) {
        return use_term($term_id, $ttl);
    }));

    // Timberのターム一覧を取得
    $twig->addFunction(new \Twig\TwigFunction('use_terms', function($query_args, $key, $ttl = 86400) {
        return use_terms($query_args, $key, $ttl);
    }));

    // Filterの追加例
    // $twig->addFilter(new \Twig\TwigFilter('nya_filter_name', function($value, $arg = null) {
    //     // 処理内容
    //     return $result;
    // }));

    return $twig;
});

