#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

console.log('🔨 WordPressコンテナを再構成中...');

try {
  const dockerComposePath = path.join(__dirname, '..', 'docker-compose.yml');
  const projectRoot = path.join(__dirname, '..');
  
  // 既存のコンテナを停止・削除
  console.log('📦 既存のコンテナを停止中...');
  try {
    execSync(`docker-compose -f ${dockerComposePath} down`, {
      stdio: 'inherit',
      cwd: projectRoot
    });
  } catch (error) {
    // コンテナが存在しない場合は無視
    console.log('既存のコンテナは存在しません');
  }
  
  // イメージを再ビルド
  console.log('🔨 Dockerイメージをビルド中...');
  execSync(`docker-compose -f ${dockerComposePath} build --no-cache`, {
    stdio: 'inherit',
    cwd: projectRoot
  });
  
  // コンテナを起動
  console.log('🚀 コンテナを起動中...');
  execSync(`docker-compose -f ${dockerComposePath} up -d`, {
    stdio: 'inherit',
    cwd: projectRoot
  });
  
  console.log('✅ WordPressコンテナの再構成が完了しました');
  console.log('🌐 WordPress: http://localhost:8080');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}

