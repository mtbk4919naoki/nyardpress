<?php
/**
 * Render callback for nya/example
 *
 * @param array $attributes Block attributes
 * @param string $content Block content (inner blocks)
 * @param WP_Block $block Block instance
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// ユーティリティ関数を読み込む（nya_twig関数を使用）
if (!function_exists('nya_twig')) {
    // site-coreのutilities/nya_twig.phpを読み込む
    $twig_utility = dirname(dirname(__DIR__)) . '/utilities/nya_twig.php';
    if (file_exists($twig_utility)) {
        require_once $twig_utility;
    }
}

// 動的ブロックの場合、attributesに直接値が保存される
// $attributesは配列またはオブジェクトの可能性がある
$context = array();
if (is_array($attributes)) {
    $context = $attributes;
} elseif (is_object($attributes)) {
    $context = (array) $attributes;
}

// ブロック名をコンテキストに追加
$context['block_name'] = 'nya-example';
$context['block_class'] = 'wp-block-nya-example';

// Twig環境を取得
$views_dir = __DIR__ . '/views';
$twig = nya_twig($views_dir);

if ($twig) {
    // Twigテンプレートをレンダリング
    try {
        echo $twig->render('view.twig', $context);
    } catch (Exception $e) {
        error_log('Twig render error: ' . $e->getMessage());
        echo '<div class="wp-block-nya-example"><p>Template rendering error.</p></div>';
    }
}
