<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Twig環境を取得または作成
 * 
 * @param string $template_dir テンプレートディレクトリのパス
 * @return \Twig\Environment|null
 */
if (!function_exists('nya_get_twig')) {
    function nya_get_twig($template_dir = null) {
        static $twig_instances = array();

        // テンプレートディレクトリが指定されていない場合はnullを返す
        if (!$template_dir) {
            return null;
        }

        // 既に作成されたインスタンスがある場合は再利用
        if (isset($twig_instances[$template_dir])) {
            return $twig_instances[$template_dir];
        }

        // Twigが利用可能か確認
        if (!class_exists('Twig\\Environment')) {
            return null;
        }

        // テンプレートディレクトリが存在するか確認
        if (!is_dir($template_dir)) {
            return null;
        }

        try {
            // Twigローダーを作成
            $loader = new \Twig\Loader\FilesystemLoader($template_dir);
            
            // Twig環境を作成（開発モードの場合はデバッグを有効化）
            $twig = new \Twig\Environment($loader, array(
                'cache' => false, // 開発環境ではキャッシュを無効化
                'debug' => defined('WP_DEBUG') && WP_DEBUG,
                'auto_reload' => defined('WP_DEBUG') && WP_DEBUG,
            ));

            // デバッグモードの場合はデバッグ拡張機能を追加
            if (defined('WP_DEBUG') && WP_DEBUG && class_exists('Twig\\Extension\\DebugExtension')) {
                $twig->addExtension(new \Twig\Extension\DebugExtension());
            }

            // インスタンスをキャッシュ
            $twig_instances[$template_dir] = $twig;

            return $twig;
        } catch (Exception $e) {
            error_log('nya_get_twig error: ' . $e->getMessage());
            return null;
        }
    }
}

