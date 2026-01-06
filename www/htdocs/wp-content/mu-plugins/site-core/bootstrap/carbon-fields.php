<?php
/**
 * Carbon Fields の初期化
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

add_action('after_setup_theme', function () {
    \Carbon_Fields\Carbon_Fields::boot();
}, 0);

