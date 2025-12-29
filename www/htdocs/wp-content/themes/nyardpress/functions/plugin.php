<?php

/**
 * プラグイン関連の処理
 *
 * 関連フック
 * - activated_plugin
 * - deactivated_plugin
 * - plugin_loaded
 * - plugins_loaded
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// プラグイン関連の処理例
// add_action('activated_plugin', function($plugin) {
//     // プラグインが有効化された時の処理
// });

// add_action('deactivated_plugin', function($plugin) {
//     // プラグインが無効化された時の処理
// });

/**
 * Yoast SEOのスキーマを変更
 */
add_filter('wpseo_schema_website', function ($data)
{
    if ($data['potentialAction']) {
        foreach ($data['potentialAction'] as $key => $value) {
            # code...

            if ($value['@type'] && $value['@type'] == 'SearchAction') {
                unset($data['potentialAction'][$key]);
            }
        }
    }
    return $data;
});

/**
 * Query MonitorでWordPressの主要フックを監視
 * 各フックの開始時（優先度-9999）と終了時（優先度9999）にログを記録
 *
 * WordPressのライフサイクル全体を監視するため、主要なフックを含めています
 */
$monitored_hooks = array(
	'after_setup_theme',
	'init',
	'wp_head',
	'wp_footer',
);

foreach ($monitored_hooks as $hook) {
	// フック開始時にログ記録（最優先で実行）
	add_action($hook, function() use ($hook) {
		do_action('qm/start', "hook: $hook");
	}, -9999);

	// フック終了時にログ記録（最後に実行）
	add_action($hook, function() use ($hook) {
		do_action('qm/stop', "hook: $hook");
	}, 9999);
}

$monitored_period_hooks_pairs = array(
    'parse_request' => ['parse_request', 'wp'], // リクエストのパース
    'loop' => ['loop_start', 'loop_end'], // ループ
    'timber' => ['timber/loader/render_file', 'timber/compile/done'], // Timber
);

foreach ($monitored_period_hooks_pairs as $key => $hooks) {
    add_action($hooks[0], function() use ($key) {
        do_action('qm/start', "period: $key");
    }, -9999);
    add_action($hooks[1], function() use ($key) {
        do_action('qm/stop', "period: $key");
    }, 9999);
}
