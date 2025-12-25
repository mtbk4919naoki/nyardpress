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
    template = `# WordPress 開発環境設定ファイル
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress
MYSQL_ROOT_PASSWORD=rootpassword
WORDPRESS_DB_HOST=db
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress
WORDPRESS_DB_NAME=wordpress
WORDPRESS_URL=http://localhost:8080
WORDPRESS_TITLE=\${PROJECT_NAME}
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=admin
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_PORT=8080
PROJECT_NAME=\${PROJECT_NAME}
THEME_NAME=\${THEME_NAME}
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

// docker-compose.ymlを更新する関数
// 注意: コンテナ名、ボリューム名、ネットワーク名は固定値（nyardpress）を使用しています
// 安定性を重視するため、動的な変更は行いません
// 別のプロジェクトで使用する場合は、docker-compose.ymlを直接編集してください
function updateDockerCompose(projectName, themeName) {
  const dockerComposePath = path.join(__dirname, '..', 'docker-compose.yml');
  if (!fs.existsSync(dockerComposePath)) {
    console.error('docker-compose.ymlが見つかりません');
    return;
  }
  
  // docker-compose.ymlは固定値を使用しているため、更新処理は不要
  // 将来的にテーマ名の動的変更が必要な場合は、ここに処理を追加してください
  console.log('ℹ️  docker-compose.ymlは固定値を使用しています（更新不要）');
}

async function main() {
  console.log('🚀 WordPress開発環境セットアップ\n');
  
  const envPath = path.join(__dirname, '.env');
  const existingEnv = loadEnvFile(envPath);
  
  // PROJECT_NAMEを取得
  const projectNamePrompt = existingEnv.PROJECT_NAME 
    ? `プロジェクト名 [${existingEnv.PROJECT_NAME}]: `
    : 'プロジェクト名: ';
  let projectName = await question(projectNamePrompt);
  projectName = projectName.trim() || existingEnv.PROJECT_NAME || 'nyardpress';
  
  // THEME_NAMEを取得（入力なしでPROJECT_NAMEと同じ）
  const themeNamePrompt = existingEnv.THEME_NAME
    ? `テーマ名 [${existingEnv.THEME_NAME}] (Enterで${projectName}と同じ): `
    : `テーマ名 (Enterで${projectName}と同じ): `;
  let themeName = await question(themeNamePrompt);
  themeName = themeName.trim() || existingEnv.THEME_NAME || projectName;
  
  // 既存の.envファイルから値を読み込む
  const env = {
    ...existingEnv,
    PROJECT_NAME: projectName,
    THEME_NAME: themeName,
    WORDPRESS_TITLE: existingEnv.WORDPRESS_TITLE || projectName,
  };
  
  // 他の設定値も確認
  console.log('\n📝 その他の設定（Enterで既存の値またはデフォルト値を使用）\n');
  
  const prompts = [
    { key: 'WORDPRESS_URL', label: 'WordPress URL', default: existingEnv.WORDPRESS_URL || 'http://localhost:8080' },
    { key: 'WORDPRESS_ADMIN_USER', label: '管理画面ユーザー名', default: existingEnv.WORDPRESS_ADMIN_USER || 'admin' },
    { key: 'WORDPRESS_ADMIN_PASSWORD', label: '管理画面パスワード', default: existingEnv.WORDPRESS_ADMIN_PASSWORD || 'admin' },
    { key: 'WORDPRESS_ADMIN_EMAIL', label: '管理画面メールアドレス', default: existingEnv.WORDPRESS_ADMIN_EMAIL || 'admin@example.com' },
    { key: 'WORDPRESS_PORT', label: 'WordPressポート', default: existingEnv.WORDPRESS_PORT || '8080' },
    { key: 'MYSQL_DATABASE', label: 'データベース名', default: existingEnv.MYSQL_DATABASE || 'wordpress' },
    { key: 'MYSQL_USER', label: 'データベースユーザー名', default: existingEnv.MYSQL_USER || 'wordpress' },
    { key: 'MYSQL_PASSWORD', label: 'データベースパスワード', default: existingEnv.MYSQL_PASSWORD || 'wordpress' },
    { key: 'MYSQL_ROOT_PASSWORD', label: 'MySQL rootパスワード', default: existingEnv.MYSQL_ROOT_PASSWORD || 'rootpassword' },
  ];
  
  for (const prompt of prompts) {
    const value = await question(`${prompt.label} [${prompt.default}]: `);
    env[prompt.key] = value.trim() || prompt.default;
  }
  
  // データベース接続設定を統一
  env.WORDPRESS_DB_HOST = env.WORDPRESS_DB_HOST || 'db';
  env.WORDPRESS_DB_USER = env.MYSQL_USER;
  env.WORDPRESS_DB_PASSWORD = env.MYSQL_PASSWORD;
  env.WORDPRESS_DB_NAME = env.MYSQL_DATABASE;
  
  // .envファイルを保存
  saveEnvFile(envPath, env);
  console.log(`\n✅ .envファイルを作成しました: ${envPath}`);
  
  // docker-compose.ymlを更新
  updateDockerCompose(projectName, themeName);
  
  console.log('\n✨ セットアップが完了しました！');
  console.log(`\n📋 設定内容:`);
  console.log(`   プロジェクト名: ${projectName}`);
  console.log(`   テーマ名: ${themeName}`);
  console.log(`   WordPress URL: ${env.WORDPRESS_URL}`);
  console.log(`\n🚀 次のステップ:`);
  console.log(`   npm run dc:build でコンテナを起動してください`);
  
  rl.close();
}

main().catch(error => {
  console.error('❌ エラーが発生しました:', error);
  rl.close();
  process.exit(1);
});

