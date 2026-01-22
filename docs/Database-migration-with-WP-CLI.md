# WP-CLIを使ったデータベース移行手順

本番環境やステージング環境でWP-CLIが使用できる場合、`wp db export`と`wp db import`を使ってデータベースを移行する手順です。

## 前提条件

- 本番/ステージング環境でWP-CLIが使用可能であること
- Dockerコンテナが起動していること
- WordPressコンテナ名が`nyardpress_wordpress`であること
- データベース接続情報がデフォルト設定（`wordpress`ユーザー、`wordpress`データベース）であること

## 手順

### 1. 本番環境でデータベースをエクスポート

本番環境またはステージング環境で、WP-CLIを使ってデータベースをエクスポートします：

```bash
# 本番環境で実行
wp db export database-export.sql --path=/path/to/wordpress
```

または、特定のテーブルを除外する場合：

```bash
# キャッシュテーブルなどを除外する場合
wp db export database-export.sql --exclude_tables=wp_options --path=/path/to/wordpress
```

**注意**: `wp db export`は`CREATE DATABASE`文を含まないため、そのままインポートできます。

### 2. SQLファイルとメディアファイルをダウンロード

#### SQLファイルのダウンロード

エクスポートしたSQLファイルをローカル環境にダウンロードします：

```bash
# SCPなどでダウンロードする場合
scp user@production-server:/path/to/database-export.sql docker/dump/

# または、FTP/SFTPクライアントを使用
```

#### メディアファイルのダウンロード

本番環境の`wp-content/uploads/`フォルダをダウンロードして、以下のディレクトリに配置してください：

```bash
# プロジェクトルートから
# 本番環境のuploadsフォルダをダウンロードして配置
cp -r ダウンロードしたuploadsフォルダ/* www/htdocs/wp-content/uploads/
```

**注意**: メディアファイルは、データベースインポート前に配置しておくことを推奨します。

### 3. SSL設定の確認（自動設定済み）

開発環境構築時（`npm run setup`または`npm run dc:build`実行時）に、`setup.sh`が自動的に`wp-config.php`に`MYSQL_CLIENT_FLAGS`を設定します。

**確認**:
```bash
# WordPressコンテナに入る
docker exec -it nyardpress_wordpress bash

# SSL設定が正しく設定されているか確認
wp config get MYSQL_CLIENT_FLAGS --allow-root
# 出力: 0
```

**注意**: 既存の環境で設定されていない場合は、手動で設定してください：

```bash
wp config set MYSQL_CLIENT_FLAGS 0 --raw --allow-root
```

### 4. データベースをインポート

#### 方法1: wp db importを使用（推奨）

```bash
# WordPressコンテナ内で実行
wp db import /var/www/html/docker/dump/database-export.sql --allow-root
```

#### 方法2: mysqlコマンドを直接使用（wp db importが使えない場合）

```bash
# データベースを空にしてから再作成
mysql -h db -u wordpress -pwordpress --skip-ssl -e "DROP DATABASE IF EXISTS wordpress; CREATE DATABASE wordpress;"

# SQLファイルをインポート
mysql -h db -u wordpress -pwordpress --skip-ssl wordpress < /var/www/html/docker/dump/database-export.sql
```

### 5. URLをローカル環境用に置換

インポート後、本番環境のURLをローカル環境用に置換する必要があります：

```bash
# 本番URLをlocalhost:8080に置換
wp search-replace 本番のドメイン名 localhost:8080 --allow-root

# HTTPSをHTTPに置換（必要に応じて）
wp search-replace https://localhost:8080 http://localhost:8080 --allow-root
```

**実行例**:
```bash
wp search-replace production.example.com localhost:8080 --allow-root
wp search-replace https://localhost:8080 http://localhost:8080 --allow-root
```

### 6. データベースをダンプして保存

インポートとURL置換が完了したら、ローカル環境用に調整されたデータベースをダンプして保存しておきます：

```bash
# コンテナから出る（まだコンテナ内にいる場合）
exit

# プロジェクトルートから実行
npm run dc:dump
```

これにより、`docker/dump/`ディレクトリにタイムスタンプ付きのダンプファイルが作成されます。次回以降は、このダンプファイルを使用して環境を復元できます。

## 完全な実行例

### 本番環境側

```bash
# 1. データベースをエクスポート
wp db export database-export.sql --path=/path/to/wordpress

# 2. ファイルをダウンロード可能な場所に移動
mv database-export.sql /path/to/downloadable/
```

### ローカル環境側

```bash
# 1. SQLファイルを配置
cp ダウンロードしたdatabase-export.sql docker/dump/

# 2. メディアファイルを配置
cp -r ダウンロードしたuploads/* www/htdocs/wp-content/uploads/

# 3. コンテナに入る
docker exec -it nyardpress_wordpress bash

# 4. SSL設定を確認（自動設定済みの場合はスキップ可能）
wp config get MYSQL_CLIENT_FLAGS --allow-root || wp config set MYSQL_CLIENT_FLAGS 0 --raw --allow-root

# 5. データベースをインポート
wp db import /var/www/html/docker/dump/database-export.sql --allow-root

# 6. URL置換
wp search-replace production.example.com localhost:8080 --allow-root
wp search-replace https://localhost:8080 http://localhost:8080 --allow-root

# 7. コンテナから出る
exit

# 8. データベースをダンプして保存（プロジェクトルートから実行）
npm run dc:dump
```

## wp db exportのオプション

### 特定のテーブルを除外する

```bash
# 複数のテーブルを除外
wp db export database-export.sql --exclude_tables=wp_options,wp_transients --path=/path/to/wordpress
```

### 圧縮してエクスポートする

```bash
# gzip圧縮
wp db export database-export.sql.gz --path=/path/to/wordpress
```

### 構造のみ、またはデータのみをエクスポートする

```bash
# 構造のみ
wp db export database-structure.sql --no-data --path=/path/to/wordpress

# データのみ
wp db export database-data.sql --no-create-info --path=/path/to/wordpress
```

## トラブルシューティング

### SSL証明書エラーが出る場合

開発環境構築時に自動的に設定されますが、設定されていない場合は手動で設定してください：

```bash
wp config set MYSQL_CLIENT_FLAGS 0 --raw --allow-root
```

それでもエラーが出る場合は、方法2の`mysql`コマンドを直接使用してください。

### テーブルが既に存在するエラーが出る場合

方法2を使用して、データベースを空にしてからインポートしてください：

```bash
mysql -h db -u wordpress -pwordpress --skip-ssl -e "DROP DATABASE IF EXISTS wordpress; CREATE DATABASE wordpress;"
mysql -h db -u wordpress -pwordpress --skip-ssl wordpress < /var/www/html/docker/dump/database-export.sql
```

### URL置換が反映されない場合

キャッシュをクリアしてください：

```bash
wp cache flush --allow-root
```

### wp db importが使えない場合

`mysql`コマンドを直接使用する方法2を試してください。

## phpMyAdminとの比較

| 項目 | phpMyAdmin | WP-CLI |
|------|-----------|--------|
| CREATE DATABASE文 | 含まれる可能性あり（設定で除外可能） | 含まれない |
| SSL設定 | 不要（mysqlコマンド使用） | 必要（wp-config.phpで設定） |
| コマンドの簡潔さ | やや複雑 | シンプル |
| テーブル除外 | 手動でSQL編集が必要 | `--exclude_tables`オプションで簡単 |

## 注意事項

- **データベースのバックアップ**: インポート前に既存のデータベースをバックアップすることを推奨します
- **SSL設定**: 開発環境構築時に自動的に設定されますが、既存環境で設定されていない場合は手動で設定してください
- **URL置換の順序**: ドメイン名の置換を先に、その後HTTPS→HTTPの置換を行ってください
- **権限**: コンテナ内でrootユーザーで実行する場合、`--allow-root`オプションが必要です
- **メディアファイル**: データベースインポート前に`www/htdocs/wp-content/uploads/`に配置しておくことを推奨します
- **ダンプの保存**: インポートとURL置換が完了したら、`npm run dc:dump`でローカル環境用のダンプを保存しておくと、次回以降の環境構築が簡単になります
