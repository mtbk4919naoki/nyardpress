<?php
/**
 * REST API関連の処理
 *
 * 関連フック
 * - rest_api_init
 * - rest_prepare_{$post_type}
 * - rest_authentication_errors
 * - rest_endpoints
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * REST APIにカスタムフィールドを追加
 * 
 * 既存の投稿タイプやカスタム投稿タイプに、REST API経由でアクセス可能な
 * プロパティを追加できます。
 */
add_action('rest_api_init', function() {
    // 投稿タイプ 'post' にカスタムプロパティを追加する例
    // register_rest_field('post', 'nya_custom_property', array(
    //     'get_callback' => function($post) {
    //         // プロパティの値を取得
    //         return get_post_meta($post['id'], 'nya_custom_property', true);
    //     },
    //     'update_callback' => function($value, $post) {
    //         // プロパティの値を更新
    //         update_post_meta($post->ID, 'nya_custom_property', $value);
    //     },
    //     'schema' => array(
    //         'type' => 'string',
    //         'description' => 'カスタムプロパティの説明',
    //         'context' => array('view', 'edit'),
    //     ),
    // ));

    // カスタム投稿タイプ 'example' にカスタムプロパティを追加する例
    // register_rest_field('example', 'nya_custom_property', array(
    //     'get_callback' => function($post) {
    //         return get_post_meta($post['id'], 'nya_custom_property', true);
    //     },
    //     'update_callback' => function($value, $post) {
    //         update_post_meta($post->ID, 'nya_custom_property', $value);
    //     },
    //     'schema' => array(
    //         'type' => 'string',
    //         'description' => 'カスタムプロパティの説明',
    //         'context' => array('view', 'edit'),
    //     ),
    // ));
});

/**
 * REST APIの認証エラーを処理
 */
// add_filter('rest_authentication_errors', function($result) {
//     // 認証エラーのカスタマイズ
//     return $result;
// });

/**
 * REST APIエンドポイントをカスタマイズ
 */
// add_filter('rest_endpoints', function($endpoints) {
//     // エンドポイントの追加・削除・変更
//     return $endpoints;
// });

/**
 * 特定の投稿タイプのREST APIレスポンスをカスタマイズ
 */
// add_filter('rest_prepare_post', function($response, $post) {
//     // レスポンスデータのカスタマイズ
//     return $response;
// }, 10, 2);

