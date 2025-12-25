#!/bin/bash
# ==============================================
# データベースとメディアファイルをダンプします
# ========================================

set -euo pipefail

# WordPressのドキュメントルート
WP_ROOT="/var/www/html"
DUMP_DIR="/var/www/html/docker/dump"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# コマンドライン引数からダンプ名のサフィックスを取得（オプション）
DUMP_SUFFIX="$1"
if [ -n "$DUMP_SUFFIX" ]; then
    # 引数がある場合は、タイムスタンプと引数を組み合わせる
    DUMP_NAME="wordpress_dump_${TIMESTAMP}_${DUMP_SUFFIX}"
else
    # 引数がない場合は、タイムスタンプのみ
    DUMP_NAME="wordpress_dump_${TIMESTAMP}"
fi

# データベース接続情報を環境変数から取得
DB_HOST="${WORDPRESS_DB_HOST:-db}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"

echo "=========================================="
echo "📦 WordPressのダンプを開始します"
echo "=========================================="
echo "  ダンプ名: $DUMP_NAME"
echo ""

# 一時作業ディレクトリを作成
TEMP_DIR="$DUMP_DIR/temp"
mkdir -p "$TEMP_DIR"
# エラー時にも一時ディレクトリを削除するように設定
trap "rm -rf '$TEMP_DIR'" EXIT

# データベースのダンプ
echo "📊 データベースをダンプ中..."
SQL_FILE="$TEMP_DIR/${DUMP_NAME}.sql"
if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --skip-ssl \
    --single-transaction \
    --quick \
    --lock-tables=false \
    "$DB_NAME" > "$SQL_FILE" 2>/dev/null; then
    echo "  ✅ データベースダンプが完了しました: $SQL_FILE"
    # ファイルサイズを表示
    SQL_SIZE=$(du -h "$SQL_FILE" | cut -f1)
    echo "  ファイルサイズ: $SQL_SIZE"
else
    echo "  ❌ データベースダンプに失敗しました"
    exit 1
fi

# メディアファイルのコピー
echo ""
echo "📁 メディアファイルをコピー中..."
UPLOADS_SOURCE="$WP_ROOT/wp-content/uploads"
UPLOADS_DEST="$TEMP_DIR/uploads"

if [ -d "$UPLOADS_SOURCE" ] && [ "$(ls -A $UPLOADS_SOURCE 2>/dev/null)" ]; then
    if cp -r "$UPLOADS_SOURCE" "$UPLOADS_DEST" 2>/dev/null; then
        echo "  ✅ メディアファイルのコピーが完了しました: $UPLOADS_DEST"
        # ディレクトリサイズを表示
        UPLOADS_SIZE=$(du -sh "$UPLOADS_DEST" | cut -f1)
        echo "  ディレクトリサイズ: $UPLOADS_SIZE"
    else
        echo "  ⚠️  メディアファイルのコピーに失敗しました（スキップします）"
    fi
else
    echo "  ℹ️  メディアファイルが存在しないか、空です（スキップします）"
fi

# 圧縮
echo ""
echo "🗜️  ファイルを圧縮中..."
TAR_FILE="$DUMP_DIR/${DUMP_NAME}.tar.gz"
cd "$TEMP_DIR"

# 圧縮するファイル/ディレクトリのリストを作成
TAR_FILES="${DUMP_NAME}.sql"
if [ -d "uploads" ]; then
    TAR_FILES="$TAR_FILES uploads"
fi

# SQLファイルとuploadsディレクトリ（存在する場合）を圧縮
if tar -czf "$TAR_FILE" $TAR_FILES 2>/dev/null; then
    echo "  ✅ 圧縮が完了しました: $TAR_FILE"
    # ファイルサイズを表示
    TAR_SIZE=$(du -h "$TAR_FILE" | cut -f1)
    echo "  ファイルサイズ: $TAR_SIZE"
else
    echo "  ❌ 圧縮に失敗しました"
    exit 1
fi

# 一時ディレクトリを削除
echo ""
echo "🧹 一時ファイルを削除中..."
rm -rf "$TEMP_DIR"
echo "  ✅ 一時ファイルを削除しました"

echo ""
echo "=========================================="
echo "✅ ダンプが完了しました"
echo "=========================================="
echo "  ダンプファイル: $TAR_FILE"
echo "  ファイルサイズ: $TAR_SIZE"
echo ""
echo "📋 次のコマンドで復元できます:"
echo "   npm run dc:restore $DUMP_NAME"
echo "=========================================="
