<?php
/**
 * Carbon Fields の初期化
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// Carbon Fieldsが利用可能な場合のみ初期化
if (class_exists('Carbon_Fields\\Carbon_Fields')) {
    \Carbon_Fields\Carbon_Fields::boot();
}


