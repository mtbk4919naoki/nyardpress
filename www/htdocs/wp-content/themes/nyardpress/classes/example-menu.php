<?php
/**
 * PrimaryMenu カスタムMenuクラス
 *
 * 'primary' メニュー用のカスタムMenuクラス
 * このファイルを参考に、他のメニュー用のクラスを作成してください。
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * PrimaryMenu クラス
 *
 * Timber\Menu を拡張して、プライマリーメニュー専用のメソッドを追加
 */
class PrimaryMenu extends \Timber\Menu {
    /**
     * アクティブなメニュー項目を取得
     *
     * @return array アクティブなメニュー項目の配列
     */
    public function active_items() {
        $active = array();
        foreach ($this->items as $item) {
            if ($item->current) {
                $active[] = $item;
            }
        }
        return $active;
    }

    /**
     * メニュー項目を階層構造で取得
     *
     * @return array 階層構造のメニュー項目
     */
    public function hierarchical_items() {
        $items = array();
        foreach ($this->items as $item) {
            if ($item->children) {
                $items[] = $item;
            }
        }
        return $items;
    }
}

