#!/bin/bash
set -euo pipefail

WP_ROOT="/var/www/html"

# WordPressの標準エントリーポイントを実行（wp-config.phpの生成など）
# 注意: WordPressの公式イメージは、/var/www/htmlが空の場合にwp core downloadを実行します
# その際、--skip-themesオプションは使えないため、後で削除します
docker-entrypoint.sh "$@" &
WP_PID=$!

# WordPressの標準エントリーポイントでwp core downloadが実行された場合を考慮して少し待機
sleep 3

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

# 初期化処理を実行（毎回実行）
/usr/docker/bin/init.sh "$WP_ROOT"

# setup.shを実行（初回起動時のみ）
# WordPressのインストール状態を直接確認（wp core is-installedで判定）
if [ -f /usr/docker/bin/setup.sh ]; then
    # WordPressのインストール状態を確認（データベース接続が必要）
    # wp-config.phpが存在し、WordPressがインストール済みか確認
    if [ -f /var/www/html/wp-config.php ]; then
        # wp core is-installedで判定（データベース接続が必要なので、接続確認後に実行）
        if wp core is-installed --allow-root --path="/var/www/html" 2>/dev/null; then
            echo "ℹ️  WordPressは既にインストール済みです"
            # post-setup.shでWordPress設定を実行
            /usr/docker/bin/post-setup.sh "$WP_ROOT" || true
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
                # setup.sh完了後、WordPress設定を実行
                /usr/docker/bin/post-setup.sh "$WP_ROOT" || true
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
            # setup.sh完了後、WordPress設定を実行
            /usr/docker/bin/post-setup.sh "$WP_ROOT" || true
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

