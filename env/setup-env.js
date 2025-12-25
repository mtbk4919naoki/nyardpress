#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

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
  const samplePath = path.join(__dirname, '.env.sample');
  let template = '';

  if (fs.existsSync(samplePath)) {
    template = fs.readFileSync(samplePath, 'utf8');
  } else {
    // デフォルトテンプレート
    template = `# WordPress開発環境設定ファイル
# ============================================
# このファイルをコピーして .env として使用してください
# ============================================

# WordPressポート番号（デフォルト: 8080）
WORDPRESS_PORT=8080

# テーマ名（デフォルト: nyardpress）
THEME_NAME=nyardpress
`;
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

  const envPath = path.join(__dirname, '.env');
  const existingEnv = loadEnvFile(envPath);

  // 既存の.envファイルから値を読み込む
  const env = {
    ...existingEnv,
  };

  // 設定値を確認
  console.log('📝 設定値（Enterで既存の値またはデフォルト値を使用）\n');

  const prompts = [
    { key: 'WORDPRESS_PORT', label: 'WordPressポート番号', default: existingEnv.WORDPRESS_PORT || '8080' },
    { key: 'THEME_NAME', label: 'テーマ名', default: existingEnv.THEME_NAME || 'nyardpress' },
  ];

  for (const prompt of prompts) {
    const value = await question(`${prompt.label} [${prompt.default}]: `);
    env[prompt.key] = value.trim() || prompt.default;
  }

  // .envファイルを保存
  saveEnvFile(envPath, env);
  console.log(`\n✅ .envファイルを作成しました: ${envPath}`);

  console.log('\n✨ セットアップが完了しました！');
  console.log(`\n📋 設定内容:`);
  console.log(`   WordPressポート: ${env.WORDPRESS_PORT}`);
  console.log(`   テーマ名: ${env.THEME_NAME}`);
  console.log(`\n📝 注意:`);
  console.log(`   MySQL設定とWordPress管理ユーザー情報は docker-compose.yml に直接設定されています`);
  console.log(`   変更する場合は docker-compose.yml を編集してください`);
  console.log(`\n🚀 次のステップ:`);
  console.log(`   npm run setup でComposer依存関係をインストールしてコンテナを起動してください`);

  rl.close();
}

main().catch(error => {
  console.error('❌ エラーが発生しました:', error);
  rl.close();
  process.exit(1);
});

