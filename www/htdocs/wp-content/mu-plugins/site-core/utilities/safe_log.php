<?php

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

/**
 * 安全にログを出力するためのユーティリティ
 * 
 * テーマ側からも使用可能です。
 * 例: safe_log('This is a test message', 'info', ['context' => 'value']);
 * 
 * @param string $message ログメッセージ
 * @param string $level ログレベル (info, warning, error)
 * @param array|null $context 追加コンテキスト情報
 */
if (!function_exists('safe_log')) {
    function safe_log($message, $level = 'info', $context = [])
    {
  /**
         * テキストをサニタイズする内部関数
         * 前後の空白をトリム、改行除去、制御文字を16進数表記に置換
         * 
   * @param string $text サニタイズするテキスト
   * @return string サニタイズされたテキスト
   */
        $sanitize_text = function ($text) {
    $text = trim($text);
    $text = preg_replace('/[\r\n]+/', '', $text);
    $text = preg_replace_callback('/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/', function ($matches) {
      return '[0x' . strtoupper(bin2hex($matches[0])) . ']';
    }, $text);
    return $text;
        };

    $timestamp = date('Y-m-d H:i:s');
        $sanitized_message = $sanitize_text($message);
    $log_entry = "[{$timestamp}] [{$level}] {$sanitized_message}";

    if (!empty($context)) {
            $sanitized_context = array_map(function ($value) use ($sanitize_text) {
                return is_string($value) ? $sanitize_text($value) : $value;
      }, $context);
      $log_entry .= ' ' . json_encode($sanitized_context, JSON_UNESCAPED_UNICODE);
    }

    return error_log($log_entry);
  }
}
