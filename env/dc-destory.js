#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

console.log('🗑️  WordPressコンテナを削除中...');

try {
  // docker-compose down -v でコンテナとボリュームを完全に削除
  const dockerComposePath = path.join(__dirname, '..', 'docker-compose.yml');
  execSync(`docker-compose -f ${dockerComposePath} down -v --remove-orphans`, {
    stdio: 'inherit',
    cwd: path.join(__dirname, '..')
  });
  
  console.log('✅ コンテナとボリュームの削除が完了しました');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}
