<?php
/**
 * ProductCategory カスタムTermクラス
 *
 * 'product_category' タクソノミー用のカスタムTermクラス
 * このファイルを参考に、他のタクソノミー用のクラスを作成してください。
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * ProductCategory クラス
 *
 * Timber\Term を拡張して、商品カテゴリータクソノミー専用のメソッドを追加
 */
class ProductCategory extends \Timber\Term {
    /**
     * カテゴリー画像のURLを取得
     *
     * @param string $size 画像サイズ
     * @return string 画像URL
     */
    public function category_image($size = 'full') {
        $image_id = $this->meta('category_image');
        if ($image_id) {
            $image = new \Timber\Image($image_id);
            return $image->src($size);
        }
        return '';
    }

    /**
     * カテゴリーカラーを取得
     *
     * @return string カラーコード
     */
    public function category_color() {
        $color = $this->meta('category_color');
        return $color ?: '#000000';
    }

    /**
     * このカテゴリーに属する商品数を取得
     *
     * @return int 商品数
     */
    public function product_count() {
        $args = array(
            'post_type' => 'product',
            'posts_per_page' => -1,
            'tax_query' => array(
                array(
                    'taxonomy' => 'product_category',
                    'field' => 'term_id',
                    'terms' => $this->ID,
                ),
            ),
        );
        $query = new WP_Query($args);
        return $query->found_posts;
    }
}

