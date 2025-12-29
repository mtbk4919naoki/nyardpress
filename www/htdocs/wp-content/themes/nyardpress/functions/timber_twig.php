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

    // Filterの追加例
    // $twig->addFilter(new \Twig\TwigFilter('nya_filter_name', function($value, $arg = null) {
    //     // 処理内容
    //     return $result;
    // }));

    return $twig;
});

