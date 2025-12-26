#!/bin/bash
# ==============================================
# wp-config.phpの初期化を行います
#
# - wp-config.php の自動生成
# - WordPress のインストールと初期設定（パーマリンク、日本語化など）
# - Carbon Fieldsのインストールと有効化
# - よく使うプラグインのインストールと有効化
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

    # wp-config.phpのパーミッションを640に設定（セキュリティのため）
    chown www-data:www-data "$WP_ROOT/wp-config.php" 2>/dev/null || true
    chmod 640 "$WP_ROOT/wp-config.php" 2>/dev/null || true

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

    # wp-adminとwp-includesのパーミッションを適切に設定（chmod()警告を防ぐため）
    echo "wp-adminとwp-includesのパーミッションを設定中..."
    if [ -d "$WP_ROOT/wp-admin" ]; then
        chown -R www-data:www-data "$WP_ROOT/wp-admin" 2>/dev/null || true
        find "$WP_ROOT/wp-admin" -type d -exec chmod 775 {} \; 2>/dev/null || true
        find "$WP_ROOT/wp-admin" -type f -exec chmod 664 {} \; 2>/dev/null || true
    fi
    if [ -d "$WP_ROOT/wp-includes" ]; then
        chown -R www-data:www-data "$WP_ROOT/wp-includes" 2>/dev/null || true
        find "$WP_ROOT/wp-includes" -type d -exec chmod 775 {} \; 2>/dev/null || true
        find "$WP_ROOT/wp-includes" -type f -exec chmod 664 {} \; 2>/dev/null || true
    fi
    # wp-config.phpのパーミッションを640に設定（セキュリティのため）
    if [ -f "$WP_ROOT/wp-config.php" ]; then
        chown www-data:www-data "$WP_ROOT/wp-config.php" 2>/dev/null || true
        chmod 640 "$WP_ROOT/wp-config.php" 2>/dev/null || true
    fi
    echo "✅ パーミッション設定が完了しました"

    # パーマリンク構造を設定
    echo "パーマリンク構造を設定中..."
    wp rewrite structure '/%postname%/' --allow-root --path="$WP_ROOT" || echo "パーマリンク構造の設定に失敗しました"
    wp rewrite flush --allow-root --path="$WP_ROOT" || echo "パーマリンクのフラッシュに失敗しました"

    # 日本語言語パックのインストールとアクティベート（毎回実行）
    echo "日本語言語パックを設定中..."
    wp language core install ja --allow-root --path="$WP_ROOT" 2>&1 | grep -v "already installed" || true
    # サイトの言語を日本語に切り替え（非推奨のactivateの代わり）
    wp site switch-language ja --allow-root --path="$WP_ROOT" 2>&1 || {
        # フォールバック: 古いコマンドを使用
        wp language core activate ja --allow-root --path="$WP_ROOT" 2>&1 || true
    }
    # WPLANGオプションも明示的に設定
    wp option update WPLANG ja --allow-root --path="$WP_ROOT" 2>&1 || true
    # 管理ユーザーの言語設定も日本語に変更
    ADMIN_USER="${WORDPRESS_ADMIN_USER:-nyardpress}"
    ADMIN_USER_ID=$(wp user get "$ADMIN_USER" --allow-root --path="$WP_ROOT" --field=ID 2>/dev/null || echo "")
    if [ -n "$ADMIN_USER_ID" ]; then
        wp user update "$ADMIN_USER" --locale=ja --allow-root --path="$WP_ROOT" 2>&1 || true
        wp user meta update "$ADMIN_USER_ID" locale ja --allow-root --path="$WP_ROOT" 2>&1 || true
    fi
    echo "✅ 日本語言語パックを設定しました"

    # EWWW Image Optimizer用のディレクトリを作成・権限設定
    # wp-content/ewwwはマウントされていないため、コンテナ内で作成・権限設定が可能
    echo "EWWW Image Optimizer用のディレクトリを準備中..."
    EWWW_DIR="$WP_ROOT/wp-content/ewww"
    EWWW_BINARIES_DIR="$EWWW_DIR/binaries"
    if [ ! -d "$EWWW_DIR" ]; then
        mkdir -p "$EWWW_DIR"
        echo "✅ EWWWディレクトリを作成しました: $EWWW_DIR"
    fi
    if [ ! -d "$EWWW_BINARIES_DIR" ]; then
        mkdir -p "$EWWW_BINARIES_DIR"
        echo "✅ EWWW binariesディレクトリを作成しました: $EWWW_BINARIES_DIR"
    fi
    # 所有者をwww-dataに変更（WordPressが書き込めるように）
    chown -R www-data:www-data "$EWWW_DIR" 2>/dev/null || echo "⚠️  所有者の変更に失敗しました"
    chmod -R 755 "$EWWW_DIR" 2>/dev/null || echo "⚠️  権限の変更に失敗しました"

    # W3 Total Cache用のディレクトリを作成・権限設定
    # wp-content/cacheとwp-content/w3tc-configはマウントされていないため、コンテナ内で作成・権限設定が可能
    echo "W3 Total Cache用のディレクトリを準備中..."
    W3TC_CACHE_DIR="$WP_ROOT/wp-content/cache"
    W3TC_CONFIG_DIR="$WP_ROOT/wp-content/w3tc-config"
    W3TC_TMP_DIR="$W3TC_CACHE_DIR/tmp"
    if [ ! -d "$W3TC_CACHE_DIR" ]; then
        mkdir -p "$W3TC_CACHE_DIR"
        echo "✅ W3TC cacheディレクトリを作成しました: $W3TC_CACHE_DIR"
    fi
    if [ ! -d "$W3TC_CONFIG_DIR" ]; then
        mkdir -p "$W3TC_CONFIG_DIR"
        echo "✅ W3TC configディレクトリを作成しました: $W3TC_CONFIG_DIR"
    fi
    if [ ! -d "$W3TC_TMP_DIR" ]; then
        mkdir -p "$W3TC_TMP_DIR"
        echo "✅ W3TC tmpディレクトリを作成しました: $W3TC_TMP_DIR"
    fi
    # 所有者をwww-dataに変更（WordPressが書き込めるように）
    chown -R www-data:www-data "$W3TC_CACHE_DIR" 2>/dev/null || echo "⚠️  W3TC cache所有者の変更に失敗しました"
    chown -R www-data:www-data "$W3TC_CONFIG_DIR" 2>/dev/null || echo "⚠️  W3TC config所有者の変更に失敗しました"
    chmod -R 755 "$W3TC_CACHE_DIR" 2>/dev/null || echo "⚠️  W3TC cache権限の変更に失敗しました"
    chmod -R 755 "$W3TC_CONFIG_DIR" 2>/dev/null || echo "⚠️  W3TC config権限の変更に失敗しました"

    # システムにインストールされたツールへのシンボリックリンクを作成
    if [ -f /usr/bin/jpegtran ]; then
        ln -sf /usr/bin/jpegtran "$EWWW_BINARIES_DIR/jpegtran-linux" 2>/dev/null || true
    fi
    if [ -f /usr/bin/optipng ]; then
        ln -sf /usr/bin/optipng "$EWWW_BINARIES_DIR/optipng-linux" 2>/dev/null || true
    fi
    if [ -f /usr/bin/gifsicle ]; then
        ln -sf /usr/bin/gifsicle "$EWWW_BINARIES_DIR/gifsicle-linux" 2>/dev/null || true
    fi
    if [ -f /usr/bin/cwebp ]; then
        ln -sf /usr/bin/cwebp "$EWWW_BINARIES_DIR/cwebp-linux" 2>/dev/null || true
    fi

    echo "✅ EWWWディレクトリを準備しました: $EWWW_DIR"

    # デフォルトプラグイン（Akismet、HelloDolly）を先に削除
    echo "デフォルトプラグインを削除中..."
    PLUGINS_DIR="$WP_ROOT/wp-content/plugins"
    if [ -d "$PLUGINS_DIR" ]; then
        # Akismetプラグインを削除
        if [ -d "$PLUGINS_DIR/akismet" ] || wp plugin is-installed akismet --allow-root --path="$WP_ROOT" 2>/dev/null; then
            echo "  - akismetを削除中..."
            wp plugin delete akismet --allow-root --path="$WP_ROOT" 2>/dev/null || rm -rf "$PLUGINS_DIR/akismet" 2>/dev/null || echo "    ⚠️  akismetの削除に失敗しました"
        fi

        # HelloDollyプラグインを削除
        if [ -f "$PLUGINS_DIR/hello.php" ] || wp plugin is-installed hello --allow-root --path="$WP_ROOT" 2>/dev/null; then
            echo "  - hello-dollyを削除中..."
            wp plugin delete hello --allow-root --path="$WP_ROOT" 2>/dev/null || rm -f "$PLUGINS_DIR/hello.php" 2>/dev/null || echo "    ⚠️  hello-dollyの削除に失敗しました"
        fi
        echo "✅ デフォルトプラグインの削除が完了しました"
    fi

    # 標準プラグインのアクティベートと日本語化
    # プラグインはComposerでインストール済み（setup.shの最初で実行）なので、アクティベートと日本語化のみ実行
    echo ""
    echo "標準プラグインをアクティベート・日本語化中..."

    # プラグインリストを定義（インストール順序を考慮）
    # 依存関係や初期設定が必要なプラグインを先に配置
    PLUGINS=(
        "wp-multibyte-patch"          # 日本語対応の基本プラグイン（最優先）
        "wordpress-seo"                # SEOプラグイン
        "taxonomy-terms-order"         # タクソノミー順序
        "simple-page-ordering"        # ページ順序
        "wp-crontrol"                  #  Cron管理
        "query-monitor"                # デバッグツール
        "wordpress-importer"           # インポートツール（アクティベート）
        # "wp-mail-smtp"                # メール送信
        # "w3-total-cache"               # キャッシュプラグイン
        # "ewww-image-optimizer"        # 画像最適化
        # "cloudsecure-wp-security"      # セキュリティプラグイン
        # "updraftplus"                  # バックアップ（日本語化のみ）
        # "all-in-one-wp-migration"      # 移行ツール（日本語化のみ）
        # "redirection"                  # リダイレクト（日本語化のみ）
    )

    # 日本語化のみ実施するプラグイン（アクティベートしない）
    PLUGINS_LOCALIZE_ONLY=(
        "updraftplus"
        "all-in-one-wp-migration"
        "redirection"
    )

    # 各プラグインをアクティベートし、日本語化
    for plugin in "${PLUGINS[@]}"; do
        echo "  - $plugin"
        # プラグインがインストールされているか確認
        if wp plugin is-installed "$plugin" --allow-root --path="$WP_ROOT" 2>/dev/null; then
            # アクティベート（既にアクティブでない場合）
            if wp plugin activate "$plugin" --allow-root --path="$WP_ROOT" 2>/dev/null; then
                echo "    ✅ $pluginをアクティベートしました"
            else
                # 既にアクティブな場合はスキップ
                if wp plugin is-active "$plugin" --allow-root --path="$WP_ROOT" 2>/dev/null; then
                    echo "    ℹ️  $pluginは既にアクティブです"
                else
                    echo "    ⚠️  $pluginのアクティベートに失敗しました"
                fi
            fi

            # プラグインの日本語化（毎回実行）
            echo "    日本語言語パックをインストール中..."
            wp language plugin install "$plugin" ja --allow-root --path="$WP_ROOT" 2>&1 | grep -v "already installed" || true
            wp language plugin update "$plugin" --allow-root --path="$WP_ROOT" 2>&1 || true
        else
            echo "    ⚠️  $pluginがインストールされていません（Composer installを確認してください）"
        fi
    done

    echo ""
    echo "✅ 標準プラグインのアクティベート・日本語化が完了しました"

    # 日本語化のみ実施するプラグイン（アクティベートしない）
    if [ ${#PLUGINS_LOCALIZE_ONLY[@]} -gt 0 ]; then
        echo ""
        echo "日本語化のみ実施するプラグインを処理中..."
        for plugin in "${PLUGINS_LOCALIZE_ONLY[@]}"; do
            echo "  - $plugin（日本語化のみ）"
            # プラグインがインストールされているか確認
            if wp plugin is-installed "$plugin" --allow-root --path="$WP_ROOT" 2>/dev/null; then
                # プラグインの日本語化（毎回実行）
                echo "    日本語言語パックをインストール中..."
                wp language plugin install "$plugin" ja --allow-root --path="$WP_ROOT" 2>&1 | grep -v "already installed" || true
                wp language plugin update "$plugin" --allow-root --path="$WP_ROOT" 2>&1 || true
                echo "    ✅ $pluginの日本語化が完了しました"
            else
                echo "    ⚠️  $pluginがインストールされていません（Composer installを確認してください）"
            fi
        done
        echo ""
        echo "✅ 日本語化のみ実施するプラグインの処理が完了しました"
    fi

    # テーマをアクティベート
    THEME_NAME="${THEME_NAME:-nyardpress}"
    echo "${THEME_NAME}テーマをアクティベート中..."
    wp theme activate "$THEME_NAME" --allow-root --path="$WP_ROOT" || echo "${THEME_NAME}テーマのアクティベートに失敗しました（テーマが存在しない可能性があります）"

    # デフォルトテーマ（twenty*系）を削除
    # マウントポイントでは、ホスト側に存在するディレクトリは保持され、存在しないディレクトリ（コンテナ内で作成されたもの）のみ削除される
    echo "デフォルトテーマ（twenty*系）を削除中..."
    THEMES_DIR="$WP_ROOT/wp-content/themes"
    if [ -d "$THEMES_DIR" ]; then
        # twenty*で始まるテーマディレクトリを検索して削除
        find "$THEMES_DIR" -maxdepth 1 -type d -name "twenty*" 2>/dev/null | while IFS= read -r theme_dir; do
            if [ -n "$theme_dir" ] && [ -d "$theme_dir" ]; then
                theme_basename=$(basename "$theme_dir")
                echo "  削除中: $theme_basename"
                rm -rf "$theme_dir" || echo "  ⚠️  $theme_basenameの削除に失敗しました"
            fi
        done || true
        echo "✅ デフォルトテーマの削除が完了しました"
    else
        echo "⚠️  テーマディレクトリが見つかりません: $THEMES_DIR"
    fi

    echo "WordPressの設定が完了しました"
else
    echo "WordPressのインストールに失敗しました。手動でインストールしてください。"
fi
