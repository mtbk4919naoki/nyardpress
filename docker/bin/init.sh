#!/bin/bash
# ==============================================
# コンテナ立ち上げ時に毎回実行される初期化処理
# WordPressのインストール状態に関係なく実行可能な処理のみ
# ========================================

set -euo pipefail

# WordPressのドキュメントルート（環境変数から取得、デフォルトは/var/www/html）
WP_ROOT="${WP_ROOT:-/var/www/html}"
WP_DIR_NAME=$(basename "$WP_ROOT")

echo ""
echo "=========================================="
echo "🔧 コンテナ初期化処理を開始します"
echo "=========================================="

# ============================================
# 1. ファイル・ディレクトリのパーミッション設定
# ============================================
echo ""
echo "📁 ファイル・ディレクトリのパーミッションを設定中..."

# wp-adminとwp-includesの所有者とパーミッションを設定
WP_ADMIN_DIR="$WP_ROOT/wp-admin"
WP_INCLUDES_DIR="$WP_ROOT/wp-includes"

if [ -d "$WP_ADMIN_DIR" ]; then
    chown -R www-data:www-data "$WP_ADMIN_DIR" 2>/dev/null || true
    find "$WP_ADMIN_DIR" -type d -exec chmod 775 {} \; 2>/dev/null || true
    find "$WP_ADMIN_DIR" -type f -exec chmod 664 {} \; 2>/dev/null || true
    echo "✅ wp-adminディレクトリのパーミッションを設定しました"
fi

if [ -d "$WP_INCLUDES_DIR" ]; then
    chown -R www-data:www-data "$WP_INCLUDES_DIR" 2>/dev/null || true
    find "$WP_INCLUDES_DIR" -type d -exec chmod 775 {} \; 2>/dev/null || true
    find "$WP_INCLUDES_DIR" -type f -exec chmod 664 {} \; 2>/dev/null || true
    echo "✅ wp-includesディレクトリのパーミッションを設定しました"
fi

# wp-config.phpのパーミッションを設定
if [ -f "$WP_ROOT/wp-config.php" ]; then
    chown www-data:www-data "$WP_ROOT/wp-config.php" 2>/dev/null || true
    chmod 640 "$WP_ROOT/wp-config.php" 2>/dev/null || true
    echo "✅ wp-config.phpのパーミッションを設定しました"
fi

# ============================================
# 2. プラグイン用ディレクトリの作成・権限設定
# ============================================
echo ""
echo "📦 プラグイン用ディレクトリを準備中..."

# EWWW Image Optimizer用のディレクトリを作成・権限設定
EWWW_DIR="$WP_ROOT/wp-content/ewww"
EWWW_BINARIES_DIR="$EWWW_DIR/binaries"
if [ ! -d "$EWWW_DIR" ]; then
    mkdir -p "$EWWW_DIR"
fi
if [ ! -d "$EWWW_BINARIES_DIR" ]; then
    mkdir -p "$EWWW_BINARIES_DIR"
fi
chown -R www-data:www-data "$EWWW_DIR" 2>/dev/null || true
chmod -R 755 "$EWWW_DIR" 2>/dev/null || true

# W3 Total Cache用のディレクトリを作成・権限設定
W3TC_CACHE_DIR="$WP_ROOT/wp-content/cache"
W3TC_CONFIG_DIR="$WP_ROOT/wp-content/w3tc-config"
W3TC_TMP_DIR="$W3TC_CACHE_DIR/tmp"
if [ ! -d "$W3TC_CACHE_DIR" ]; then
    mkdir -p "$W3TC_CACHE_DIR"
fi
if [ ! -d "$W3TC_CONFIG_DIR" ]; then
    mkdir -p "$W3TC_CONFIG_DIR"
fi
if [ ! -d "$W3TC_TMP_DIR" ]; then
    mkdir -p "$W3TC_TMP_DIR"
fi
chown -R www-data:www-data "$W3TC_CACHE_DIR" 2>/dev/null || true
chown -R www-data:www-data "$W3TC_CONFIG_DIR" 2>/dev/null || true
chmod -R 755 "$W3TC_CACHE_DIR" 2>/dev/null || true
chmod -R 755 "$W3TC_CONFIG_DIR" 2>/dev/null || true

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

echo "✅ プラグイン用ディレクトリを準備しました"

# ============================================
# 3. デフォルトテーマ・プラグインの削除
# ============================================
echo ""
echo "🗑️  デフォルトテーマ・プラグインを削除中..."

# デフォルトテーマ（twenty*系）を削除
THEMES_DIR="$WP_ROOT/wp-content/themes"
if [ -d "$THEMES_DIR" ]; then
    find "$THEMES_DIR" -maxdepth 1 -type d -name "twenty*" 2>/dev/null | while IFS= read -r theme_dir; do
        if [ -n "$theme_dir" ] && [ -d "$theme_dir" ]; then
            theme_basename=$(basename "$theme_dir")
            echo "  削除中: $theme_basename"
            rm -rf "$theme_dir" || true
        fi
    done || true
fi

# デフォルトプラグイン（Akismet、HelloDolly）を削除
PLUGINS_DIR="$WP_ROOT/wp-content/plugins"
if [ -d "$PLUGINS_DIR" ]; then
    # Akismetプラグインを削除
    if [ -d "$PLUGINS_DIR/akismet" ] || [ -f "$PLUGINS_DIR/akismet/akismet.php" ]; then
        echo "  削除中: akismet"
        rm -rf "$PLUGINS_DIR/akismet" 2>/dev/null || true
    fi
    # HelloDollyプラグインを削除
    if [ -f "$PLUGINS_DIR/hello.php" ]; then
        echo "  削除中: hello-dolly"
        rm -f "$PLUGINS_DIR/hello.php" 2>/dev/null || true
    fi
fi

echo "✅ デフォルトテーマ・プラグインの削除が完了しました"

# 公式のindex.phpを書き換えてwp-contentを削除する
echo "WP_ROOT: $WP_ROOT"
echo "WP_DIR_NAME: $WP_DIR_NAME"
if [ "$WP_DIR_NAME" != "html" ]; then
    echo "ℹ️ サブディレクトリにwordpressをインストールしているため構成を変更します..."

    echo "  📝 index.phpを書き換えています (WP_DIR_NAME: $WP_DIR_NAME)..."
    cp /var/www/html/$WP_DIR_NAME/index.php /var/www/html/index.php
    sed -i "s|'/wp-blog-header\.php'|'/$WP_DIR_NAME/wp-blog-header.php'|g" /var/www/html/index.php
    echo "  ✅ index.phpを書き換えました"

    echo "  🗑️ wp-contentを削除しています..."
    rm -rf /var/www/html/wp-content
    echo "  ✅ wp-contentを削除しました"

    echo "✅ 構成変更が完了しました"
fi

echo ""
echo "=========================================="
echo "✅ コンテナ初期化処理が完了しました"
echo "=========================================="

