<?php
/**
 * CustomMenuItem カスタムMenuItemクラス
 *
 * カスタムメニュー項目用のカスタムMenuItemクラス
 * このファイルを参考に、他のメニュー項目用のクラスを作成してください。
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * CustomMenuItem クラス
 *
 * Timber\MenuItem を拡張して、カスタムメニュー項目専用のメソッドを追加
 */
class CustomMenuItem extends \Timber\MenuItem {
    /**
     * アイコンクラスを取得
     *
     * @return string アイコンクラス
     */
    public function icon_class() {
        $icon = $this->meta('menu_icon');
        return $icon ?: 'dashicons-menu';
    }

    /**
     * バッジテキストを取得
     *
     * @return string バッジテキスト
     */
    public function badge_text() {
        return $this->meta('badge_text') ?: '';
    }

    /**
     * メニュー項目が外部リンクかどうかを判定
     *
     * @return bool 外部リンクの場合true
     */
    public function is_external() {
        $url = $this->url;
        $site_url = home_url();
        return strpos($url, $site_url) !== 0;
    }
}

