# phpMyAdminからDocker環境へのデータベースインポート手順

本番環境やステージング環境からphpMyAdminでエクスポートしたSQLファイルを、Docker開発環境にインポートする手順です。

## 前提条件

- Dockerコンテナが起動していること
- WordPressコンテナ名が`nyardpress_wordpress`であること
- データベース接続情報がデフォルト設定（`wordpress`ユーザー、`wordpress`データベース）であること

## 手順

### 1. phpMyAdminでエクスポート

1. phpMyAdminにログイン
2. 対象のデータベースを選択
3. 「エクスポート」タブを開く
4. エクスポート方法で「**詳細 - 可能なオプションをすべて表示**」を選択
5. 「生成オプション」セクションで「**CREATE DATABASE / USE 文を追加する**」のチェックを**外す**（重要）
6. 「実行」をクリックしてSQLファイルをダウンロード

**注意**: `CREATE DATABASE`文を含めると、権限エラーでインポートに失敗します。

### 2. SQLファイルとメディアファイルを配置

#### SQLファイルの配置

```bash
# プロジェクトルートから
cp ダウンロードしたファイル.sql docker/dump/
```

または、直接`docker/dump/`ディレクトリに配置してください。

#### メディアファイルの配置

本番環境の`wp-content/uploads/`フォルダをダウンロードして、以下のディレクトリに配置してください：

```bash
# プロジェクトルートから
# 本番環境のuploadsフォルダをダウンロードして配置
cp -r ダウンロードしたuploadsフォルダ/* www/htdocs/wp-content/uploads/
```

**注意**: メディアファイルは、データベースインポート前に配置しておくことを推奨します。

### 3. コンテナに入ってデータベースをインポート

```bash
# WordPressコンテナに入る
docker exec -it nyardpress_wordpress bash

# データベースを空にしてから再作成
mysql -h db -u wordpress -pwordpress --skip-ssl -e "DROP DATABASE IF EXISTS wordpress; CREATE DATABASE wordpress;"

# SQLファイルをインポート
mysql -h db -u wordpress -pwordpress --skip-ssl wordpress < /var/www/html/docker/dump/ファイル名.sql
```

**注意**: `--skip-ssl`オプションは、Docker環境でのSSL証明書エラーを回避するために必要です。

### 4. URLをローカル環境用に置換

インポート後、本番環境のURLをローカル環境用に置換する必要があります。

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

### 5. データベースをダンプして保存

インポートとURL置換が完了したら、ローカル環境用に調整されたデータベースをダンプして保存しておきます：

```bash
# コンテナから出る（まだコンテナ内にいる場合）
exit

# プロジェクトルートから実行
npm run dc:dump
```

これにより、`docker/dump/`ディレクトリにタイムスタンプ付きのダンプファイルが作成されます。次回以降は、このダンプファイルを使用して環境を復元できます。

## 完全な実行例

```bash
# 1. コンテナに入る
docker exec -it nyardpress_wordpress bash

# 2. データベースをリセットしてインポート
mysql -h db -u wordpress -pwordpress --skip-ssl -e "DROP DATABASE IF EXISTS wordpress; CREATE DATABASE wordpress;"
mysql -h db -u wordpress -pwordpress --skip-ssl wordpress < /var/www/html/docker/dump/5qdwt_fafed64y.sql

# 3. URL置換
wp search-replace production.example.com localhost:8080 --allow-root
wp search-replace https://localhost:8080 http://localhost:8080 --allow-root

# 4. コンテナから出る
exit

# 5. データベースをダンプして保存（プロジェクトルートから実行）
npm run dc:dump
```

## トラブルシューティング

### SSL証明書エラーが出る場合

`mysql`コマンドに`--skip-ssl`オプションを必ず付けてください。

### テーブルが既に存在するエラーが出る場合

手順3でデータベースを空にしてからインポートしてください。`DROP DATABASE`を実行することで、既存のテーブルがすべて削除されます。

### URL置換が反映されない場合

キャッシュをクリアしてください：

```bash
wp cache flush --allow-root
```

### wp db importが使えない場合

`wp db import`コマンドはSSL証明書エラーが発生する可能性があるため、`mysql`コマンドを直接使用することを推奨します。

## 注意事項

- **データベースのバックアップ**: インポート前に既存のデータベースをバックアップすることを推奨します
- **CREATE DATABASE文**: phpMyAdminのエクスポート設定で必ず外してください
- **URL置換の順序**: ドメイン名の置換を先に、その後HTTPS→HTTPの置換を行ってください
- **権限**: コンテナ内でrootユーザーで実行する場合、`--allow-root`オプションが必要です
- **メディアファイル**: データベースインポート前に`www/htdocs/wp-content/uploads/`に配置しておくことを推奨します
- **ダンプの保存**: インポートとURL置換が完了したら、`npm run dc:dump`でローカル環境用のダンプを保存しておくと、次回以降の環境構築が簡単になります
