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

