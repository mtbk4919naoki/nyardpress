#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

console.log('🗑️  WordPressコンテナを削除中...');

try {
  const projectRoot = path.join(__dirname, '..');
  const dockerComposePath = path.join(projectRoot, 'docker-compose.yml');

  // docker-compose down -v でコンテナとボリュームを完全に削除
  execSync(`docker-compose -f ${dockerComposePath} down -v --remove-orphans`, {
    stdio: 'inherit',
    cwd: projectRoot
  });

  console.log('✅ コンテナとボリュームの削除が完了しました');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}
