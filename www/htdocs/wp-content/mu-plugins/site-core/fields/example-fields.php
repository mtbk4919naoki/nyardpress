<?php
/**
 * Carbon Fields のカスタムフィールドサンプル
 *
 * このファイルをコピーして、新しいカスタムフィールドを作成してください。
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

use Carbon_Fields\Container;
use Carbon_Fields\Field;

/**
 * カスタム投稿タイプ 'example' にカスタムフィールドを追加
 */
function add_example_custom_fields() {
    Container::make('post_meta', '追加情報')
        ->where('post_type', '=', 'example')
        ->add_fields(array(
            Field::make('text', 'example_text', 'テキストフィールド')
                ->set_help_text('サンプルのテキストフィールドです'),

            Field::make('textarea', 'example_textarea', 'テキストエリア')
                ->set_help_text('サンプルのテキストエリアです'),

            Field::make('image', 'example_image', '画像')
                ->set_help_text('サンプルの画像フィールドです'),

            Field::make('complex', 'example_complex', '複合フィールド')
                ->add_fields(array(
                    Field::make('text', 'title', 'タイトル'),
                    Field::make('textarea', 'description', '説明'),
                ))
                ->set_layout('tabbed-horizontal')
                ->set_help_text('サンプルの複合フィールドです'),

            Field::make('select', 'example_select', 'セレクトボックス')
                ->add_options(array(
                    'option1' => 'オプション1',
                    'option2' => 'オプション2',
                    'option3' => 'オプション3',
                ))
                ->set_help_text('サンプルのセレクトボックスです'),

            Field::make('checkbox', 'example_checkbox', 'チェックボックス')
                ->set_help_text('サンプルのチェックボックスです'),

            Field::make('date', 'example_date', '日付')
                ->set_help_text('サンプルの日付フィールドです'),
        ));
}
//add_action('carbon_fields_register_fields', 'add_example_custom_fields');

/**
 * タクソノミー 'example_category' にカスタムフィールドを追加
 */
function add_example_category_custom_fields() {
    Container::make('term_meta', 'カテゴリー追加情報')
        ->where('term_taxonomy', '=', 'example_category')
        ->add_fields(array(
            Field::make('image', 'category_image', 'カテゴリー画像')
                ->set_help_text('カテゴリーの画像を設定できます'),

            Field::make('text', 'category_color', 'カテゴリーカラー')
                ->set_help_text('カテゴリーのカラーコードを設定できます（例: #ff0000）'),
        ));
}
add_action('carbon_fields_register_fields', 'add_example_category_custom_fields');

/**
 * オプションページにカスタムフィールドを追加（オプション）
 */
function add_example_options_fields() {
    Container::make('theme_options', 'サイト設定')
        ->set_page_menu_position(2)
        ->set_icon('dashicons-admin-settings')
        ->add_fields(array(
            Field::make('text', 'site_phone', '電話番号')
                ->set_help_text('サイトの電話番号を設定します'),

            Field::make('text', 'site_email', 'メールアドレス')
                ->set_help_text('サイトのメールアドレスを設定します'),

            Field::make('image', 'site_logo', 'サイトロゴ')
                ->set_help_text('サイトのロゴ画像を設定します'),
        ));
}
// オプションページが必要な場合はコメントアウトを外してください
// add_action('carbon_fields_register_fields', 'add_example_options_fields');

