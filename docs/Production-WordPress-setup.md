# 本番 WordPress 設置手順

共有サーバーや本番ホストに nyardpress ベースのサイトを置くときの手順と注意です。  
対象読者は、サーバーパネル操作と FTP / SSH が使える実装・運用担当です。

Docker 開発環境では `setup.sh` が `wp-config.php` を自動生成します。本番ではその仕組みは使わず、この文書の手順で手置きします。

テーマの継続デプロイ（GitHub Actions）は [.github/DEPLOYMENT.md](../.github/DEPLOYMENT.md) を参照してください。

## Docker との違い

| 項目 | Docker 開発 | 本番・ステージング |
|------|-------------|-------------------|
| WordPress 本体 | コンテナが自動取得 | サーバーに別途インストール |
| `wp-config.php` | `setup.sh` が生成 | `wp-config.sample.php` から作成 |
| デバッグログ | `docker/log/` | `www/htdocs/log/debug.log` |
| DB の SSL | `MYSQL_CLIENT_FLAGS` は `0` | ホスト要件に合わせて設定 |
| デプロイ | ローカルマウント | 初回は一式配置、以降は主にテーマ |

## 事前に用意するもの

1. 公開ディレクトリ（例: `public_html`）と、その中に置く WordPress 用の領域
2. MySQL / MariaDB のデータベース名・ユーザー・パスワード・ホスト名（サーバーパネルで作成）
3. PHP 8.0 以上（Composer / テーマ要件に合わせる）
4. HTTPS（管理画面・フロントとも SSL 推奨）
5. ローカルでビルド済みのテーマ資産（`npm run build` 後の成果物）

## 設置の流れ

### 1. WordPress 本体を入れる

サーバーの標準インストーラ、または公式パッケージで WordPress をドキュメントルートに配置します。  
nyardpress リポジトリには WordPress 本体（`wp-admin` など）は含まれません。

### 2. このプロジェクトから載せるもの

ドキュメントルートを `www/htdocs/` 相当として、少なくとも次を配置します。

| 配置先 | 内容 |
|--------|------|
| `wp-content/themes/nyardpress/` | テーマ（ビルド済み） |
| `wp-content/mu-plugins/site-core/` | MU プラグイン（Composer の `vendor` 含む） |
| `wp-content/plugins/` | 必要なプラグイン（Composer 利用時は `vendor` も） |
| `.htaccess` | リポジトリ同梱のセキュリティ設定付き |
| `log/` | `.htaccess` と空の `debug.log` |
| `wp-config.php` | サンプルから作成（次節） |

`uploads` は初回は空でよいです。メディア移行がある場合は別途コピーします。

### 3. wp-config.php を作る

```bash
cp wp-config.sample.php wp-config.php
```

編集する項目:

1. `DB_NAME` / `DB_USER` / `DB_PASSWORD` / `DB_HOST` をサーバーの値に合わせる
2. [認証キーとソルト](https://api.wordpress.org/secret-key/1.1/salt/) を生成して置き換える（プレースホルダのままにしない）
3. `$table_prefix` を決める（既存 DB を使う場合は既存プレフィックスに合わせる）
4. `WP_ENVIRONMENT_TYPE` を `production` または `staging` にする

DB が SSL 必須のホストだけ、コメントアウトされている `MYSQL_CLIENT_FLAGS` などを有効化します。Docker 用の `0`（SSL 無効）を本番にコピーしないでください。

パーミッションの目安: `wp-config.php` は `600` または `640`。ディレクトリは `755`、一般ファイルは `644`。`777` は使わない。

### 4. デバッグとログ

サンプルには検証しやすい初期値が入っています。

```php
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', __DIR__ . '/log/debug.log' );
```

- ログ先は `log/debug.log`。`log/.htaccess` で Web からの閲覧を拒否しています
- `log/` ディレクトリが無いと書けないので、リポジトリの `log/`（`.htaccess` と空の `debug.log`）を必ず置く
- **公開リリース前**は次を推奨する  
  - `WP_DEBUG` を `false`  
  - `WP_DEBUG_DISPLAY` と `display_errors` をオフ  
  - 必要ならログだけ残す場合は `WP_DEBUG` true + `WP_DEBUG_DISPLAY` false

`DISALLOW_FILE_EDIT` と `WP_AUTO_UPDATE_CORE`（`'minor'`）はサンプルに含まれています。

### 5. .htaccess

リポジトリの `.htaccess` をドキュメントルートに置きます。主な内容:

- WordPress パーマリンク用ルール（`# BEGIN WordPress` 〜 `# END WordPress`）
- 秘匿ファイル・`vendor`・ログ・SQL などへのアクセス拒否
- XML-RPC（`xmlrpc.php`）の拒否
- Basic 認証の無効化テンプレ（コメントアウト済み）
- セキュリティヘッダー

注意:

- `# BEGIN WordPress` 〜 `# END WordPress` は管理画面のパーマリンク保存で書き換わることがある。カスタムルールはその外側に置く
- Jetpack や WP モバイルアプリで XML-RPC が必要な場合は、該当の拒否ブロックを外すか許可 IP に限る
- Basic 認証を使うときはコメントを外し、`AuthUserFile` を `.htpasswd` の**絶対パス**にする。`wp-cron.php` は認証なし例外付き
- `.htpasswd` は公開ディレクトリの外に置く

### 6. Composer 依存関係

テーマ・MU プラグイン・プラグインは `vendor` が無いと動きません。次のどちらかで揃えます。

1. ローカルで `composer install --no-dev` した成果をアップロードする  
2. サーバー上で同じコマンドを実行する（SSH と Composer が使える場合）

本番に `require-dev` の検証用プラグインを載せないこと。

### 7. テーマのビルド

デプロイ前にローカルで本番ビルドします。

```bash
cd www/htdocs/wp-content/themes/nyardpress
npm ci
npm run build
```

ソースだけ上げてサーバーで `npm run build` しない運用でも、ビルド成果物がテーマ側の想定パスに入っていることを確認してください。

### 8. インストール完了と初期設定

1. ブラウザでサイト URL を開き、未インストールなら WordPress のインストールウィザードを進める（または WP-CLI）
2. 管理画面でパーマリンクを「投稿名」などに設定して保存する（`.htaccess` の書き換えに注意）
3. テーマ `nyardpress` と必要なプラグインを有効化する
4. サイト URL・ホーム URL が HTTPS になっているか確認する
5. メディアアップロードと管理画面ログインを確認する

## 公開前チェックリスト

- [ ] `wp-config.php` のソルトがプレースホルダではない
- [ ] 公開本番で `WP_DEBUG` / 画面上のエラー表示がオフ（または意図した設定）
- [ ] `log/` があり、`https://example.com/log/debug.log` が 403 になる
- [ ] `https://example.com/xmlrpc.php` が 403 になる（XML-RPC 利用時は除く）
- [ ] `.env` / `composer.json` / `.git` が Web から読めない
- [ ] `wp-config.php` のパーミッションが厳しすぎず緩すぎない（600 または 640）
- [ ] HTTPS でフロントと `/wp-admin/` が開ける
- [ ] テーマ・MU プラグインの `vendor` が揃っている
- [ ] バックアップ（ファイル＋DB）の取得方法が決まっている

## デプロイ時の注意

GitHub Actions の標準設定は**テーマディレクトリのみ**を rsync します。初回の本体・`wp-config.php`・`.htaccess`・`log/`・MU プラグインは手動または別手段で置きます。

ログを消さないため、rsync では `*.log` と `log/*.log` を除外しています。空の `debug.log` を毎回上書き転送しないでください。

`wp-config.php` と本番の `.htaccess`（Basic 認証を有効化した状態など）は Git 管理外です。サーバー上の実ファイルをデプロイで潰さないこと。

## 関連ファイル

| ファイル | 用途 |
|----------|------|
| `www/htdocs/wp-config.sample.php` | 本番用設定例 |
| `www/htdocs/.htaccess` | セキュリティ・XML-RPC・Basic 認証テンプレ |
| `www/htdocs/log/` | デバッグログ置き場（Web 拒否済み） |
| [.github/DEPLOYMENT.md](../.github/DEPLOYMENT.md) | テーマの GitHub Actions デプロイ |
| [Database-migration-with-WP-CLI.md](Database-migration-with-WP-CLI.md) | DB 移行（開発向けが多いが手順の参考） |
