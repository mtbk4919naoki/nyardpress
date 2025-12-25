#!/bin/bash
set -euo pipefail

# WordPressの標準エントリーポイントを実行する前に、
# wp core downloadが実行される場合に備えて、--skip-themesオプションを設定
# 環境変数で制御できないため、WordPressの標準エントリーポイントを実行
# その後、twenty系テーマを削除する処理を追加

# wp-adminとwp-includesの所有者とパーミッションを設定
# WordPressの公式イメージでは、これらのディレクトリの所有者がrootになっている場合がある
WP_ADMIN_DIR="/var/www/html/wp-admin"
WP_INCLUDES_DIR="/var/www/html/wp-includes"
WP_ROOT="/var/www/html"

# wp-adminとwp-includesの所有者とパーミッションを変更（再帰的に）
# ディレクトリ: 775、ファイル: 664に設定（chmod()警告を防ぐため）
if [ -d "$WP_ADMIN_DIR" ]; then
    chown -R www-data:www-data "$WP_ADMIN_DIR" 2>/dev/null || true
    find "$WP_ADMIN_DIR" -type d -exec chmod 775 {} \; 2>/dev/null || true
    find "$WP_ADMIN_DIR" -type f -exec chmod 664 {} \; 2>/dev/null || true
    echo "✅ wp-adminディレクトリの所有者とパーミッションを設定しました"
fi
if [ -d "$WP_INCLUDES_DIR" ]; then
    chown -R www-data:www-data "$WP_INCLUDES_DIR" 2>/dev/null || true
    find "$WP_INCLUDES_DIR" -type d -exec chmod 775 {} \; 2>/dev/null || true
    find "$WP_INCLUDES_DIR" -type f -exec chmod 664 {} \; 2>/dev/null || true
    echo "✅ wp-includesディレクトリの所有者とパーミッションを設定しました"
fi

# wp-contentディレクトリはマウントされているため、所有者変更はスキップ
# マウントされていない部分（ewwwディレクトリなど）は個別に処理
WP_CONTENT_DIR="$WP_ROOT/wp-content"

# EWWW Image Optimizer用のディレクトリを事前に作成（コンテナ内なので権限設定可能）
# wp-content/ewwwはマウントされていないため、コンテナ内で作成・権限設定が可能
EWWW_DIR="/var/www/html/wp-content/ewww"
EWWW_BINARIES_DIR="$EWWW_DIR/binaries"
if [ ! -d "$EWWW_DIR" ]; then
    mkdir -p "$EWWW_DIR"
fi
if [ ! -d "$EWWW_BINARIES_DIR" ]; then
    mkdir -p "$EWWW_BINARIES_DIR"
fi
# 所有者をwww-dataに変更（WordPressが書き込めるように）
chown -R www-data:www-data "$EWWW_DIR" 2>/dev/null || true
chmod -R 755 "$EWWW_DIR" 2>/dev/null || true

# システムにインストールされたツールへのシンボリックリンクを作成
# EWWWはシステムのツールを使用できるように設定
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

# WordPressの標準エントリーポイントを実行（wp-config.phpの生成など）
# 注意: WordPressの公式イメージは、/var/www/htmlが空の場合にwp core downloadを実行します
# その際、--skip-themesオプションは使えないため、後で削除します
docker-entrypoint.sh "$@" &
WP_PID=$!

# WordPressの標準エントリーポイントでwp core downloadが実行された場合、
# wp-adminとwp-includesの所有者がrootになっている可能性があるため、再度パーミッションを設定
sleep 3
# wp core download実行後のパーミッション設定
if [ -d "$WP_ADMIN_DIR" ]; then
    chown -R www-data:www-data "$WP_ADMIN_DIR" 2>/dev/null || true
    find "$WP_ADMIN_DIR" -type d -exec chmod 775 {} \; 2>/dev/null || true
    find "$WP_ADMIN_DIR" -type f -exec chmod 664 {} \; 2>/dev/null || true
fi
if [ -d "$WP_INCLUDES_DIR" ]; then
    chown -R www-data:www-data "$WP_INCLUDES_DIR" 2>/dev/null || true
    find "$WP_INCLUDES_DIR" -type d -exec chmod 775 {} \; 2>/dev/null || true
    find "$WP_INCLUDES_DIR" -type f -exec chmod 664 {} \; 2>/dev/null || true
fi
if [ -f "$WP_ROOT/wp-config.php" ]; then
    chown www-data:www-data "$WP_ROOT/wp-config.php" 2>/dev/null || true
    chmod 640 "$WP_ROOT/wp-config.php" 2>/dev/null || true
fi

# データベース接続情報を環境変数から取得
DB_HOST="${WORDPRESS_DB_HOST:-db}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpassword}"

# データベースが準備できるまで待機
echo "データベース接続を待機中..."
max_attempts=60
attempt=0
db_connected=false

while [ $attempt -lt $max_attempts ]; do
    # MySQLが起動しているか確認（TCP接続を試行）
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/3306" 2>/dev/null; then
        # MySQLに接続を試行（rootユーザーで、TLSを無効化）
        if mysql -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl -e "SELECT 1" 2>/dev/null; then
            echo "データベース接続が確認できました"
            # データベースが存在しない場合は作成（TLSを無効化）
            mysql -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null || true
            # ユーザーが存在しない場合は作成
            mysql -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';" 2>/dev/null || true
            mysql -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';" 2>/dev/null || true
            mysql -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl -e "FLUSH PRIVILEGES;" 2>/dev/null || true
            # 通常ユーザーで接続を確認
            if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --skip-ssl -e "USE $DB_NAME; SELECT 1" 2>/dev/null; then
                echo "データベースユーザーでの接続が確認できました"
                db_connected=true
                break
            fi
        fi
    fi
    sleep 2
    attempt=$((attempt + 1))
    if [ $((attempt % 5)) -eq 0 ]; then
        echo "データベース接続を待機中... (${attempt}/${max_attempts})"
    fi
done

if [ "$db_connected" = false ]; then
    echo "⚠️  データベース接続が確立できませんでしたが、setup.shを実行します"
fi

# wp-config.phpが生成されるまで少し待機
echo "wp-config.phpの生成を待機中..."
for i in {1..30}; do
    if [ -f /var/www/html/wp-config.php ]; then
        echo "wp-config.phpが生成されました"
        break
    fi
    sleep 1
done

# WordPressの標準エントリーポイントでwp core downloadが実行された場合、
# twenty系テーマとデフォルトプラグインがダウンロードされる可能性があるため、削除する
# この処理はsetup.shの実行前後に関係なく実行する

# デフォルトテーマ（twenty*系）を削除
echo "デフォルトテーマ（twenty*系）を削除中..."
THEMES_DIR="/var/www/html/wp-content/themes"
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
fi

# デフォルトプラグイン（Akismet、HelloDolly）を削除
echo "デフォルトプラグイン（Akismet、HelloDolly）を削除中..."
PLUGINS_DIR="/var/www/html/wp-content/plugins"
if [ -d "$PLUGINS_DIR" ]; then
    # Akismetプラグインを削除
    if [ -d "$PLUGINS_DIR/akismet" ]; then
        echo "  削除中: akismet"
        rm -rf "$PLUGINS_DIR/akismet" || echo "  ⚠️  akismetの削除に失敗しました"
    fi

    # HelloDollyプラグインを削除
    if [ -f "$PLUGINS_DIR/hello.php" ]; then
        echo "  削除中: hello-dolly"
        rm -f "$PLUGINS_DIR/hello.php" || echo "  ⚠️  hello-dollyの削除に失敗しました"
    fi
    echo "✅ デフォルトプラグインの削除が完了しました"
fi

# setup.shを実行（初回起動時のみ）
# WordPressのインストール状態を直接確認（wp core is-installedで判定）
if [ -f /usr/docker/bin/setup.sh ]; then
    # WordPressのインストール状態を確認（データベース接続が必要）
    # wp-config.phpが存在し、WordPressがインストール済みか確認
    if [ -f /var/www/html/wp-config.php ]; then
        # wp core is-installedで判定（データベース接続が必要なので、接続確認後に実行）
        if wp core is-installed --allow-root --path="/var/www/html" 2>/dev/null; then
            echo "ℹ️  WordPressは既にインストール済みです"
            # 日本語化の処理だけは毎回実行（再起動時に英語に戻るのを防ぐ）
            echo "日本語言語パックを設定中..."
            # データベース接続を確認してから実行
            if wp core is-installed --allow-root --path="/var/www/html" 2>/dev/null; then
                # 日本語パックをインストール（既にインストール済みの場合は更新）
                wp language core install ja --allow-root --path="/var/www/html" 2>&1 | grep -v "already installed" || true
                # サイトの言語を日本語に切り替え（非推奨のactivateの代わり）
                wp site switch-language ja --allow-root --path="/var/www/html" 2>&1 || {
                    # フォールバック: 古いコマンドを使用
                    wp language core activate ja --allow-root --path="/var/www/html" 2>&1 || true
                }
                # WPLANGオプションも明示的に設定
                wp option update WPLANG ja --allow-root --path="/var/www/html" 2>&1 || true
                # 管理ユーザーの言語設定も日本語に変更
                ADMIN_USER="${WORDPRESS_ADMIN_USER:-nyardpress}"
                ADMIN_USER_ID=$(wp user get "$ADMIN_USER" --allow-root --path="/var/www/html" --field=ID 2>/dev/null || echo "")
                if [ -n "$ADMIN_USER_ID" ]; then
                    wp user update "$ADMIN_USER" --locale=ja --allow-root --path="/var/www/html" 2>&1 || true
                    wp user meta update "$ADMIN_USER_ID" locale ja --allow-root --path="/var/www/html" 2>&1 || true
                fi
                echo "✅ 日本語言語パックを設定しました"
            else
                echo "⚠️  データベース接続が確立されていないため、日本語化をスキップします"
            fi
        else
            echo "=========================================="
            echo "🚀 WordPressが未インストールのため、setup.shを実行中..."
            echo "=========================================="
            set +e  # エラーで停止しないようにする
            /usr/docker/bin/setup.sh
            setup_exit_code=$?
            set -e
            if [ $setup_exit_code -eq 0 ]; then
                echo "=========================================="
                echo "✅ setup.shの実行が完了しました"
                echo "=========================================="
            else
                echo "=========================================="
                echo "⚠️  setup.shの実行に失敗しました (終了コード: $setup_exit_code)"
                echo "   次回起動時に再試行されます"
                echo "=========================================="
            fi
        fi
    else
        # wp-config.phpが存在しない場合は、確実に未インストール
        echo "=========================================="
        echo "🚀 WordPressが未インストールのため、setup.shを実行中..."
        echo "=========================================="
        set +e  # エラーで停止しないようにする
        /usr/docker/bin/setup.sh
        setup_exit_code=$?
        set -e
        if [ $setup_exit_code -eq 0 ]; then
            echo "=========================================="
            echo "✅ setup.shの実行が完了しました"
            echo "=========================================="
        else
            echo "=========================================="
            echo "⚠️  setup.shの実行に失敗しました (終了コード: $setup_exit_code)"
            echo "   次回起動時に再試行されます"
            echo "=========================================="
        fi
    fi
else
    echo "❌ setup.shが見つかりません: /usr/docker/bin/setup.sh"
    echo "利用可能なファイル:"
    ls -la /usr/docker/bin/ 2>/dev/null || echo "ディレクトリが存在しません"
fi

# フォアグラウンドプロセスを待機
wait $WP_PID

