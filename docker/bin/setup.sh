#!/bin/bash
# ==============================================
# WordPressの初回インストール処理
#
# - wp-config.php の自動生成
# - WordPress のインストール
# - デバッグ設定の追加
# - プラグイン・テーマのアクティベート
# 注意: パーマリンク、日本語化はpost-setup.shで実行されます
# ========================================

set -uo pipefail
# 注意: set -e を外しています（エラーが発生してもスクリプトを続行）
# 各コマンドで明示的にエラーハンドリングを行います

# WordPressのドキュメントルート
WP_ROOT="/var/www/html"

# Composer installはホスト側で実行する前提
# プラグイン、テーマ、MUプラグインは既にインストールされていることを想定

# データベース接続情報を環境変数から取得
DB_HOST="${WORDPRESS_DB_HOST:-db}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpassword}"

# データベース接続を確認
echo "データベース接続を確認中..."
max_db_attempts=30
db_attempt=0
db_connected=false

while [ $db_attempt -lt $max_db_attempts ]; do
    # TCP接続を先に確認
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/3306" 2>/dev/null; then
        # MySQL接続を試行（TLSを無効化）
        if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --skip-ssl -e "USE $DB_NAME; SELECT 1" 2>/dev/null; then
            echo "データベース接続が確認できました"
            db_connected=true
            break
        fi
    fi
    sleep 2
    db_attempt=$((db_attempt + 1))
    if [ $((db_attempt % 5)) -eq 0 ]; then
        echo "データベース接続を待機中... (${db_attempt}/${max_db_attempts})"
    fi
done

if [ "$db_connected" = false ]; then
    echo "⚠️  データベース接続が確立できませんでしたが、続行します"
fi

# WordPressがインストールされているか確認
echo "WordPressのインストール状態を確認中..."
if ! wp core is-installed --allow-root --path="$WP_ROOT" 2>/dev/null; then
    echo "WordPressは未インストールです。初期インストールを開始します..."

    # wp-config.phpが存在しない場合は生成、存在する場合はデータベース接続情報を更新
    if [ ! -f "$WP_ROOT/wp-config.php" ]; then
        echo "wp-config.phpを生成中..."
        wp config create \
            --dbname="$DB_NAME" \
            --dbuser="$DB_USER" \
            --dbpass="$DB_PASSWORD" \
            --dbhost="$DB_HOST" \
            --allow-root \
            --path="$WP_ROOT" \
            --skip-check || {
            echo "❌ wp-config.phpの生成に失敗しました"
            exit 1
        }
        echo "✅ wp-config.phpを生成しました"
    else
        echo "wp-config.phpは既に存在します。データベース接続情報を確認中..."
        # getenv_docker関数を使っている場合、wp config setでは更新できない
        # そのため、wp-config.phpを直接編集するか、再生成する
        # まず、現在のDB_HOSTを確認
        current_db_host=$(wp config get DB_HOST --allow-root --path="$WP_ROOT" 2>/dev/null || echo "")
        if [ "$current_db_host" != "$DB_HOST" ]; then
            echo "DB_HOSTが正しく設定されていません（現在: $current_db_host, 期待: $DB_HOST）"
            echo "wp-config.phpを再生成します..."
            # バックアップを取る
            cp "$WP_ROOT/wp-config.php" "$WP_ROOT/wp-config.php.bak" 2>/dev/null || true
            # wp-config.phpを削除して再生成
            rm -f "$WP_ROOT/wp-config.php"
            wp config create \
                --dbname="$DB_NAME" \
                --dbuser="$DB_USER" \
                --dbpass="$DB_PASSWORD" \
                --dbhost="$DB_HOST" \
                --allow-root \
                --path="$WP_ROOT" \
                --skip-check || {
                echo "❌ wp-config.phpの再生成に失敗しました"
                # バックアップから復元
                mv "$WP_ROOT/wp-config.php.bak" "$WP_ROOT/wp-config.php" 2>/dev/null || true
                exit 1
            }
            echo "✅ wp-config.phpを再生成しました"
        else
            echo "✅ データベース接続情報は正しく設定されています"
        fi
    fi

    # wp-config.phpが存在することを確認
    if [ ! -f "$WP_ROOT/wp-config.php" ]; then
        echo "❌ エラー: wp-config.phpが生成されませんでした"
        exit 1
    fi

    # wp-config.phpのパーミッションはinit.shで設定されるため、ここではスキップ

    # Mailpit設定はMUプラグイン（site-core/mail/mailpit.php）で管理
    echo "✅ Mailpit設定はMUプラグインで管理されます"

    # 開発環境用のデバッグ設定を追加
    echo "開発環境用のデバッグ設定を追加中..."
    wp config set WP_DEBUG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUGの設定に失敗しました"
    wp config set WP_DEBUG_DISPLAY true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_DISPLAYの設定に失敗しました"
    wp config set WP_DEBUG_LOG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_LOGの設定に失敗しました"
    wp config set WP_DEBUG_LOG_FILE "$WP_ROOT/wp-content/debug.log" --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_LOG_FILEの設定に失敗しました"
    wp config set SCRIPT_DEBUG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  SCRIPT_DEBUGの設定に失敗しました"

    # WordPressのアップデート時にデフォルトテーマが再インストールされるのを防ぐ
    if ! wp config has CORE_UPGRADE_SKIP_NEW_BUNDLED --allow-root --path="$WP_ROOT" 2>/dev/null; then
        wp config set CORE_UPGRADE_SKIP_NEW_BUNDLED true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  CORE_UPGRADE_SKIP_NEW_BUNDLEDの設定に失敗しました"
    fi


    # PHPエラーログをdocker/logディレクトリと標準出力の両方に出力するように設定
    # wp-config.phpに直接追加
    if ! grep -q "ini_set('log_errors', 1)" "$WP_ROOT/wp-config.php"; then
        echo "" >> "$WP_ROOT/wp-config.php"
        echo "/* 開発環境用: PHPエラーログをdocker/logディレクトリと標準出力にも出力 */" >> "$WP_ROOT/wp-config.php"
        echo "if (WP_DEBUG) {" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('log_errors', 1);" >> "$WP_ROOT/wp-config.php"
        echo "    // docker/logディレクトリに出力" >> "$WP_ROOT/wp-config.php"
        echo "    \$log_dir = ABSPATH . 'docker/log';" >> "$WP_ROOT/wp-config.php"
        echo "    if (!file_exists(\$log_dir)) {" >> "$WP_ROOT/wp-config.php"
        echo "        wp_mkdir_p(\$log_dir);" >> "$WP_ROOT/wp-config.php"
        echo "    }" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('error_log', \$log_dir . '/php-error.log');" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('display_errors', 1);" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('display_startup_errors', 1);" >> "$WP_ROOT/wp-config.php"
        echo "    error_reporting(E_ALL);" >> "$WP_ROOT/wp-config.php"
        echo "}" >> "$WP_ROOT/wp-config.php"
        echo "✅ デバッグ設定を追加しました"
    else
        echo "✅ デバッグ設定は既に追加されています"
    fi

    # WordPressをインストール
    # 環境変数から管理ユーザー情報を取得（docker-compose.ymlから設定される）
    ADMIN_USER="${WORDPRESS_ADMIN_USER:-admin}"
    ADMIN_PASSWORD="${WORDPRESS_ADMIN_PASSWORD:-admin}"
    ADMIN_EMAIL="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}"

    echo "WordPressをインストール中..."
    echo "  URL: ${WORDPRESS_URL:-http://localhost:8080}"
    echo "  タイトル: ${WORDPRESS_TITLE:-Nyardpress}"
    echo "  管理者ユーザー: $ADMIN_USER"
    echo "  管理者メール: $ADMIN_EMAIL"

    if wp core install \
        --url="${WORDPRESS_URL:-http://localhost:8080}" \
        --title="${WORDPRESS_TITLE:-Nyardpress}" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$ADMIN_EMAIL" \
        --allow-root \
        --path="$WP_ROOT" 2>&1; then
        echo "✅ WordPressのインストールが完了しました"
    else
        echo "❌ WordPressのインストールに失敗しました"
        echo "エラー詳細を確認してください"
        # インストール状態を再確認
        if wp core is-installed --allow-root --path="$WP_ROOT" 2>/dev/null; then
            echo "⚠️  ただし、WordPressは既にインストールされているようです"
        else
            exit 1
        fi
    fi
else
    echo "✅ WordPressは既にインストールされています"

    # 既存インストールの場合でも、管理ユーザー情報を環境変数に合わせて更新
    echo "管理ユーザー情報を確認中..."
    ADMIN_USER="${WORDPRESS_ADMIN_USER:-admin}"
    ADMIN_PASSWORD="${WORDPRESS_ADMIN_PASSWORD:-admin}"
    ADMIN_EMAIL="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}"

    # 管理ユーザーが存在するか確認
    if wp user get "$ADMIN_USER" --allow-root --path="$WP_ROOT" --field=ID 2>/dev/null; then
        echo "管理ユーザー '$ADMIN_USER' が存在します。パスワードとメールアドレスを更新中..."
        # パスワードを更新
        wp user update "$ADMIN_USER" --user_pass="$ADMIN_PASSWORD" --allow-root --path="$WP_ROOT" 2>/dev/null || echo "⚠️  パスワードの更新に失敗しました"
        # メールアドレスを更新
        wp user update "$ADMIN_USER" --user_email="$ADMIN_EMAIL" --allow-root --path="$WP_ROOT" 2>/dev/null || echo "⚠️  メールアドレスの更新に失敗しました"
        echo "✅ 管理ユーザー情報を更新しました"
    else
        # 既存のadminユーザーが存在する場合、削除して新しいユーザーを作成
        if wp user get "admin" --allow-root --path="$WP_ROOT" --field=ID 2>/dev/null && [ "$ADMIN_USER" != "admin" ]; then
            echo "既存の'admin'ユーザーを削除して、新しいユーザー '$ADMIN_USER' を作成中..."
            wp user delete admin --reassign=1 --allow-root --path="$WP_ROOT" 2>/dev/null || echo "⚠️  既存のadminユーザーの削除に失敗しました"
        fi

        echo "管理ユーザー '$ADMIN_USER' を作成中..."
        # 管理ユーザーを作成（管理者権限付き）
        wp user create "$ADMIN_USER" "$ADMIN_EMAIL" --user_pass="$ADMIN_PASSWORD" --role=administrator --allow-root --path="$WP_ROOT" 2>/dev/null || {
            echo "⚠️  管理ユーザーの作成に失敗しました。既存ユーザーのパスワードを更新します..."
            # 作成に失敗した場合（既に存在する場合など）、パスワードのみ更新
            wp user update "$ADMIN_USER" --user_pass="$ADMIN_PASSWORD" --user_email="$ADMIN_EMAIL" --allow-root --path="$WP_ROOT" 2>/dev/null || echo "⚠️  パスワードの更新にも失敗しました"
        }
    fi

    # 既存のwp-config.phpにもデバッグ設定を追加（存在しない場合）
    if [ -f "$WP_ROOT/wp-config.php" ]; then
        echo "既存のwp-config.phpにデバッグ設定を確認中..."
        if ! wp config has WP_DEBUG --allow-root --path="$WP_ROOT" 2>/dev/null; then
            echo "開発環境用のデバッグ設定を追加中..."
            wp config set WP_DEBUG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUGの設定に失敗しました"
            wp config set WP_DEBUG_DISPLAY true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_DISPLAYの設定に失敗しました"
            wp config set WP_DEBUG_LOG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_LOGの設定に失敗しました"
            wp config set WP_DEBUG_LOG_FILE "$WP_ROOT/wp-content/debug.log" --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_LOG_FILEの設定に失敗しました"
            wp config set SCRIPT_DEBUG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  SCRIPT_DEBUGの設定に失敗しました"

            # PHPエラーログをdocker/logディレクトリと標準出力の両方に出力するように設定
            if ! grep -q "ini_set('log_errors', 1)" "$WP_ROOT/wp-config.php"; then
                echo "" >> "$WP_ROOT/wp-config.php"
                echo "/* 開発環境用: PHPエラーログをdocker/logディレクトリと標準出力にも出力 */" >> "$WP_ROOT/wp-config.php"
                echo "if (WP_DEBUG) {" >> "$WP_ROOT/wp-config.php"
                echo "    ini_set('log_errors', 1);" >> "$WP_ROOT/wp-config.php"
                echo "    // docker/logディレクトリに出力" >> "$WP_ROOT/wp-config.php"
                echo "    \$log_dir = ABSPATH . 'docker/log';" >> "$WP_ROOT/wp-config.php"
                echo "    if (!file_exists(\$log_dir)) {" >> "$WP_ROOT/wp-config.php"
                echo "        wp_mkdir_p(\$log_dir);" >> "$WP_ROOT/wp-config.php"
                echo "    }" >> "$WP_ROOT/wp-config.php"
                echo "    ini_set('error_log', \$log_dir . '/php-error.log');" >> "$WP_ROOT/wp-config.php"
                echo "    ini_set('display_errors', 1);" >> "$WP_ROOT/wp-config.php"
                echo "    ini_set('display_startup_errors', 1);" >> "$WP_ROOT/wp-config.php"
                echo "    error_reporting(E_ALL);" >> "$WP_ROOT/wp-config.php"
                echo "}" >> "$WP_ROOT/wp-config.php"
            fi
            echo "✅ デバッグ設定を追加しました"
        else
            echo "✅ デバッグ設定は既に有効です"
        fi

    fi
fi

# WordPressがインストールされている場合、設定を実行
if wp core is-installed --allow-root --path="$WP_ROOT" 2>/dev/null; then
    echo "WordPressの設定を開始します..."

    # 初期化処理はinit.shで実行されるため、ここではプラグインとテーマの処理のみ実行

    # 標準プラグインのアクティベート
    # プラグインはComposerでインストール済みなので、アクティベートのみ実行
    # 注意: プラグインの日本語化はpost-setup.shで実行されます
    /usr/docker/bin/setup-plugin.sh "$WP_ROOT"

    # テーマをアクティベート
    THEME_NAME="${THEME_NAME:-nyardpress}"
    echo "${THEME_NAME}テーマをアクティベート中..."
    wp theme activate "$THEME_NAME" --allow-root --path="$WP_ROOT" || echo "${THEME_NAME}テーマのアクティベートに失敗しました（テーマが存在しない可能性があります）"

    echo "WordPressの設定が完了しました"
else
    echo "WordPressのインストールに失敗しました。手動でインストールしてください。"
fi
