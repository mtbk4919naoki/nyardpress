#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

const projectRoot = path.join(__dirname, '..');
const containerName = 'nyardpress_wordpress';

// コマンドライン引数からダンプ名のサフィックスを取得（オプション）
const dumpSuffix = process.argv[2];

if (dumpSuffix) {
  console.log(`📦 WordPressのダンプを開始します（名前: ${dumpSuffix}）...`);
} else {
  console.log('📦 WordPressのダンプを開始します...');
}

try {
  // コンテナが起動しているか確認
  try {
    execSync(`docker ps --filter "name=${containerName}" --filter "status=running" --format "{{.Names}}"`, {
      stdio: 'pipe',
      cwd: projectRoot
    });
  } catch (error) {
    console.error('❌ コンテナが起動していません。先に `npm run dc:build` を実行してください。');
    process.exit(1);
  }

  // コンテナ内でdump.shを実行（引数がある場合は渡す）
  const dumpCommand = dumpSuffix 
    ? `docker exec -it ${containerName} /usr/docker/bin/dump.sh ${dumpSuffix}`
    : `docker exec -it ${containerName} /usr/docker/bin/dump.sh`;
  
  execSync(dumpCommand, {
    stdio: 'inherit',
    cwd: projectRoot
  });

  console.log('✅ ダンプが完了しました');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}

