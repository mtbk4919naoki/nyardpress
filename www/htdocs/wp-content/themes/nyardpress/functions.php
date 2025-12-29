<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Composerのオートローダーを読み込む
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
}

if(class_exists('Dotenv\Dotenv')) {
    $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
    $dotenv->load();
}

// ヘルパー関数を読み込む
load_php_files(__DIR__ . '/functions/helpers');

// 上から実行順で整理する
$function_files = [
    'bootstrap',
    'plugin',
    'setup_theme',
    // 'setup_carbon_fields', // mu-plugins/site-coreで管理
    // 'register_post_types', // mu-plugins/site-coreで管理
    // 'register_taxonomies', // mu-plugins/site-coreで管理
    'menus_widgets',
    'rest_api',
    'query_main',
    'template_routing',
    'timber_classmap',
    'timber_twig',
    'timber_context',
    'assets_front',
    'render_filters',
    'save_post',
    'admin_ui',
];

foreach ($function_files as $file) {
    require_once __DIR__ . "/functions/{$file}.php";
}
