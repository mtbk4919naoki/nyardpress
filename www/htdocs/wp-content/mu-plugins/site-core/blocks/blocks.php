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
 * コアブロックを無効化
 *
 * block_type_metadataフィルターを使用して、インサーターからブロックを非表示にします。
 * 既存のブロックは壊さず、新規追加だけを禁止できます。
 * 参考: https://zenn.dev/shimomura/articles/disable-gutenberg-blocks
 */
add_filter('block_type_metadata', function ($metadata) {
    $config = get_blocks_config();
    $disabled_core_blocks = isset($config['disabledCoreBlocks']) ? $config['disabledCoreBlocks'] : array();
    
    $blocks_to_disable = array();
    foreach ($disabled_core_blocks as $core_block_name) {
        if (strpos($core_block_name, '_') !== 0) {
            $blocks_to_disable[] = $core_block_name;
        }
    }
    
    if (!empty($blocks_to_disable) && isset($metadata['name']) && in_array($metadata['name'], $blocks_to_disable, true)) {
        if (!isset($metadata['supports'])) {
            $metadata['supports'] = array();
        }
        $metadata['supports']['inserter'] = false;
    }
    
    return $metadata;
}, 10, 1);

/**
 * カスタムブロックの登録
 */
add_action('init', function () {
    $blocks_dir = __DIR__;
    
    if (!is_dir($blocks_dir)) {
        return;
    }
    
    $config = get_blocks_config();
    $enabled_blocks = isset($config['enabled']) ? $config['enabled'] : array();
    $disabled_blocks = isset($config['disabled']) ? $config['disabled'] : array();
    
    // アンダースコアで始まる設定は無視
    $enabled_blocks = array_filter($enabled_blocks, function($block) {
        return strpos($block, '_') !== 0;
    });
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
        
        if (in_array($block_name, $disabled_blocks, true)) {
            continue;
        }
        
        if (!empty($enabled_blocks) && !in_array($block_name, $enabled_blocks, true)) {
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
        $mu_plugin_url = content_url('/mu-plugins/site-core');
        wp_enqueue_style(
            'site-core-blocks-editor',
            $mu_plugin_url . '/blocks/editor.css',
            array(),
            filemtime($editor_css_path)
        );
    }
});

add_action('wp_enqueue_scripts', function () {
    $style_css_path = __DIR__ . '/style.css';
    
    if (file_exists($style_css_path)) {
        $mu_plugin_url = content_url('/mu-plugins/site-core');
        wp_enqueue_style(
            'site-core-blocks',
            $mu_plugin_url . '/blocks/style.css',
            array(),
            filemtime($style_css_path)
        );
    }
});
