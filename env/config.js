#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const projectRoot = path.join(__dirname, '..');
const configPath = path.join(projectRoot, 'nyardpress.config.json');

/**
 * 設定ファイルを読み込む
 * @returns {Object} 設定オブジェクト
 */
function loadConfig() {
  const defaultConfig = {
    themeName: 'nyardpress'
  };

  if (!fs.existsSync(configPath)) {
    // 設定ファイルが存在しない場合はデフォルト値を使用
    return defaultConfig;
  }

  try {
    const configContent = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configContent);
    return {
      ...defaultConfig,
      ...config
    };
  } catch (error) {
    console.warn(`⚠️  設定ファイルの読み込みに失敗しました: ${configPath}`);
    console.warn(`   デフォルト値を使用します: ${error.message}`);
    return defaultConfig;
  }
}

module.exports = {
  loadConfig
};

