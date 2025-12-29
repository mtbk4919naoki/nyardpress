# Site Core

WordPressのカスタム投稿タイプ、カスタムタクソノミー、Carbon Fieldsを管理するMUプラグインです。

## ディレクトリ構造

```
site-core/
├── posttypes/      # カスタム投稿タイプ
├── taxonomies/     # カスタムタクソノミー
├── fields/         # Carbon Fields設定
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

