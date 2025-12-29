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

// 最新のダンプファイルを取得する関数
function getLatestDump() {
  const dumpDir = path.join(projectRoot, 'docker', 'dump');
  if (!fs.existsSync(dumpDir)) {
    return null;
  }

  const files = fs.readdirSync(dumpDir)
    .filter(file => file.endsWith('.tar.gz'))
    .map(file => {
      const name = file.replace('.tar.gz', '');
      // ファイル名から日時を抽出: wordpress_dump_YYYYMMDD_HHMMSS または wordpress_dump_YYYYMMDD_HHMMSS_suffix
      const match = name.match(/^wordpress_dump_(\d{8}_\d{6})(?:_(.+))?$/);
      if (match) {
        // YYYYMMDD_HHMMSS を Date オブジェクトに変換
        const dateStr = match[1]; // "20240101_120000"
        const year = dateStr.substring(0, 4);
        const month = dateStr.substring(4, 6);
        const day = dateStr.substring(6, 8);
        const hour = dateStr.substring(9, 11);
        const minute = dateStr.substring(11, 13);
        const second = dateStr.substring(13, 15);
        const date = new Date(year, month - 1, day, hour, minute, second);

        return {
          name: name,
          fullName: file,
          date: date
        };
      }
      // パターンに一致しない場合は、ファイル名をそのまま使用（辞書順ソート）
      return {
        name: name,
        fullName: file,
        date: new Date(0) // 古い日付として扱う
      };
    });

  if (files.length === 0) {
    return null;
  }

  // 日時でソート（新しい順）、同じ場合はファイル名でソート
  files.sort((a, b) => {
    if (b.date.getTime() !== a.date.getTime()) {
      return b.date.getTime() - a.date.getTime();
    }
    // 日時が同じ場合はファイル名で辞書順（降順）
    return b.name.localeCompare(a.name);
  });

  return files[0].name;
}

// コマンドライン引数からダンプファイル名を取得
let dumpName = process.argv[2];

// --latest オプションのチェック
if (dumpName === '--latest') {
  dumpName = getLatestDump();
  if (!dumpName) {
    console.error('❌ ダンプファイルが見つかりません');
    process.exit(1);
  }
  console.log(`📋 最新のダンプファイルを自動選択: ${dumpName}`);
}

if (!dumpName) {
  console.error('❌ ダンプファイル名を指定してください');
  console.log('');
  console.log('使用方法:');
  console.log('  npm run dc:restore <ダンプファイル名>');
  console.log('  npm run dc:restore --latest');
  console.log('');
  console.log('例:');
  console.log('  npm run dc:restore wordpress_dump_20240101_120000');
  console.log('  npm run dc:restore --latest');
  console.log('');
  console.log('利用可能なダンプファイル:');
  try {
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
  // 現在のプロジェクトで起動しているWordPressコンテナ名を取得
  let containerName;
  try {
    containerName = getWordPressContainerName();
  } catch (error) {
    console.error('❌ コンテナが起動していません。先に `npm run dc:build` を実行してください。');
    process.exit(1);
  }

  // ダンプファイルが存在するか確認
  const dumpFile = path.join(projectRoot, 'docker', 'dump', `${dumpName}.tar.gz`);
  if (!fs.existsSync(dumpFile)) {
    console.error(`❌ ダンプファイルが見つかりません: ${dumpFile}`);
    process.exit(1);
  }

  // コンテナ内でrestore.shを実行
  execSync(`docker exec -it ${containerName} /opt/docker/bin/restore.sh ${dumpName}`, {
    stdio: 'inherit',
    cwd: projectRoot
  });

  console.log('✅ 復元が完了しました');
} catch (error) {
  console.error('❌ エラーが発生しました:', error.message);
  process.exit(1);
}

