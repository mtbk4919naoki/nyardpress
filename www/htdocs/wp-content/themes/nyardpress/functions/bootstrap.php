<?php
/**
 * テーマの初期化
 *
 * 関連フック
 * - muplugins_loaded
 * - plugins_loaded
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Timberの初期化
if (class_exists('Timber\Timber')) {
    Timber\Timber::init();
}
