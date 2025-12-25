#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

const projectRoot = path.join(__dirname, '..');
const containerName = 'nyardpress_wordpress';

// コマンドライン引数からダンプファイル名を取得
const dumpName = process.argv[2];

if (!dumpName) {
  console.error('❌ ダンプファイル名を指定してください');
  console.log('');
  console.log('使用方法:');
  console.log('  npm run dc:restore <ダンプファイル名>');
  console.log('');
  console.log('例:');
  console.log('  npm run dc:restore wordpress_dump_20240101_120000');
  console.log('');
  console.log('利用可能なダンプファイル:');
  try {
    const fs = require('fs');
    const dumpDir = path.join(projectRoot, 'docker', 'dump');
    if (fs.existsSync(dumpDir)) {
      const files = fs.readdirSync(dumpDir)
        .filter(file => file.endsWith('.tar.gz'))
        .map(file => file.replace('.tar.gz', ''));
      if (files.length > 0) {
        files.forEach(file => console.log(`  - ${file}`));
      } else {
        console.log('  （ダンプファイルが見つかりません）');
      }
    } else {
      console.log('  （ダンプディレクトリが存在しません）');
    }
  } catch (error) {
    console.log('  （ダンプファイルの一覧を取得できませんでした）');
  }
  process.exit(1);
}

  console.log(`📥 WordPressの復元を開始します: ${dumpName}`);
  console.log('');

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

  // ダンプファイルが存在するか確認
  const fs = require('fs');
  const dumpFile = path.join(projectRoot, 'docker', 'dump', `${dumpName}.tar.gz`);
  if (!fs.existsSync(dumpFile)) {
    console.error(`❌ ダンプファイルが見つかりません: ${dumpFile}`);
    process.exit(1);
  }

  // コンテナ内でrestore.shを実行
  execSync(`docker exec -it ${containerName} /usr/docker/bin/restore.sh ${dumpName}`, {
    stdio: 'inherit',
    cwd: projectRoot
  });

  console.log('✅ 復元が完了しました');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}

