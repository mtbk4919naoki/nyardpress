<?php
/**
 * ブロック管理
 *
 * カスタムブロックの登録とコアブロックの無効化を管理します。
 */

if (!defined('ABSPATH')) {
    exit;
}

/**
 * ブロック設定ファイルを読み込む
 *
 * @return array 設定配列
 */
function get_blocks_config() {
    static $config = null;

    if ($config === null) {
        $config_path = __DIR__ . '/blocks-config.json';
        $config = array();

        if (file_exists($config_path)) {
            $loaded = json_decode(file_get_contents($config_path), true);
            if (is_array($loaded)) {
                $config = $loaded;
            }
        }
    }

    return $config;
}

/**
 * 利用可能ブロックをホワイトリスト方式で制限
 *
 * allowed_block_types_allフィルターを使用して、許可されたブロックのみを利用可能にします。
 * WordPress更新時に新しいブロックが自動的に追加されるのを防ぎます。
 */
add_filter('allowed_block_types_all', function ($allowed_block_types, $editor_context) {
    $config = get_blocks_config();
    $allowed_blocks = isset($config['allowedBlocks']) ? $config['allowedBlocks'] : array();

    // allowedBlocksが設定されていない場合は、すべてのブロックを許可（従来の動作）
    if (empty($allowed_blocks)) {
        return $allowed_block_types;
    }

    // アンダースコアで始まる設定は無視
    $allowed_list = array();
    foreach ($allowed_blocks as $block_name) {
        if (strpos($block_name, '_') !== 0) {
            $allowed_list[] = $block_name;
        }
    }

    // カスタムブロック（nya/で始まる）を自動的に追加
    $blocks_dir = __DIR__;
    if (is_dir($blocks_dir)) {
        $directories = glob($blocks_dir . '/*', GLOB_ONLYDIR);
        foreach ($directories as $block_dir) {
            $block_json_path = $block_dir . '/block.json';
            if (file_exists($block_json_path)) {
                $block_metadata = json_decode(file_get_contents($block_json_path), true);
                if ($block_metadata && isset($block_metadata['name'])) {
                    $block_name = $block_metadata['name'];
                    // nya/で始まるカスタムブロックを自動的に追加
                    if (strpos($block_name, 'nya/') === 0 && !in_array($block_name, $allowed_list, true)) {
                        $allowed_list[] = $block_name;
                    }
                }
            }
        }
    }

    return $allowed_list;
}, 10, 2);

/**
 * カスタムブロックの登録
 */
add_action('init', function () {
    $blocks_dir = __DIR__;

    if (!is_dir($blocks_dir)) {
        return;
    }

    $config = get_blocks_config();
    $disabled_blocks = isset($config['disabled']) ? $config['disabled'] : array();

    // アンダースコアで始まる設定は無視
    $disabled_blocks = array_filter($disabled_blocks, function($block) {
        return strpos($block, '_') !== 0;
    });

    $directories = glob($blocks_dir . '/*', GLOB_ONLYDIR);

    foreach ($directories as $block_dir) {
        $block_json_path = $block_dir . '/block.json';

        if (!file_exists($block_json_path)) {
            continue;
        }

        $block_name = basename($block_dir);

        // 先頭アンダースコアで始まるディレクトリは無視
        if (strpos($block_name, '_') === 0) {
            continue;
        }

        // 無効化リストに含まれている場合はスキップ
        if (in_array($block_name, $disabled_blocks, true)) {
            continue;
        }

        $block_metadata = json_decode(file_get_contents($block_json_path), true);
        if (!$block_metadata || !isset($block_metadata['name'])) {
            continue;
        }

        register_block_type($block_dir);
    }
}, 20);

/**
 * ブロック用CSSの読み込み
 */
add_action('enqueue_block_editor_assets', function () {
    $editor_css_path = __DIR__ . '/editor.css';

    if (file_exists($editor_css_path)) {
        $editor_css_url = plugins_url('editor.css', __FILE__);
        wp_enqueue_style(
            'site-core-blocks-editor',
            $editor_css_url,
            array(),
            filemtime($editor_css_path)
        );
    }
});

add_action('wp_enqueue_scripts', function () {
    // フロントエンド用CSS
    $style_css_path = __DIR__ . '/style.css';
    if (file_exists($style_css_path)) {
        $style_css_url = plugins_url('style.css', __FILE__);
        wp_enqueue_style(
            'site-core-blocks',
            $style_css_url,
            array(),
            filemtime($style_css_path)
        );
    }

    // フロントエンド用JavaScript
    $script_js_path = __DIR__ . '/script.js';
    if (file_exists($script_js_path)) {
        $script_js_url = plugins_url('script.js', __FILE__);
        wp_enqueue_script(
            'site-core-blocks',
            $script_js_url,
            array(),
            filemtime($script_js_path),
            true
        );
    }
});

