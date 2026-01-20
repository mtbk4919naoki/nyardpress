/**
 * blocks/ディレクトリ内のすべてのブロックを開発モードで起動
 * 各ブロックは別々のプロセスとして起動されます
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const blocksDir = path.join(__dirname, '../blocks');
const directories = fs.readdirSync(blocksDir, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

// src/index.jsが存在するブロックをフィルタリング
const blocks = directories.filter(blockName => {
    const blockDir = path.join(blocksDir, blockName);
    const srcIndex = path.join(blockDir, 'src/index.js');
    return fs.existsSync(srcIndex);
});

if (blocks.length === 0) {
    console.log('No blocks found with src/index.js');
    process.exit(0);
}

console.log(`Starting development mode for ${blocks.length} block(s):\n`);

const processes = [];

// 各ブロックを別々のプロセスとして起動
blocks.forEach((blockName, index) => {
    const blockDir = path.join(blocksDir, blockName);
    const srcIndex = path.join(blockDir, 'src/index.js');
    const buildDir = path.join(blockDir, 'build');

    // 相対パスに変換（site-coreディレクトリからの相対パス）
    const baseDir = path.join(__dirname, '..');
    const relativeSrcIndex = path.relative(baseDir, srcIndex);
    const relativeBuildDir = path.relative(baseDir, buildDir);

    // 各ブロックに異なるポートを割り当て（3000 + index）
    const port = 3000 + index;

    console.log(`  [${index + 1}/${blocks.length}] Starting: ${blockName} (port: ${port})`);

    const child = spawn(
        'npm',
        [
            'run',
            'start:block',
            '--',
            relativeSrcIndex,
            '--output-path=' + relativeBuildDir,
            '--webpack-copy-php',
            '--webpack-dev-server-port=' + port
        ],
        {
            cwd: baseDir,
            stdio: 'inherit',
            shell: true
        }
    );

    processes.push({
        name: blockName,
        process: child
    });

    // プロセスが終了したときの処理
    child.on('exit', (code) => {
        if (code !== 0 && code !== null) {
            console.error(`\n❌ Block "${blockName}" exited with code ${code}`);
        }
    });
});

// Ctrl+Cで全プロセスを終了
process.on('SIGINT', () => {
    console.log('\n\nStopping all blocks...');
    processes.forEach(({ name, process: child }) => {
        console.log(`  Stopping: ${name}`);
        child.kill('SIGINT');
    });
    setTimeout(() => {
        process.exit(0);
    }, 1000);
});

console.log('\n✅ All blocks started. Press Ctrl+C to stop all.\n');
