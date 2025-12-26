#!/bin/bash
# ==============================================
# データベースとメディアファイルを復元します
# ========================================

set -euo pipefail

# コマンドライン引数からダンプファイル名を取得
DUMP_NAME="$1"

if [ -z "$DUMP_NAME" ]; then
    echo "❌ ダンプファイル名を指定してください"
    echo ""
    echo "使用方法:"
    echo "  /usr/docker/bin/restore.sh <ダンプファイル名>"
    echo ""
    echo "例:"
    echo "  /usr/docker/bin/restore.sh wordpress_dump_20240101_120000"
    exit 1
fi

# WordPressのドキュメントルート
WP_ROOT="/var/www/html"
DUMP_DIR="/var/www/html/docker/dump"
TAR_FILE="$DUMP_DIR/${DUMP_NAME}.tar.gz"

# データベース接続情報を環境変数から取得
DB_HOST="${WORDPRESS_DB_HOST:-db}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"

# ダンプファイルの存在確認
if [ ! -f "$TAR_FILE" ]; then
    echo "❌ ダンプファイルが見つかりません: $TAR_FILE"
    exit 1
fi

echo "=========================================="
echo "📥 WordPressの復元を開始します"
echo "=========================================="
echo "  ダンプファイル: $DUMP_NAME"
echo ""

# 一時作業ディレクトリを作成
TEMP_DIR="$DUMP_DIR/temp"
mkdir -p "$TEMP_DIR"
# エラー時にも一時ディレクトリを削除するように設定
trap "rm -rf '$TEMP_DIR'" EXIT

# 圧縮ファイルを展開
echo "📦 ダンプファイルを展開中..."
cd "$TEMP_DIR"
if tar -xzf "$TAR_FILE" 2>/dev/null; then
    echo "  ✅ 展開が完了しました"
else
    echo "  ❌ 展開に失敗しました"
    exit 1
fi

# データベースの復元
echo ""
echo "📊 データベースを復元中..."
SQL_FILE="$TEMP_DIR/${DUMP_NAME}.sql"

if [ -f "$SQL_FILE" ]; then
    # データベースを空にする（既存のデータを削除）
    echo "  🗑️  既存のデータベースをクリア中..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --skip-ssl \
        -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;" 2>/dev/null || {
        echo "  ⚠️  データベースのクリアに失敗しました（続行します）"
    }
    
    # SQLファイルをインポート
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --skip-ssl \
        "$DB_NAME" < "$SQL_FILE" 2>/dev/null; then
        echo "  ✅ データベースの復元が完了しました"
        # ファイルサイズを表示
        SQL_SIZE=$(du -h "$SQL_FILE" | cut -f1)
        echo "  インポートしたSQLファイルサイズ: $SQL_SIZE"
    else
        echo "  ❌ データベースの復元に失敗しました"
        exit 1
    fi
else
    echo "  ⚠️  SQLファイルが見つかりません（スキップします）"
fi

# メディアファイルの復元
echo ""
echo "📁 メディアファイルを復元中..."
UPLOADS_SOURCE="$TEMP_DIR/uploads"
UPLOADS_DEST="$WP_ROOT/wp-content/uploads"

if [ -d "$UPLOADS_SOURCE" ] && [ "$(ls -A $UPLOADS_SOURCE 2>/dev/null)" ]; then
    # 既存のuploadsディレクトリをバックアップ（存在する場合）
    if [ -d "$UPLOADS_DEST" ] && [ "$(ls -A $UPLOADS_DEST 2>/dev/null)" ]; then
        BACKUP_DIR="${UPLOADS_DEST}_backup_$(date +%Y%m%d_%H%M%S)"
        echo "  💾 既存のメディアファイルをバックアップ中: $BACKUP_DIR"
        mv "$UPLOADS_DEST" "$BACKUP_DIR" 2>/dev/null || true
    fi
    
    # メディアファイルをコピー
    if cp -r "$UPLOADS_SOURCE" "$UPLOADS_DEST" 2>/dev/null; then
        echo "  ✅ メディアファイルの復元が完了しました: $UPLOADS_DEST"
        # ディレクトリサイズを表示
        UPLOADS_SIZE=$(du -sh "$UPLOADS_DEST" | cut -f1)
        echo "  ディレクトリサイズ: $UPLOADS_SIZE"
    else
        echo "  ⚠️  メディアファイルの復元に失敗しました（スキップします）"
    fi
else
    echo "  ℹ️  メディアファイルが存在しないか、空です（スキップします）"
fi

# 一時ディレクトリを削除（圧縮ファイルのみ残す）
echo ""
echo "🧹 一時ファイルを削除中..."
rm -rf "$TEMP_DIR"
echo "  ✅ 一時ファイルを削除しました"

echo ""
echo "=========================================="
echo "✅ 復元が完了しました"
echo "=========================================="
echo "  復元したダンプ: $DUMP_NAME"
echo ""
echo "📋 次のコマンドでWordPressの状態を確認できます:"
echo "   docker exec -it nyardpress_wordpress wp core version --allow-root"
echo "=========================================="
