# nyardpress

NYCreationのWordPress開発フレームワークです。

Dockerを使用したWordPress開発環境で、Timber（Twig）、Carbon Fields、カスタム投稿タイプ・タクソノミーを簡単に管理できます。

## 特徴

- 🐳 Docker Composeによる開発環境
- 🎨 Timber 2.3.3（Twigテンプレートエンジン）対応
- 📦 Carbon Fieldsによるカスタムフィールド管理
- 🔧 カスタム投稿タイプ・タクソノミーの自動読み込み
- 🛠️ ユーティリティ関数（キャッシュ、ログなど）
- 🇯🇵 日本語環境の自動セットアップ
- 📧 Mailpitによるメールテスト環境

## 必要な環境

- Docker Desktop
- Node.js（npm scriptsを使用する場合）
- Git

## 開発環境立ち上げ

まだ、初回セットアップを行っていない場合は、次章のセットアップを行なってください。

### 1. コンテナの起動

```bash
# バックグラウンドモードでコンテナを起動
npm run start
```

### 2. テーマ開発環境の立ち上げ

```bash
# テーマディレクトリに移動（プロジェクトによる）
cd www/htdocs/wp-content/themes/nyardpress

npm run dev
```

### 3. MUプラグイン開発環境の立ち上げ

こちらはカスタム投稿タイプやカスタムブロック、カスタムフィールドの開発に用います。

```bash
# テーマディレクトリに移動（プロジェクトによる）
cd www/htdocs/wp-content/mu-plugins/site-core

npm run dev
```

## 3. 各画面へアクセス（.envやプロジェクトの設定による）

- [フロント: http://loclalhost:8080](http://localhost:8080)
- [管理画面: http://localhost:8080/wp-admin/](http://localhost:8080/wp-admin/)
- [メール: http://localhost:8025](http://localhost:8025)
- [DB: mysql://wordpress:wordpress@localhost:3306/wordpress](mysql://wordpress:wordpress@localhost:3306/wordpress)

**デフォルトWordPressユーザー**  
```
User: nyardpress  
Pass: supercat
```

**CLIでDBへアクセスする**
```bash
# dockerコンテナから
docker exec -it nyardpress_db mysql -u wordpress -pwordpress wordpress

# TCP/IPから
mysql -h localhost -P 3306 -u wordpress -pwordpress --protocol=TCP wordpress
```

**MySQLクライアントでDBへアクセスする**
```
protocol: TCP/IP
host: localhost
username: wordpress
password: wordpress
database: wordpress
```

## セットアップ

### 1. 環境変数の設定とDockerコンテナの起動

テーマ名は`nyardpress.config.json`から自動的に読み込まれます。

```bash
# npmインストール
npm ci

# 環境変数設定、Composer依存関係のインストール、Dockerコンテナのビルドと起動（推奨）
npm run setup
```

このコマンドで以下が順番に実行されます：
1. **環境変数ファイルの作成**（`npm run setup:env`）
  - 対話形式で以下の設定を行います：
  - WordPressポート番号（デフォルト: 8080）
  - MySQLポート番号（デフォルト: 3306）
  - SMTPポート番号（デフォルト: 1025）
  - Mailpitポート番号（デフォルト: 8025）
2. **Composer依存関係のインストール**（`npm run dc:install`）
   - プラグイン（`www/htdocs/wp-content/plugins/composer.json`）
   - テーマ（`www/htdocs/wp-content/themes/{THEME_NAME}/composer.json`）
   - MUプラグイン（`www/htdocs/wp-content/mu-plugins/site-core/composer.json`）
   - 各ディレクトリに`package.json`がある場合は`npm install`も実行
3. **Dockerコンテナのビルドと起動**（`npm run dc:build`）
   - 初回起動時は、自動的に以下が実行されます：
     - WordPressのインストール
     - 日本語言語パックのインストール
     - 標準プラグインのアクティベート
     - テーマのアクティベート
4. **無事ビルドできたことを確認したら一旦終了**（`ctrl + c`）

**個別に実行する場合：**

```bash
# 環境変数ファイルの作成
npm run setup:env

# Composerとnpmの依存関係をインストール
npm run dc:install

# Dockerコンテナのビルドと起動
npm run dc:build

# 無事ビルドできたら、ctrl + c で一旦終了
```

### 2. データベースの復元（途中から参加したメンバー向け）

既存のダンプファイルがある場合は、データベースとメディアファイルを復元します：

```bash
# 利用可能なダンプファイルを確認
ls docker/dump/*.tar.gz

# ダンプファイルを復元（ファイル名から拡張子を除いた名前を指定）
npm run dc:restore wordpress_dump_20251225_132220

# 最新のダンプファイルを自動選択して復元
npm run restore
```

**注意：** ダンプファイルがない場合は、この手順をスキップして次に進んでください。

### 3. アクセス

- **WordPress**: `http://localhost:8080`（デフォルト、`.env`で変更可能）
- **Mailpit Web UI**: `http://localhost:8025`（メールテスト用）
  - WordPressから送信されたメールがここに表示されます
  - SMTPサーバーは自動的に `mailpit:1025` に接続されます

## ディレクトリ構造

```
nyardpress/
├── docker/                    # Docker関連ファイル
│   ├── Dockerfile            # WordPressカスタムイメージ
│   └── bin/                  # カスタムスクリプト
│       ├── docker-entrypoint.sh
│       └── setup.sh          # WordPress初期セットアップ
├── scripts/                      # 環境設定スクリプト
│   ├── setup-env.js         # 環境変数セットアップ
│   ├── config.js            # 設定ファイル読み込み
│   ├── dc-install.js        # Composer依存関係インストール
│   ├── dc-build.js          # Docker Composeビルド
│   ├── dc-destory.js        # Docker Compose削除
│   ├── dc-dump.js           # データベースダンプ
│   └── dc-restore.js        # データベース復元
├── .env                      # 環境変数ファイル（プロジェクトルート、gitignore）
├── nyardpress.config.json   # プロジェクト設定ファイル（テーマ名など）
├── www/htdocs/               # WordPressドキュメントルート
│   ├── wp-content/
│   │   ├── themes/
│   │   │   └── nyardpress/  # カスタムテーマ（Timber使用）
│   │   ├── plugins/         # プラグインディレクトリ（マウント済み、永続化）
│   │   ├── mu-plugins/
│   │   │   └── site-core/   # MUプラグイン
│   │   │       ├── posttypes/    # カスタム投稿タイプ
│   │   │       ├── taxonomies/   # カスタムタクソノミー
│   │   │       ├── fields/       # Carbon Fields設定
│   │   │       └── utilities/    # ユーティリティ関数
│   │   └── plugins/
│   └── .htaccess            # Apache設定（セキュリティ含む）
└── docker-compose.yml       # Docker Compose設定
```

## コマンド一覧

### 環境セットアップ

```bash
# 環境変数の設定（対話形式）
npm run setup:env
```

### セットアップと起動

```bash
# 環境変数設定、Composer依存関係のインストール、Dockerコンテナのビルドと起動（推奨）
npm run setup

# 個別に実行する場合
npm run setup:env    # 環境変数ファイルの作成
npm run dc:install   # Composer依存関係のみインストール
npm run dc:build     # Dockerコンテナのビルドと起動
```

### Docker管理

```bash
# コンテナの起動（既にビルド済みの場合）
npm run start

# コンテナのビルドと起動
npm run dc:build

# コンテナの停止と削除（ボリュームも削除）
npm run dc:destroy

# 完全に再構築（削除→インストール→ビルド）
npm run rebuild
```

### データベースのダンプと復元

```bash
# データベースとメディアファイルをダンプ
npm run dump

# ダンプ名を指定してダンプ（オプション）
npm run dc:dump production

# ダンプファイルを復元（ファイル名を指定）
npm run dc:restore wordpress_dump_20251225_132220

# 最新のダンプファイルを自動選択して復元
npm run restore
```

**テーマディレクトリ内でのコマンド：**

```bash
# テーマディレクトリに移動
cd www/htdocs/wp-content/themes/nyardpress

# 依存関係のインストール
npm install

# 開発モード（ファイル監視）
npm run dev

# 本番ビルド
npm run build

# TypeScriptの型チェック
npm run type-check
```

詳細は `www/htdocs/wp-content/themes/nyardpress/README.md` を参照してください。

### コマンド一覧表

| コマンド | 説明 |
|---------|------|
| `npm run setup` | 環境変数設定、依存関係インストール、コンテナビルド（初回セットアップ推奨） |
| `npm run setup:env` | 環境変数ファイル（`.env`）の作成（対話形式） |
| `npm run dc:install` | Composer依存関係のインストール |
| `npm run dc:build` | Dockerコンテナのビルドと起動 |
| `npm run start` | コンテナの起動（既にビルド済みの場合） |
| `npm run rebuild` | コンテナの完全再構築（削除→インストール→ビルド） |
| `npm run dc:destroy` | コンテナの停止と削除（ボリュームも削除） |
| `npm run dump` | データベースとメディアファイルのダンプ |
| `npm run dc:dump [名前]` | ダンプ名を指定してダンプ |
| `npm run restore` | 最新のダンプファイルを自動選択して復元 |
| `npm run dc:restore [ファイル名]` | 指定したダンプファイルを復元 |

## 開発ガイド

### テーマのカスタマイズ

テーマは `www/htdocs/wp-content/themes/nyardpress/` にあります。

#### Twigテンプレート

- `views/base.twig` - ベーステンプレート
- `views/index.twig` - 投稿一覧
- `views/single.twig` - 個別投稿
- `views/page.twig` - 固定ページ
- `views/archive.twig` - アーカイブページ
- `views/404.twig` - 404ページ

#### PHPテンプレート

- `index.php` - 投稿一覧
- `single.php` - 個別投稿
- `page.php` - 固定ページ
- `archive.php` - アーカイブページ
- `404.php` - 404ページ

### Site Core（MUプラグイン）

カスタム投稿タイプ、カスタムタクソノミー、Carbon Fields、ユーティリティ関数の詳細は、`www/htdocs/wp-content/mu-plugins/site-core/README.md` を参照してください。

## 環境変数

プロジェクトルートの`.env`ファイルで以下の設定が可能です：

### ポート設定

- `WP_PORT` - WordPressポート番号（デフォルト: 8080）
- `DB_PORT` - MySQLポート番号（デフォルト: 3306）
- `SMTP_PORT` - SMTPポート番号（デフォルト: 1025）
- `MAILPIT_PORT` - Mailpit Web UIポート番号（デフォルト: 8025）

### テーマ設定

- `THEME_NAME` - テーマ名（`nyardpress.config.json`から自動設定、デフォルト: nyardpress）

### Vite開発サーバー設定

テーマ開発でViteを使用する場合、テーマ側の`.env`ファイル（`www/htdocs/wp-content/themes/{テーマ名}/.env`）でViteのポート番号を設定します。

**重要**: テーマ側の`.env`ファイルの`VITE_PORT`と、Docker側の`.env`ファイルの`VITE_PORT`（`setup-env.js`で設定）は同じ値に設定してください。異なる値を設定すると、Vite開発サーバーに接続できません。

- テーマ側: `www/htdocs/wp-content/themes/{テーマ名}/.env` → `VITE_PORT=3000`
- Docker側: プロジェクトルートの`.env` → `VITE_PORT=3000`（`setup-env.js`で設定可能）

### デバッグ設定

- `WP_DEBUG` - WordPressデバッグモード（デフォルト: true）

**注意**: `.env`ファイルで`WP_DEBUG=false`に設定すると、ビルド済みファイルの検証が可能です。

エラーログは以下の場所で確認できます：
- WordPressデバッグログ: `docker/log/debug.log`
- PHPエラーログ: `docker/log/php-error.log`
- Dockerログ: `docker logs nyardpress_wordpress`

## セキュリティ

`.htaccess`で以下のファイルへのアクセスが自動的に拒否されます：

- `.env`ファイル
- `vendor`ディレクトリ
- `composer.json`, `composer.lock`
- `.git`関連ファイル
- ログファイル、SQLファイル

## トラブルシューティング

### データベース接続エラー

```bash
# コンテナとボリュームを削除して再ビルド
npm run dc:destroy
npm run dc:build
```

### セットアップが実行されない

```bash
# WordPressのインストール状態を確認
docker exec -it nyardpress_wordpress wp core is-installed --allow-root

# 未インストールの場合は、wp-config.phpを削除して再起動
docker exec -it nyardpress_wordpress rm /var/www/html/wp-config.php
docker compose restart wordpress
```

## デプロイ

このプロジェクトでは、GitHub Actionsを使用してテーマをXServerへデプロイできます。

### デプロイ環境

- **Staging（ステージング環境）**: 開発・テスト用
- **Production（本番環境）**: 本番サイト

### デプロイの設定

詳細な設定手順は [.github/DEPLOYMENT.md](.github/DEPLOYMENT.md) を参照してください。

### 必要なGitHub Environment設定

各環境（`staging`、`production`）にそれぞれ以下を設定します：

**Secrets:**
- `SSH_HOST` - サーバーのホスト名
- `SSH_PORT` - SSHポート番号（通常10022）
- `SSH_USERNAME` - SSH接続用ユーザー名
- `SSH_PRIVATE_KEY` - SSH秘密鍵

**Variables:**
- `THEME_PATH` - テーマのデプロイ先パス
- `ASSET_PATH` - 静的アセットのデプロイ先パス（オプション）

### デプロイ方法

#### Stagingへのデプロイ

1. GitHubリポジトリの `Actions` タブを開く
2. `Deploy Theme to XServer (Staging)` ワークフローを選択
3. `Run workflow` ボタンをクリックして手動実行

#### Productionへのデプロイ

1. GitHubリポジトリの `Actions` タブを開く
2. `Deploy Theme to XServer` ワークフローを選択
3. `Run workflow` ボタンをクリックして手動実行

**推奨ワークフロー**: Staging環境で動作確認後、Production環境へデプロイ

**注意**: 本番環境への誤デプロイを防ぐため、自動デプロイは無効化されています。

## ライセンス

このプロジェクトはNYCreationの内部開発フレームワークです。

