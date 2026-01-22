#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { loadConfig } = require('./config');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// プロンプトを表示して入力を受け取る関数
function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

// 既存の.envファイルを読み込む関数
function loadEnvFile(envPath) {
  const env = {};
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    content.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...values] = trimmed.split('=');
        if (key) {
          env[key.trim()] = values.join('=').trim();
        }
      }
    });
  }
  return env;
}

// .envファイルを保存する関数
function saveEnvFile(envPath, env) {
  const samplePath = path.join(__dirname, '..', '.env.sample');
  let template = '';

  if (fs.existsSync(samplePath)) {
    template = fs.readFileSync(samplePath, 'utf8');
  } else {
    console.error('❌ .env.sampleが存在しません');
    process.exit(1);
  }

  // 環境変数を置換
  let content = template;
  Object.keys(env).forEach(key => {
    const value = env[key];
    // ${変数名}の形式を置換
    content = content.replace(new RegExp(`\\$\\{${key}\\}`, 'g'), value);
    // 既存の値を更新
    const regex = new RegExp(`^${key}=.*$`, 'm');
    if (regex.test(content)) {
      content = content.replace(regex, `${key}=${value}`);
    } else {
      // 変数が存在しない場合は追加
      if (!content.includes(`${key}=`)) {
        content += `\n${key}=${value}`;
      }
    }
  });

  fs.writeFileSync(envPath, content, 'utf8');
}


async function main() {
  console.log('🚀 WordPress開発環境セットアップ\n');

  const envPath = path.join(__dirname, '..', '.env');
  const existingEnv = loadEnvFile(envPath);

  // 既存の.envファイルから値を読み込む
  const env = {
    ...existingEnv,
  };

  // 設定値を確認
  console.log('📝 設定値（Enterで既存の値またはデフォルト値を使用）\n');

  // 設定ファイルからテーマ名を読み取る
  const config = loadConfig();

  const prompts = [
    { key: 'WP_PORT', label: 'WordPressポート番号', default: existingEnv.WP_PORT || '8080' },
    { key: 'DB_PORT', label: 'MySQLポート番号', default: existingEnv.DB_PORT || '3306' },
    { key: 'SMTP_PORT', label: 'SMTPポート番号', default: existingEnv.SMTP_PORT || '1025' },
    { key: 'MAILPIT_PORT', label: 'Mailpitポート番号', default: existingEnv.MAILPIT_PORT || '8025' },
    { key: 'VITE_PORT', label: 'Viteポート番号', default: existingEnv.VITE_PORT || '3000' },
  ];

  for (const prompt of prompts) {
    const value = await question(`${prompt.label} [${prompt.default}]: `);
    env[prompt.key] = value.trim() || prompt.default;
  }

  // 設定ファイルからテーマ名を.envファイルに書き込む（docker-compose.ymlで環境変数として使用）
  env.THEME_NAME = config.themeName;
  env.WP_ROOT = config.wpRoot;

  // .envファイルを保存
  saveEnvFile(envPath, env);
  console.log(`\n✅ .envファイルを作成しました: ${envPath}`);

  console.log('\n✨ セットアップが完了しました！');
  console.log(`\n📋 設定内容:`);
  console.log(`   WordPressポート: ${env.WP_PORT}`);
  console.log(`   MySQLポート: ${env.DB_PORT}`);
  console.log(`   SMTPポート: ${env.SMTP_PORT}`);
  console.log(`   Mailpitポート: ${env.MAILPIT_PORT}`);
  console.log(`   テーマ名: ${config.themeName}`);
  console.log(`   WPインストールディレクトリ: ${config.wpRoot}`);

  rl.close();
}

main().catch(error => {
  console.error('❌ エラーが発生しました:', error);
  rl.close();
  process.exit(1);
});

