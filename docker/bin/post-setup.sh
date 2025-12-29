#!/bin/bash
# ==============================================
# WordPressインストール後に必ず実行される処理
# ========================================

set -euo pipefail

# WordPressのドキュメントルート（引数から取得、デフォルトは/var/www/html）
WP_ROOT="${1:-/var/www/html}"

# WordPressがインストールされている場合のみ実行
if ! wp core is-installed --allow-root --path="$WP_ROOT" 2>/dev/null; then
    echo "ℹ️  WordPressが未インストールのため、post-setup.shをスキップします"
    exit 0
fi

echo ""
echo "=========================================="
echo "⚙️  WordPress設定を適用中..."
echo "=========================================="

# デバッグ設定を環境変数の値で更新（毎回実行）
echo "  デバッグ設定を更新中..."
WP_DEBUG_VALUE="${WP_DEBUG:-true}"
WP_DEBUG_DISPLAY_VALUE="${WP_DEBUG_DISPLAY:-true}"
WP_DEBUG_LOG_VALUE="${WP_DEBUG_LOG:-true}"
WP_DEBUG_LOG_FILE_VALUE="${WP_DEBUG_LOG_FILE:-$WP_ROOT/docker/log/debug.log}"

# docker/logディレクトリを作成（存在しない場合）
LOG_DIR="$WP_ROOT/docker/log"
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    echo "✅ docker/logディレクトリを作成しました"
fi

if [ -f "$WP_ROOT/wp-config.php" ]; then
    wp config set WP_DEBUG "$WP_DEBUG_VALUE" --raw --allow-root --path="$WP_ROOT" 2>&1 || echo "    ⚠️  WP_DEBUGの設定に失敗しました"
    wp config set WP_DEBUG_DISPLAY "$WP_DEBUG_VALUE" --raw --allow-root --path="$WP_ROOT" 2>&1 || echo "    ⚠️  WP_DEBUG_DISPLAYの設定に失敗しました"
    wp config set WP_DEBUG_LOG "$WP_DEBUG_VALUE" --raw --allow-root --path="$WP_ROOT" 2>&1 || echo "    ⚠️  WP_DEBUG_LOGの設定に失敗しました"
    wp config set WP_DEBUG_LOG_FILE "$LOG_DIR/wp-debug.log" --allow-root --path="$WP_ROOT" 2>&1 || echo "    ⚠️  WP_DEBUG_LOG_FILEの設定に失敗しました"

    # PHPエラーログをdocker/logディレクトリと標準出力の両方に出力するように設定
    # 既に存在する場合は削除してから追加（重複を防ぐ）
    if grep -q "ini_set('log_errors', 1)" "$WP_ROOT/wp-config.php"; then
        # 既存の設定ブロックを削除
        sed -i '/\/\* 開発環境用: PHPエラーログ/,/^}$/d' "$WP_ROOT/wp-config.php" 2>/dev/null || true
    fi

    # 設定ブロックを追加
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

    echo "  ✅ デバッグ設定を更新しました (WP_DEBUG=$WP_DEBUG_VALUE)"
fi

# パーマリンク構造を設定（毎回実行）
echo "  パーマリンク構造を設定中..."
wp rewrite structure '/%postname%/' --allow-root --path="$WP_ROOT" 2>&1 || echo "    ⚠️  パーマリンク構造の設定に失敗しました"
wp rewrite flush --allow-root --path="$WP_ROOT" 2>&1 || echo "    ⚠️  パーマリンクのフラッシュに失敗しました"
echo "  ✅ パーマリンク構造を設定しました"

# 日本語言語パックの設定（毎回実行）
echo "  日本語言語パックを設定中..."
# 言語パックをインストール（既にインストール済みの場合は更新）
wp language core install ja --allow-root --path="$WP_ROOT" 2>&1 | grep -v "already installed" || true
wp language core update ja --allow-root --path="$WP_ROOT" 2>&1 || true

# サイトの言語を日本語に切り替え
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
echo "  ✅ 日本語言語パックを設定しました"

# プラグインの日本語化（毎回実行）
# インストール済みのすべてのプラグインに対して日本語化を実行
echo "  プラグインの日本語言語パックをインストール中..."
installed_plugins=$(wp plugin list --allow-root --path="$WP_ROOT" --field=name --format=csv 2>/dev/null | tail -n +2 || echo "")

if [ -n "$installed_plugins" ]; then
    echo "$installed_plugins" | while IFS= read -r plugin; do
        if [ -n "$plugin" ]; then
            wp language plugin install "$plugin" ja --allow-root --path="$WP_ROOT" 2>&1 | grep -v "already installed" || true
            wp language plugin update "$plugin" --allow-root --path="$WP_ROOT" 2>&1 || true
        fi
    done
    echo "  ✅ プラグインの日本語言語パックを設定しました"
else
    echo "  ℹ️  インストール済みのプラグインが見つかりませんでした"
fi

echo ""
echo "=========================================="
echo "✅ WordPress設定が完了しました"
echo "=========================================="

