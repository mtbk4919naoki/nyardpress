<?php
/**
 * Product カスタムPostクラス
 *
 * 'product' 投稿タイプ用のカスタムPostクラス
 * このファイルを参考に、他の投稿タイプ用のクラスを作成してください。
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Product クラス
 *
 * Timber\Post を拡張して、商品投稿タイプ専用のメソッドを追加
 */
class Product extends \Timber\Post {
    /**
     * 価格をフォーマットして返す
     *
     * @return string フォーマットされた価格
     */
    public function formatted_price() {
        $price = $this->meta('price');
        return $price ? number_format($price) . '円' : '価格未設定';
    }

    /**
     * 在庫状況を取得
     *
     * @return string 在庫状況
     */
    public function stock_status() {
        $stock = $this->meta('stock');
        if ($stock === null) {
            return '在庫情報なし';
        }
        return $stock > 0 ? '在庫あり' : '在庫切れ';
    }

    /**
     * 商品画像のURLを取得（フォールバック付き）
     *
     * @param string $size 画像サイズ
     * @return string 画像URL
     */
    public function product_image($size = 'full') {
        if ($this->thumbnail()) {
            return $this->thumbnail()->src($size);
        }
        // フォールバック画像
        return get_template_directory_uri() . '/assets/images/no-image.png';
    }
}

