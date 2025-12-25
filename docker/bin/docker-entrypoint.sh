#!/bin/bash
set -euo pipefail

# WordPressの標準エントリーポイントを実行（wp-config.phpの生成など）
docker-entrypoint.sh "$@" &
WP_PID=$!

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

# setup.shを実行（初回起動時のみ）
if [ -f /usr/docker/bin/setup.sh ]; then
    if [ -f /var/www/html/.setup-completed ]; then
        echo "ℹ️  setup.shは既に実行済みです（.setup-completedフラグが存在します）"
        echo "   再実行する場合は、.setup-completedフラグを削除してください"
    else
        echo "=========================================="
        echo "🚀 setup.shを実行中..."
        echo "=========================================="
        set +e  # エラーで停止しないようにする
        /usr/docker/bin/setup.sh
        setup_exit_code=$?
        set -e
        if [ $setup_exit_code -eq 0 ]; then
            touch /var/www/html/.setup-completed
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

