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

## 必要な環境

- Docker Desktop
- Node.js（npm scriptsを使用する場合）
- Git

## セットアップ

### 1. 初回セットアップ

```bash
# 環境変数ファイルの作成と設定
npm run setup:env
```

対話形式で以下の設定を行います：
- プロジェクト名
- テーマ名（デフォルトはプロジェクト名と同じ）
- WordPress URL、ポート番号
- データベース設定
- 管理画面の認証情報

### 2. Dockerコンテナの起動

```bash
# コンテナのビルドと起動
npm run dc:build
```

初回起動時は、自動的に以下が実行されます：
- WordPressのインストール
- 日本語言語パックのインストール
- wordpress-seoプラグインのインストール
- テーマのアクティベート
- Composer依存関係のインストール

### 3. アクセス

ブラウザで `http://localhost:8080` にアクセスしてください。

## ディレクトリ構造

```
nyardpress/
├── docker/                    # Docker関連ファイル
│   ├── Dockerfile            # WordPressカスタムイメージ
│   └── bin/                  # カスタムスクリプト
│       ├── docker-entrypoint.sh
│       └── setup.sh          # WordPress初期セットアップ
├── env/                      # 環境設定スクリプト
│   ├── .env.sample          # 環境変数テンプレート
│   ├── setup-env.js         # 環境変数セットアップ
│   ├── dc-build.js          # Docker Composeビルド
│   ├── dc-destory.js        # Docker Compose削除
│   └── dc-flush.js          # ボリュームとキャッシュのクリア
├── www/htdocs/               # WordPressドキュメントルート
│   ├── wp-content/
│   │   ├── themes/
│   │   │   └── nyardpress/  # カスタムテーマ（Timber使用）
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

### Docker管理

```bash
# コンテナのビルドと起動
npm run dc:build

# コンテナの停止と削除
npm run dc:destroy

# ボリュームとキャッシュのクリア（データベースもリセット）
npm run dc:flush
```

### 開発用コマンド（今後実装予定）

```bash
# 開発サーバー起動
npm run dev

# ビルド
npm run build

# データベースエクスポート
npm run db:export

# データベースインポート
npm run db:import

# デプロイ
npm run deploy:dev
npm run deploy:stg
npm run deploy:prod
```

## 開発ガイド

### カスタム投稿タイプの追加

1. `www/htdocs/wp-content/mu-plugins/site-core/posttypes/` にPHPファイルを作成
2. `example-posttype.php` を参考に実装
3. ファイル名は `example-` で始めると自動的に読み込まれません（サンプル用）

```php
// posttypes/my-posttype.php
function register_my_post_type() {
    $labels = array(
        'name' => 'マイ投稿',
        // ...
    );
    $args = array(
        'labels' => $labels,
        'public' => true,
        // ...
    );
    register_post_type('my_posttype', $args);
}
add_action('init', 'register_my_post_type');
```

### カスタムタクソノミーの追加

1. `www/htdocs/wp-content/mu-plugins/site-core/taxonomies/` にPHPファイルを作成
2. `example-category.php` を参考に実装

```php
// taxonomies/my-taxonomy.php
function register_my_taxonomy() {
    $args = array(
        'hierarchical' => true,
        'public' => true,
        // ...
    );
    register_taxonomy('my_taxonomy', array('post'), $args);
}
add_action('init', 'register_my_taxonomy', 0);
```

### Carbon Fieldsでカスタムフィールドを追加

1. `www/htdocs/wp-content/mu-plugins/site-core/fields/` にPHPファイルを作成
2. `example-fields.php` を参考に実装

```php
// fields/my-fields.php
use Carbon_Fields\Container;
use Carbon_Fields\Field;

function add_my_custom_fields() {
    Container::make('post_meta', '追加情報')
        ->where('post_type', '=', 'my_posttype')
        ->add_fields(array(
            Field::make('text', 'my_field', 'カスタムフィールド'),
        ));
}
add_action('carbon_fields_register_fields', 'add_my_custom_fields');
```

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

### ユーティリティ関数

#### use_transient

キャッシュ機能を提供します。ログイン中のユーザーはキャッシュを無視します。

```php
$value = use_transient('cache_key', function() {
    // 重い処理
    return expensive_operation();
}, 3600); // 1時間キャッシュ
```

#### safe_log

安全にログを出力します。制御文字を自動的にサニタイズします。

```php
safe_log('エラーメッセージ', 'error', ['context' => 'value']);
```

## 環境変数

`.env`ファイルで以下の設定が可能です：

- `PROJECT_NAME` - プロジェクト名（コンテナ名などに使用）
- `THEME_NAME` - テーマ名
- `WORDPRESS_URL` - WordPressのURL
- `WORDPRESS_PORT` - ポート番号
- `WORDPRESS_DB_*` - データベース接続情報
- `WORDPRESS_ADMIN_*` - 管理画面の認証情報

詳細は `env/.env.sample` を参照してください。

## デバッグ設定

開発環境では、以下のデバッグ設定が自動的に有効になります：

- `WP_DEBUG = true`
- `WP_DEBUG_DISPLAY = true`
- `WP_DEBUG_LOG = true`
- `WP_DEBUG_LOG_FILE = /var/www/html/wp-content/debug.log`
- `SCRIPT_DEBUG = true`

エラーログは以下の場所で確認できます：
- ファイル: `www/htdocs/wp-content/debug.log`
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
# ボリュームをクリアして再起動
npm run dc:flush
```

### セットアップが実行されない

```bash
# セットアップフラグを削除して再実行
rm www/htdocs/.setup-completed
docker-compose restart wordpress
```

### Composer依存関係の再インストール

コンテナ内で実行：

```bash
docker exec -it nyardpress_wordpress bash
cd /var/www/html/wp-content/themes/nyardpress
composer install
```

## ライセンス

このプロジェクトはNYCreationの内部開発フレームワークです。

