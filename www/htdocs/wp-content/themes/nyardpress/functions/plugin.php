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

