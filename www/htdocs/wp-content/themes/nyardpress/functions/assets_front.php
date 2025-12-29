<?php
/**
 * フロントエンドのアセット読み込み
 *
 * 関連フック
 * - wp_enqueue_scripts
 * - script_loader_tag
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * スタイルとスクリプトの読み込み
 * Viteでビルドしたファイルを読み込む（dev/build両対応）
 */
add_action('wp_enqueue_scripts', function() {
    $theme_version = wp_get_theme()->get('Version');
    $template_dir = get_template_directory();
    $template_uri = get_template_directory_uri();

    // 開発モードの判定
    $is_dev = get_config('WP_DEBUG', true);
    $vite_port = get_config('VITE_PORT', 3000);

    if ($is_dev) {
        // 開発環境: Viteの開発サーバーから読み込む（HMR対応）
        // バージョンクエリパラメータは不要（Viteサーバーが処理できないため）
        $vite_url = "http://localhost:{$vite_port}";

        // Vite HMRクライアント（headで読み込む、優先度を高くするため依存関係なし）
        wp_enqueue_script(
            'vite-client',
            "{$vite_url}/@vite/client",
            array(),
            null, // バージョンクエリパラメータを追加しない
            false
        );

        // CSSファイル
        wp_enqueue_style(
            'main-style',
            "{$vite_url}/css/style.css",
            array(),
            null // バージョンクエリパラメータを追加しない
        );

        // メインスクリプト
        wp_enqueue_script(
            'main-script',
            "{$vite_url}/js/main.ts",
            array('nyardpress-vite-client'),
            null, // バージョンクエリパラメータを追加しない
            true
        );
    } else {
        // 本番環境: ビルド済みファイルを読み込む
        $manifest_path = $template_dir . '/assets/.vite/manifest.json';

        if (file_exists($manifest_path)) {
            $manifest = json_decode(file_get_contents($manifest_path), true);

            // CSSファイルを読み込む
            $css_key = null;
            if (isset($manifest['css/style.css'])) {
                $css_key = 'css/style.css';
            } elseif (isset($manifest['src/css/style.css'])) {
                $css_key = 'src/css/style.css';
            }

            if ($css_key && isset($manifest[$css_key]['file'])) {
                wp_enqueue_style(
                    'main-style',
                    $template_uri . '/assets/' . $manifest[$css_key]['file'],
                    array(),
                    $theme_version
                );
            }

            // JavaScriptファイルを読み込む
            $js_key = null;
            if (isset($manifest['js/main.ts'])) {
                $js_key = 'js/main.ts';
            } elseif (isset($manifest['src/js/main.ts'])) {
                $js_key = 'src/js/main.ts';
            }

            if ($js_key && isset($manifest[$js_key]['file'])) {
                wp_enqueue_script(
                    'main-script',
                    $template_uri . '/assets/' . $manifest[$js_key]['file'],
                    array(),
                    $theme_version,
                    true
                );
            }
        } else {
            // manifest.jsonが存在しない場合のフォールバック
            $css_file = $template_dir . '/assets/css/style.css';
            if (file_exists($css_file)) {
                wp_enqueue_style(
                    'main-style',
                    $template_uri . '/assets/css/style.css',
                    array(),
                    $theme_version
                );
            }

            $js_file = $template_dir . '/assets/js/main.js';
            if (file_exists($js_file)) {
                wp_enqueue_script(
                    'main-script',
                    $template_uri . '/assets/js/main.js',
                    array(),
                    $theme_version,
                    true
                );
            }
        }
    }
});

/**
 * スクリプトにtype="module"を追加
 */
add_filter('script_loader_tag', function($tag, $handle, $src) {
    $module_handles = array('vite-client', 'main-script');
    if (in_array($handle, $module_handles, true)) {
        $tag = str_replace('<script ', '<script type="module" ', $tag);
    }
    return $tag;
}, 10, 3);

