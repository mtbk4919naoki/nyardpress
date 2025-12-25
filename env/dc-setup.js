#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const projectRoot = path.join(__dirname, '..');

// .envファイルからTHEME_NAMEを読み取る
let themeName = 'nyardpress'; // デフォルト値
const envPath = path.join(projectRoot, 'env', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  const themeMatch = envContent.match(/^THEME_NAME=(.+)$/m);
  if (themeMatch) {
    themeName = themeMatch[1].trim();
  }
}

console.log('📦 テーマとプラグインのComposer依存関係をインストール中...');

// Composer installを実行するディレクトリのリスト
const composerDirs = [
  'www/htdocs/wp-content/plugins',
  `www/htdocs/wp-content/themes/${themeName}`,
  'www/htdocs/wp-content/mu-plugins/site-core'
];

let hasError = false;

for (const dir of composerDirs) {
  const fullPath = path.join(projectRoot, dir);
  const composerJson = path.join(fullPath, 'composer.json');

  if (fs.existsSync(composerJson)) {
    const composerLock = path.join(fullPath, 'composer.lock');
    const hasLockFile = fs.existsSync(composerLock);

    // composer.lockが存在する場合はinstall、存在しないかcomposer.jsonが変更された場合はupdate
    const command = hasLockFile ? 'composer install' : 'composer update';
    const commandLabel = hasLockFile ? 'install' : 'update';

    console.log(`\n📦 ${dir} のComposer ${commandLabel}を実行中...`);
    try {
      execSync(`${command} --no-interaction --prefer-dist`, {
        stdio: 'inherit',
        cwd: fullPath
      });
      console.log(`✅ ${dir} のComposer ${commandLabel}が完了しました`);
    } catch (error) {
      // installが失敗した場合（lock fileが古い場合など）、updateを試行
      if (hasLockFile && error.status !== 0) {
        console.log(`⚠️  ${dir} のComposer installに失敗しました。composer updateを試行します...`);
        try {
          execSync('composer update --no-interaction --prefer-dist', {
            stdio: 'inherit',
            cwd: fullPath
          });
          console.log(`✅ ${dir} のComposer updateが完了しました`);
        } catch (updateError) {
          console.error(`❌ ${dir} のComposer updateに失敗しました`);
          hasError = true;
        }
      } else {
        console.error(`❌ ${dir} のComposer ${commandLabel}に失敗しました`);
        hasError = true;
      }
    }
  } else {
    console.log(`ℹ️  ${dir} にcomposer.jsonが見つかりません（スキップします）`);
  }
}

if (hasError) {
  console.error('\n❌ 一部のComposer installに失敗しました');
  process.exit(1);
} else {
  console.log('\n✅ すべてのComposer installが完了しました');
}

