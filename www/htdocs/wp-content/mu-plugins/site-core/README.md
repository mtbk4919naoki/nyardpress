# Site Core

WordPressのカスタム投稿タイプ、カスタムタクソノミー、Carbon Fieldsを管理するMUプラグインです。

## ディレクトリ構造

```
site-core/
├── posttypes/      # カスタム投稿タイプ
├── taxonomies/     # カスタムタクソノミー
├── fields/         # Carbon Fields設定
├── blocks/         # Gutenbergブロック
├── utilities/      # ユーティリティ関数
└── bootstrap/      # 初期化スクリプト
```

## カスタム投稿タイプの追加

1. `posttypes/` ディレクトリにPHPファイルを作成
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

## カスタムタクソノミーの追加

1. `taxonomies/` ディレクトリにPHPファイルを作成
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

## Carbon Fieldsでカスタムフィールドを追加

1. `fields/` ディレクトリにPHPファイルを作成
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

## Carbon FieldsでGutenbergブロックを追加

1. `blocks/` ディレクトリにPHPファイルを作成
2. `example-block.php` を参考に実装
3. ファイル名は `example-` で始めると自動的に読み込まれません（サンプル用）

```php
// blocks/my-block.php
use Carbon_Fields\Block;
use Carbon_Fields\Field;

add_action('carbon_fields_register_fields', function() {
    Block::make(__('マイブロック', 'nyardpress'))
        ->add_fields(array(
            Field::make('text', 'heading', __('見出し', 'nyardpress')),
            Field::make('image', 'image', __('画像', 'nyardpress')),
            Field::make('rich_text', 'content', __('コンテンツ', 'nyardpress')),
        ))
        ->set_category('layout', __('レイアウト', 'nyardpress'), 'layout')
        ->set_render_callback(function($fields, $attributes, $inner_blocks) {
            // レンダリング処理
        });
});
```

参考: [Carbon Fields - Gutenberg Blocks](https://docs.carbonfields.net/learn/containers/gutenberg-blocks.html)

## Gutenbergブロックの作成（block.json方式）

標準的なGutenbergブロックを作成するには、`block.json`を使用します。

### 新しいブロックの作成

```bash
npm run create-block [ブロック名]
```

または、対話形式で：

```bash
npm run create-block
# ブロック名を入力してください: my-block
```

**注意：** 作成されるブロックは自動的に`nya/`プレフィックスが付きます（例：`nya/my-block`）。

これにより、以下のディレクトリ構造でブロックが作成されます：

```
blocks/
└── my-block/
    ├── block.json          # ブロックのメタデータ（name: "nya/my-block"）
    ├── render.php          # ロジック
    ├── view.twig           # Twigテンプレート
    ├── src/
    │   ├── index.js        # ブロック登録
    │   └── edit.js         # エディターコンポーネント
    └── build/              # ビルド成果物（自動生成）
```

### ブロックの開発

開発モードで起動すると、ホットリロードが有効になります：

```bash
npm run start
```

すべてのブロックが同時に開発モードで起動します。各ブロックには異なるポート（3000, 3001, ...）が割り当てられます。

### ブロックのビルド

本番環境用にビルド：

```bash
npm run build
```

すべてのブロックがビルドされ、`build/`ディレクトリに成果物が生成されます。

### ブロックの自動登録

`blocks/`ディレクトリ内のサブディレクトリに`block.json`が存在する場合、WordPressが自動的にブロックを登録します。

- `block.json`の`name`プロパティがブロック名として使用されます（例：`nya/my-block`）
- `editorScript`が指定されている場合、管理画面用のスクリプトが自動的にenqueueされます
- `render`が指定されている場合、そのファイルがレンダリングコールバックとして使用されます

### ブロックの有効化/無効化設定

`blocks/blocks-config.json`でカスタムブロックとコアブロックの有効化/無効化を制御できます。

```json
{
  "disabled": [
    "example"
  ],
  "allowedBlocks": [
    "core/paragraph",
    "core/heading",
    "core/list",
    "core/image"
  ]
}
```

**設定項目：**

- `disabled`: 無効化するカスタムブロックのディレクトリ名の配列。先頭にアンダースコア（`_`）を付けると無視されます（コメント用）。
- `allowedBlocks`: 利用可能なブロックのホワイトリスト。このリストに記載されたブロックのみがエディターで使用可能になります。

**ホワイトリスト方式のメリット：**

- WordPress更新時に新しいブロックが自動的に追加されても、リストにないものは表示されません
- 明示的に許可したブロックのみが使用可能になるため、セキュリティと管理が向上します
- カスタムブロック（`nya/`で始まるブロック）は自動的に許可リストに追加されます

**設定方法：**

- `allowedBlocks`が空または未設定の場合: すべてのブロックが許可されます（従来の動作）
- `allowedBlocks`が設定されている場合: リストに記載されたブロックのみが許可されます
- 先頭アンダースコア（`_`）で始まる設定は無視されます（コメント用）

**コアブロック一覧：**

コアブロックの完全な一覧は`allowedBlocks`に記載されています。参考: [Gutenbergコアのブロック名一覧](https://zenn.dev/shimomura/articles/gutenberg-block-list)

### ブロック用CSS・JavaScriptの読み込み

ブロック用のCSS・JavaScriptファイルは自動的に読み込まれます：

- **フロントエンド用CSS**: `blocks/style.css` - `wp_enqueue_scripts`フックで読み込まれます
- **フロントエンド用JavaScript**: `blocks/script.js` - `wp_enqueue_scripts`フックで読み込まれます（`</body>`の前に出力）
- **エディター用CSS**: `blocks/editor.css` - `enqueue_block_editor_assets`フックで読み込まれます

すべてのファイルは存在する場合のみ読み込まれます。すべてのカスタムブロックのスタイルとスクリプトをこれらのファイルに記述してください。

### デフォルトの属性

新しく作成されるブロックには、以下の属性がデフォルトで含まれます：

- `content` - テキストコンテンツ（RichText）
- `number` - 数字
- `imageId`, `imageUrl`, `imageAlt` - 画像関連
- `url`, `urlText` - URL関連
- `repeat` - 繰り返し項目（配列）

不要な属性は`block.json`、`src/edit.js`、`views/block.twig`から削除してください。

### Twigテンプレート

ブロックのフロントエンド表示にはTwigテンプレートを使用します。`render.php`が自動的に`view.twig`をレンダリングします。

```twig
{# blocks/my-block/view.twig #}
<div class="{{ block_class }}">
    {% if content %}
        <div class="{{ block_class }}__content">
            {{ content|raw }}
        </div>
    {% endif %}
</div>
```

**注意：** `view.twig`はブロックディレクトリ直下に配置します（`views/`ディレクトリは使用しません）。

### 参考資料

- [Component Reference](https://developer.wordpress.org/block-editor/reference-guides/components/) - WordPress公式のコンポーネントリファレンス
- [Gutenberg Handbook](https://wordpress.github.io/gutenberg/?path=/docs/docs-introduction--page) - Gutenbergブロック開発の公式ドキュメント
- [Carbon Fields - Gutenberg Blocks](https://docs.carbonfields.net/learn/containers/gutenberg-blocks.html) - Carbon Fieldsを使ったブロック開発

## ユーティリティ関数

### use_transient

キャッシュ機能を提供します。ログイン中のユーザーはキャッシュを無視します。

```php
$value = use_transient('cache_key', function() {
    // 重い処理
    return expensive_operation();
}, 3600); // 1時間キャッシュ
```

**特徴：**
- ログイン中のユーザーは常に最新のデータを取得（キャッシュを無視）
- キャッシュの有効期限にジッター（ランダムな追加時間）を付与して、同時アクセス時の負荷を分散
- テーマ側からも使用可能

