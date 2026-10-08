<?php
/**
 * wp-config.php 設定例（本番・ステージング設置用）
 *
 * 使い方:
 *   cp wp-config.sample.php wp-config.php
 *   下記のプレースホルダを実値に書き換える
 *
 * Docker 開発環境では setup.sh が wp-config.php を自動生成するため、
 * このファイルは使わない。本番や共有サーバーへ設置するときに使う。
 *
 * デバッグログは __DIR__/log/debug.log（log/.htaccess で公開拒否済み）
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 */

// ** データベース設定（サーバーパネルの値に合わせる） ** //
define( 'DB_NAME', 'database_name_here' );
define( 'DB_USER', 'username_here' );
define( 'DB_PASSWORD', 'password_here' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

/**
 * MySQL の SSL
 *
 * Docker 開発環境: MYSQL_CLIENT_FLAGS は 0（SSL 無効）
 * 本番で DB が SSL 必須の場合のみ有効化する
 */
// define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL );
// define( 'MYSQL_SSL_CA', '/path/to/ca.pem' );

/**#@+
 * 認証用キーとソルト
 * https://api.wordpress.org/secret-key/1.1/salt/ で生成して置き換える
 */
define( 'AUTH_KEY', 'put your unique phrase here' );
define( 'SECURE_AUTH_KEY', 'put your unique phrase here' );
define( 'LOGGED_IN_KEY', 'put your unique phrase here' );
define( 'NONCE_KEY', 'put your unique phrase here' );
define( 'AUTH_SALT', 'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT', 'put your unique phrase here' );
define( 'NONCE_SALT', 'put your unique phrase here' );
/**#@-*/

$table_prefix = 'wp_';

/**
 * 環境タイプ: local | development | staging | production
 */
define( 'WP_ENVIRONMENT_TYPE', 'production' );

/**
 * デバッグ
 * 公開本番では WP_DEBUG を false にし、画面表示もオフにすること
 */
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', __DIR__ . '/log/debug.log' );
if ( WP_DEBUG ) {
	define( 'WP_DEBUG_DISPLAY', true );
	@ini_set( 'display_errors', 1 );
	define( 'SCRIPT_DEBUG', true );
	// define( 'SAVEQUERIES', true );
}

/* Add any custom values between this line and the "stop editing" line. */

define( 'DISALLOW_FILE_EDIT', true );
define( 'WP_AUTO_UPDATE_CORE', 'minor' );

// define( 'FORCE_SSL_ADMIN', true );
// define( 'WP_HOME', 'https://example.com' );
// define( 'WP_SITEURL', 'https://example.com' );
// define( 'WP_MEMORY_LIMIT', '256M' );

/* That's all, stop editing! Happy publishing. */

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
