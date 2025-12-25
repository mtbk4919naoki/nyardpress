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

# Composer installを実行する関数
run_composer_install() {
    local dir=$1
    if [ -f "$dir/composer.json" ]; then
        echo "Composer installを実行中: $dir"
        cd "$dir"
        composer install --no-interaction --prefer-dist || echo "Composer installに失敗しました: $dir"
    fi
}

# マウントされたディレクトリ配下でcomposer.jsonを探索してcomposer installを実行
echo "マウントされたディレクトリでcomposer.jsonを探索中..."

# wp-content配下のthemes、plugins、mu-pluginsディレクトリを探索
for base_dir in "$WP_ROOT/wp-content/themes" "$WP_ROOT/wp-content/plugins" "$WP_ROOT/wp-content/mu-plugins"; do
    if [ -d "$base_dir" ]; then
        echo "探索中: $base_dir"
        # ディレクトリ配下を再帰的に探索（最大深度2レベル）
        # findの結果を配列に格納してから処理（サブシェル問題を回避）
        find "$base_dir" -maxdepth 2 -type f -name "composer.json" 2>/dev/null | while IFS= read -r composer_file; do
            if [ -n "$composer_file" ]; then
                composer_dir=$(dirname "$composer_file")
                # 既に実行済みのディレクトリをスキップ（vendorディレクトリ内など）
                if [[ "$composer_dir" != *"/vendor/"* ]]; then
                    run_composer_install "$composer_dir" || echo "⚠️  Composer installに失敗: $composer_dir"
                fi
            fi
        done || true
    fi
done

echo "Composer installが完了しました"

# データベース接続情報を環境変数から取得
DB_HOST="${WORDPRESS_DB_HOST:-db}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"

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

    # 開発環境用のデバッグ設定を追加
    echo "開発環境用のデバッグ設定を追加中..."
    wp config set WP_DEBUG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUGの設定に失敗しました"
    wp config set WP_DEBUG_DISPLAY true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_DISPLAYの設定に失敗しました"
    wp config set WP_DEBUG_LOG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_LOGの設定に失敗しました"
    wp config set WP_DEBUG_LOG_FILE "$WP_ROOT/wp-content/debug.log" --allow-root --path="$WP_ROOT" || echo "⚠️  WP_DEBUG_LOG_FILEの設定に失敗しました"
    wp config set SCRIPT_DEBUG true --raw --allow-root --path="$WP_ROOT" || echo "⚠️  SCRIPT_DEBUGの設定に失敗しました"

    # PHPエラーログを標準出力にも出力するように設定
    # wp-config.phpに直接追加
    if ! grep -q "ini_set('log_errors', 1)" "$WP_ROOT/wp-config.php"; then
        echo "" >> "$WP_ROOT/wp-config.php"
        echo "/* 開発環境用: PHPエラーログを標準出力にも出力 */" >> "$WP_ROOT/wp-config.php"
        echo "if (WP_DEBUG) {" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('log_errors', 1);" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('error_log', 'php://stderr');" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('display_errors', 1);" >> "$WP_ROOT/wp-config.php"
        echo "    ini_set('display_startup_errors', 1);" >> "$WP_ROOT/wp-config.php"
        echo "    error_reporting(E_ALL);" >> "$WP_ROOT/wp-config.php"
        echo "}" >> "$WP_ROOT/wp-config.php"
        echo "✅ デバッグ設定を追加しました"
    else
        echo "✅ デバッグ設定は既に追加されています"
    fi

    # WordPressをインストール
    echo "WordPressをインストール中..."
    echo "  URL: ${WORDPRESS_URL:-http://localhost:8080}"
    echo "  タイトル: ${WORDPRESS_TITLE:-Nyardpress}"
    echo "  管理者ユーザー: ${WORDPRESS_ADMIN_USER:-admin}"

    if wp core install \
        --url="${WORDPRESS_URL:-http://localhost:8080}" \
        --title="${WORDPRESS_TITLE:-Nyardpress}" \
        --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
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

            # PHPエラーログを標準出力にも出力するように設定
            if ! grep -q "ini_set('log_errors', 1)" "$WP_ROOT/wp-config.php"; then
                echo "" >> "$WP_ROOT/wp-config.php"
                echo "/* 開発環境用: PHPエラーログを標準出力にも出力 */" >> "$WP_ROOT/wp-config.php"
                echo "if (WP_DEBUG) {" >> "$WP_ROOT/wp-config.php"
                echo "    ini_set('log_errors', 1);" >> "$WP_ROOT/wp-config.php"
                echo "    ini_set('error_log', 'php://stderr');" >> "$WP_ROOT/wp-config.php"
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

    # パーマリンク構造を設定
    echo "パーマリンク構造を設定中..."
    wp rewrite structure '/%postname%/' --allow-root --path="$WP_ROOT" || echo "パーマリンク構造の設定に失敗しました"
    wp rewrite flush --allow-root --path="$WP_ROOT" || echo "パーマリンクのフラッシュに失敗しました"

    # 日本語言語パックのインストールとアクティベート
    echo "日本語言語パックをインストール中..."
    wp language core install ja --activate --allow-root --path="$WP_ROOT" || echo "日本語言語パックのインストールに失敗しました"

    # wordpress-seoプラグインのインストールとアクティベート
    echo "wordpress-seoプラグインをインストール中..."
    wp plugin install wordpress-seo --activate --allow-root --path="$WP_ROOT" || echo "wordpress-seoプラグインのインストールに失敗しました"

    # テーマをアクティベート
    THEME_NAME="${THEME_NAME:-nyardpress}"
    echo "${THEME_NAME}テーマをアクティベート中..."
    wp theme activate "$THEME_NAME" --allow-root --path="$WP_ROOT" || echo "${THEME_NAME}テーマのアクティベートに失敗しました（テーマが存在しない可能性があります）"

    echo "WordPressの設定が完了しました"
else
    echo "WordPressのインストールに失敗しました。手動でインストールしてください。"
fi
