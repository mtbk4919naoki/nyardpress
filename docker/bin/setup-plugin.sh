#!/bin/bash
# ==============================================
# プラグインのアクティベートを実行します
# 注意: プラグインの日本語化はpost-setup.shで実行されます
# ========================================

set -euo pipefail

# WordPressのドキュメントルート（環境変数から取得、デフォルトは/var/www/html）
WP_ROOT="${WP_ROOT:-/var/www/html}"

echo ""
echo "標準プラグインをアクティベート中..."
# 注意: プラグイン用ディレクトリの準備はinit.shで実行されます

# プラグインリストを定義（インストール順序を考慮）
# 依存関係や初期設定が必要なプラグインを先に配置
# 形式: "plugin_name:mode" (mode: activate=アクティベート+日本語化, localize_only=日本語化のみ)
PLUGINS=(
    "wp-multibyte-patch:activate"           # 日本語対応の基本プラグイン（最優先）
    "wordpress-seo:activate"                # SEOプラグイン
    "taxonomy-terms-order:activate"         # タクソノミー順序
    "simple-page-ordering:activate"         # ページ順序
    "wp-crontrol:activate"                  # Cron管理
    "query-monitor:activate"                # デバッグツール
    "wordpress-importer:activate"           # インポートツール
    "wp-mail-smtp:localize_only"            # メール送信（日本語化のみ）
    "updraftplus:localize_only"             # バックアップ（日本語化のみ）
    "all-in-one-wp-migration:localize_only" # 移行ツール（日本語化のみ）
    "redirection:localize_only"             # リダイレクト（日本語化のみ）
    "w3-total-cache:localize_only"          # キャッシュプラグイン（日本語化のみ）
    "ewww-image-optimizer:localize_only"    # 画像最適化（日本語化のみ）
    "cloudsecure-wp-security:localize_only" # セキュリティプラグイン（日本語化のみ）
)

# 各プラグインを処理
for plugin_entry in "${PLUGINS[@]}"; do
    # コメントアウトされた行をスキップ
    if [[ "$plugin_entry" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    # プラグイン名とモードを分割
    plugin_name="${plugin_entry%%:*}"
    plugin_mode="${plugin_entry##*:}"

    echo "  - $plugin_name"

    # プラグインがインストールされているか確認
    if wp plugin is-installed "$plugin_name" --allow-root --path="$WP_ROOT" 2>/dev/null; then
        # アクティベートが必要な場合
        if [ "$plugin_mode" = "activate" ]; then
            # アクティベート（既にアクティブでない場合）
            if wp plugin activate "$plugin_name" --allow-root --path="$WP_ROOT" 2>/dev/null; then
                echo "    ✅ $plugin_nameをアクティベートしました"
            else
                # 既にアクティブな場合はスキップ
                if wp plugin is-active "$plugin_name" --allow-root --path="$WP_ROOT" 2>/dev/null; then
                    echo "    ℹ️  $plugin_nameは既にアクティブです"
                else
                    echo "    ⚠️  $plugin_nameのアクティベートに失敗しました"
                fi
            fi
        else
            echo "    ℹ️  $plugin_nameは日本語化のみ（アクティベートしません）"
            echo "    ℹ️  日本語化はpost-setup.shで実行されます"
        fi
    else
        echo "    ⚠️  $plugin_nameがインストールされていません（Composer installを確認してください）"
    fi
done

echo ""
echo "✅ 標準プラグインの処理が完了しました"

