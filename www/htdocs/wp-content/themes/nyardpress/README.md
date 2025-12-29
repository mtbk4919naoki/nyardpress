# Nyardpress Theme Development

WordPressテーマ開発環境（Vite + TypeScript + Tailwind CSS + Lit）

## セットアップ

```bash
# テーマディレクトリに移動
cd www/htdocs/wp-content/themes/nyardpress

# 依存関係のインストール（Docker側のsetupに含まれてます）
npm install
composer install

# 環境変数ファイルの設定
# .env.sampleを.envにリネームして、必要に応じてポート番号を変更
cp .env.sample .env

# 開発サーバーの起動（ファイル監視 + 自動ビルド）
npm run dev

# 本番ビルド（最適化 + ミニファイ）
npm run build

# TypeScriptの型チェックのみ
npm run type-check
```

### 環境変数の設定

テーマ側の`.env`ファイルでVite開発サーバーの設定を行います。

1. `.env.sample`を`.env`にリネーム
2. 必要に応じてポート番号を変更（複数プロジェクトを同時に開発する場合など）

```env
# Vite開発サーバーのポート番号（デフォルト: 3000）
# 複数のプロジェクトを同時に開発する場合は、重複しないポート番号を設定してください
VITE_PORT=3000
```

**注意**: 
- テーマ側の`.env`ファイルはDocker側の`.env`とは別のファイルです。テーマ開発環境とDocker開発環境は切り離されています。
- 開発モードとビルドモードの切り替えは、Docker側の`.env`ファイルの`WP_DEBUG`設定で行います。

### 開発モードとビルドモードの切り替え

#### 開発モード（HMR対応）

開発中は開発モードを使用します。ホットリロードが有効になり、ファイルを編集すると自動的にブラウザが更新されます。

**手順**:

1. Docker側の`.env`ファイルで`WP_DEBUG=true`に設定（デフォルトで`true`）
2. Vite開発サーバーを起動:
   ```bash
   npm run dev
   ```
3. WordPressにアクセス（`http://localhost:8080`など）
4. `src/`ディレクトリのファイルを編集すると、自動的にブラウザが更新されます

**特徴**:
- ホットリロード（HMR）が有効
- ソースマップが生成される
- ビルド時間が短い
- 最適化されていない（開発用）

#### ビルドモード（検証用）

ビルドしたファイルを検証する場合は、ビルドモードを使用します。

**手順**:

1. ビルドを実行:
   ```bash
   npm run build
   ```
2. Docker側の`.env`ファイルで`WP_DEBUG=false`に設定
3. WordPressコンテナを再起動:
   ```bash
   docker compose restart wordpress
   ```
4. WordPressのページをリロード
5. ビルド済みファイル（`assets/`ディレクトリ）から読み込まれます

**特徴**:
- 最適化・ミニファイされたファイルが読み込まれる
- 本番環境と同じ状態で検証可能
- ホットリロードは無効

**注意**: Docker側の`.env`ファイルで`WP_DEBUG`を変更した場合は、WordPressコンテナを再起動する必要があります。

## 開発フロー

### 開発時の手順

1. Docker側の`.env`ファイルで`WP_DEBUG=true`に設定（デフォルトで`true`）
2. Vite開発サーバーを起動:
   ```bash
   npm run dev
   ```
3. `src/`ディレクトリでソースファイルを編集
4. 変更が自動的に検知され、ブラウザが自動更新される（HMR）

### ビルド検証時の手順

1. ビルドを実行:
   ```bash
   npm run build
   ```
2. Docker側の`.env`ファイルで`WP_DEBUG=false`に設定
3. WordPressコンテナを再起動:
   ```bash
   docker compose restart wordpress
   ```
4. WordPressのページをリロードして動作確認
5. 問題がなければ、再度`WP_DEBUG=true`に戻して開発を継続

### 本番デプロイ時

1. `npm run build` を実行
2. 最適化・ミニファイされたファイルが `assets/` に出力される
3. `assets/` ディレクトリの内容をデプロイ

## ディレクトリ構造

```
nyardpress/
├── src/              # ソースファイル（開発用）
│   ├── js/           # TypeScriptファイル
│   └── css/          # Tailwind CSSファイル
├── assets/           # ビルド成果物（デプロイ用）
│   ├── js/           # ビルド済みJavaScript
│   └── css/          # ビルド済みCSS
├── views/            # Twigテンプレート
├── package.json      # npm設定
├── vite.config.ts    # Vite設定
├── tsconfig.json     # TypeScript設定
└── tailwind.config.js # Tailwind設定
```

## コーディングガイドライン

### Hookの処理

WordPressのhook（アクション・フィルター）を登録する際は、基本的に即時関数（無名関数）を使用してください。

**推奨**:
```php
add_action('init', function() {
    // 処理内容
});
```

**非推奨**:
```php
function my_function() {
    // 処理内容
}
add_action('init', 'my_function');
```

即時関数を使用することで、関数名の衝突を防ぎ、コードの可読性と保守性が向上します。

### 関数名の命名規則

テーマ内で定義する関数は、`nya_`を接頭辞として使用してください。

**推奨**:
```php
function nya_load_env() {
    // 処理内容
}
```

**非推奨**:
```php
function nyardpress_load_env() {
    // 処理内容
}
```

`nya_`接頭辞を使用することで、関数名を簡潔に保ち、コードの可読性が向上します。

## 開発フロー

1. `src/` ディレクトリでソースファイルを編集
2. `npm run dev` で開発サーバーを起動（HMR対応）
3. `npm run build` で本番用にビルド
4. ビルド成果物は `assets/` に出力される

## トラブルシューティング

### ホットリロードが動作しない

1. Vite開発サーバーが起動しているか確認:
   ```bash
   # 別のターミナルで確認
   lsof -i :3000
   ```
2. Docker側の`.env`ファイルで`WP_DEBUG=true`が設定されているか確認
3. WordPressコンテナが再起動されているか確認（`.env`を変更した場合）
4. ブラウザのコンソールでエラーがないか確認
5. WordPressのページをハードリロード（Cmd+Shift+R / Ctrl+Shift+R）

### ビルド済みファイルが読み込まれない

1. ビルドが正常に完了しているか確認:
   ```bash
   npm run build
   ```
2. `assets/.vite/manifest.json`が存在するか確認
3. Docker側の`.env`ファイルで`WP_DEBUG=false`が設定されているか確認
4. WordPressコンテナを再起動:
   ```bash
   docker compose restart wordpress
   ```
5. WordPressのページをハードリロード

### ポートが重複している

複数のプロジェクトを同時に開発する場合、`.env`ファイルで`VITE_PORT`を変更してください:

```env
VITE_PORT=3001
```

変更後、Vite開発サーバーを再起動してください。

## 注意事項

- `src/` ディレクトリは開発用のみ（Gitに含める）
- `assets/` ディレクトリのビルド成果物はGitに含める
- Twigテンプレート（`views/`）でTailwindクラスを使用可能
- `.env`ファイルはGitに含めない（`.gitignore`に追加推奨）

