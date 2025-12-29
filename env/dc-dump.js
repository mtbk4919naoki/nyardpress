#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const projectRoot = path.join(__dirname, '..');
const dockerComposePath = path.join(projectRoot, 'docker-compose.yml');

// 現在のプロジェクトで起動しているWordPressコンテナ名を取得する関数
function getWordPressContainerName() {
  try {
    // docker-compose.ymlからサービス名を取得
    const dockerComposeContent = fs.readFileSync(dockerComposePath, 'utf8');
    const serviceMatch = dockerComposeContent.match(/^\s+wordpress:/m);
    if (!serviceMatch) {
      throw new Error('docker-compose.ymlにwordpressサービスが見つかりません');
    }

    // docker-compose psで起動中のコンテナを取得
    const output = execSync(`docker-compose -f ${dockerComposePath} ps -q wordpress`, {
      stdio: 'pipe',
      cwd: projectRoot,
      encoding: 'utf8'
    }).trim();

    if (!output) {
      throw new Error('WordPressコンテナが起動していません');
    }

    // コンテナIDからコンテナ名を取得
    const containerId = output.split('\n')[0];
    const containerName = execSync(`docker inspect --format='{{.Name}}' ${containerId}`, {
      stdio: 'pipe',
      cwd: projectRoot,
      encoding: 'utf8'
    }).trim().replace(/^\//, ''); // 先頭の/を削除

    return containerName;
  } catch (error) {
    // フォールバック: docker-compose.ymlからwordpressサービスの固定コンテナ名を読み取る
    try {
      const dockerComposeContent = fs.readFileSync(dockerComposePath, 'utf8');
      // wordpressサービスのセクションを抽出
      const wordpressMatch = dockerComposeContent.match(/^\s+wordpress:([\s\S]*?)(?=^\s+\w+:|$)/m);
      if (wordpressMatch) {
        const wordpressSection = wordpressMatch[1];
        // wordpressセクション内のcontainer_nameを探す
        const containerNameMatch = wordpressSection.match(/container_name:\s*(.+)/);
        if (containerNameMatch) {
          const fixedName = containerNameMatch[1].trim();
          // 固定名でコンテナが起動しているか確認
          try {
            execSync(`docker ps --filter "name=${fixedName}" --filter "status=running" --format "{{.Names}}"`, {
              stdio: 'pipe',
              cwd: projectRoot
            });
            return fixedName;
          } catch (e) {
            throw new Error('WordPressコンテナが起動していません');
          }
        }
      }
    } catch (e) {
      // エラーをそのまま投げる
    }
    throw error;
  }
}

// コマンドライン引数からダンプ名のサフィックスを取得（オプション）
const dumpSuffix = process.argv[2];

if (dumpSuffix) {
  console.log(`📦 WordPressのダンプを開始します（名前: ${dumpSuffix}）...`);
} else {
  console.log('📦 WordPressのダンプを開始します...');
}

try {
  // 現在のプロジェクトで起動しているWordPressコンテナ名を取得
  let containerName;
  try {
    containerName = getWordPressContainerName();
  } catch (error) {
    console.error('❌ コンテナが起動していません。先に `npm run dc:build` を実行してください。');
    process.exit(1);
  }

  // コンテナ内でdump.shを実行（引数がある場合は渡す）
  const dumpCommand = dumpSuffix
    ? `docker exec -it ${containerName} /opt/docker/bin/dump.sh ${dumpSuffix}`
    : `docker exec -it ${containerName} /opt/docker/bin/dump.sh`;

  execSync(dumpCommand, {
    stdio: 'inherit',
    cwd: projectRoot
  });

  console.log('✅ ダンプが完了しました');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}

