<?php
/**
 * Mailpit SMTP設定
 *
 * 開発環境でMailpitにメールを送信するための設定
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * PHPMailerの設定を変更してMailpitに接続
 *
 * @param PHPMailer\PHPMailer\PHPMailer $phpmailer PHPMailerインスタンス
 */
function site_core_configure_mailpit($phpmailer) {
    // 開発環境用: 常にMailpitに接続（本番環境では環境変数で制御可能）
    // 本番環境では、環境変数 WP_USE_MAILPIT を false に設定することで無効化可能

    // 環境変数で無効化されていない場合のみ有効
    $use_mailpit = getenv('WP_USE_MAILPIT');
    if ($use_mailpit === false || $use_mailpit === '' || $use_mailpit === 'true') {
        // SMTPモードに設定
        $phpmailer->isSMTP();

        // Mailpitの設定
        $phpmailer->Host = 'mailpit';
        $phpmailer->Port = 1025;
        $phpmailer->SMTPAuth = false;
        $phpmailer->SMTPSecure = ''; // SSL/TLSを無効化
        $phpmailer->SMTPAutoTLS = false; // 自動TLSを無効化

        // 送信者情報を設定（常に上書き）
        $admin_email = get_option('admin_email');
        if (empty($admin_email) || $admin_email === 'wordpress@localhost' || !is_email($admin_email)) {
            // 無効なメールアドレスの場合、デフォルト値を設定
            $admin_email = 'admin@example.com';
        }
        // Fromアドレスを強制的に設定（既に設定されていても上書き）
        $phpmailer->setFrom($admin_email, get_option('blogname') ?: 'WordPress', false);

        // デバッグモードを有効化（開発環境のみ）
        // WP_DEBUGがfalseでも開発環境として扱う
        $phpmailer->SMTPDebug = 2; // 詳細なデバッグ情報を出力
        $phpmailer->Debugoutput = function($str, $level) {
            if (function_exists('safe_log')) {
                safe_log("PHPMailer Debug: $str", 'debug');
            } else {
                error_log("PHPMailer Debug: $str");
            }
        };

        // デバッグ用ログ
        if (function_exists('safe_log')) {
            safe_log('Mailpit SMTP設定を適用しました', 'info', [
                'host' => $phpmailer->Host,
                'port' => $phpmailer->Port,
                'from' => $phpmailer->From,
                'from_name' => $phpmailer->FromName
            ]);
        }
    }
}
// wp_mailの前にFromアドレスを設定
add_filter('wp_mail', function($args) {
    // Fromアドレスが無効な場合、デフォルト値を設定
    if (empty($args['headers']) || !is_array($args['headers'])) {
        $args['headers'] = [];
    }

    $admin_email = get_option('admin_email');
    if (empty($admin_email) || $admin_email === 'wordpress@localhost' || !is_email($admin_email)) {
        $admin_email = 'admin@example.com';
    }

    // Fromヘッダーを追加（既存のFromヘッダーを上書き）
    $from_header = 'From: ' . $admin_email;
    // 既存のFromヘッダーを削除
    $args['headers'] = array_filter($args['headers'], function($header) {
        return strpos(strtolower($header), 'from:') !== 0;
    });
    // 新しいFromヘッダーを追加
    $args['headers'][] = $from_header;

    return $args;
}, 10, 1);

// 優先度を高くして、他のフックより先に実行
add_action('phpmailer_init', 'site_core_configure_mailpit', 5, 1);

/**
 * wp_mail送信失敗時のエラーログ
 */
add_action('wp_mail_failed', function($wp_error) {
    if (function_exists('safe_log')) {
        safe_log('wp_mail送信失敗', 'error', [
            'error_message' => $wp_error->get_error_message(),
            'error_code' => $wp_error->get_error_code(),
            'error_data' => $wp_error->get_error_data()
        ]);
    } else {
        error_log('wp_mail送信失敗: ' . $wp_error->get_error_message());
    }
});

