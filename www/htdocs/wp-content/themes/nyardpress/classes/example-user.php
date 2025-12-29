<?php
/**
 * AdminUser カスタムUserクラス
 *
 * 'administrator' ロール用のカスタムUserクラス
 * このファイルを参考に、他のユーザーロール用のクラスを作成してください。
 *
 * @package Nyardpress
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * AdminUser クラス
 *
 * Timber\User を拡張して、管理者ユーザー専用のメソッドを追加
 */
class AdminUser extends \Timber\User {
    /**
     * ユーザーの表示名を取得（フォールバック付き）
     *
     * @return string 表示名
     */
    public function display_name() {
        return $this->name ?: $this->user_nicename;
    }

    /**
     * アバター画像のURLを取得
     *
     * @param int $size 画像サイズ
     * @return string アバター画像URL
     */
    public function avatar_url($size = 96) {
        return get_avatar_url($this->ID, array('size' => $size));
    }

    /**
     * ユーザーの投稿数を取得
     *
     * @return int 投稿数
     */
    public function post_count() {
        return count_user_posts($this->ID);
    }

    /**
     * ユーザーの権限レベルを取得
     *
     * @return string 権限レベル
     */
    public function capability_level() {
        if ($this->has_cap('administrator')) {
            return '管理者';
        } elseif ($this->has_cap('editor')) {
            return '編集者';
        } elseif ($this->has_cap('author')) {
            return '投稿者';
        } else {
            return '購読者';
        }
    }
}

