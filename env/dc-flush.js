#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('🧹 ボリュームとキャッシュをクリア中...');

try {
  const dockerComposePath = path.join(__dirname, '..', 'docker-compose.yml');
  const projectRoot = path.join(__dirname, '..');
  
  // コンテナを停止
  console.log('⏸️  コンテナを停止中...');
  try {
    execSync(`docker-compose -f ${dockerComposePath} stop`, {
      stdio: 'inherit',
      cwd: projectRoot
    });
  } catch (error) {
    console.log('コンテナは既に停止しているか、存在しません');
  }
  
  // ボリュームを削除（データベースのデータをクリア）
  // down -v でボリュームを削除（コンテナも削除されるが、イメージは保持される）
  console.log('🗑️  ボリュームとコンテナを削除中...');
  try {
    execSync(`docker-compose -f ${dockerComposePath} down -v`, {
      stdio: 'inherit',
      cwd: projectRoot
    });
    console.log('  ✅ ボリュームとコンテナを削除しました');
  } catch (error) {
    console.log('  ⚠️  ボリュームとコンテナの削除に失敗しました（既に削除されている可能性があります）');
  }
  
  // コンテナを再作成（ボリュームは再作成される、イメージは再利用される）
  console.log('🔄 コンテナを再作成中...');
  try {
    execSync(`docker-compose -f ${dockerComposePath} up -d`, {
      stdio: 'inherit',
      cwd: projectRoot
    });
    console.log('  ✅ コンテナを再作成しました');
  } catch (error) {
    console.log('  ⚠️  コンテナの再作成に失敗しました');
  }
  
  // このプロジェクトのビルドキャッシュのみをクリア（オプション）
  // 注意: 他のプロジェクトのキャッシュは削除しません
  console.log('ℹ️  ビルドキャッシュは保持されます（他のプロジェクトに影響しません）');
  
  // WordPressのセットアップ完了フラグを削除（次回起動時に再セットアップされる）
  const setupFlagPath = path.join(projectRoot, 'www', 'htdocs', '.setup-completed');
  if (fs.existsSync(setupFlagPath)) {
    console.log('🗑️  セットアップフラグを削除中...');
    fs.unlinkSync(setupFlagPath);
  }
  
  console.log('✅ フラッシュが完了しました');
  console.log('\n📋 注意:');
  console.log('   - このプロジェクトのボリュームとコンテナのみを削除しました');
  console.log('   - 他のプロジェクトのDockerリソースには影響しません');
  console.log('   - コンテナは既に再作成されています');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}

