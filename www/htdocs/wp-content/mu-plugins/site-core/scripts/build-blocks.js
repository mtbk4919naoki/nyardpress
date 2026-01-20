/**
 * blocks/ディレクトリ内のすべてのブロックをビルド
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const blocksDir = path.join(__dirname, '../blocks');
const directories = fs.readdirSync(blocksDir, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

let builtCount = 0;

directories.forEach(blockName => {
    const blockDir = path.join(blocksDir, blockName);
    const srcIndex = path.join(blockDir, 'src/index.js');
    const buildDir = path.join(blockDir, 'build');

    // src/index.jsが存在する場合のみビルド
    if (fs.existsSync(srcIndex)) {
        // 相対パスに変換（site-coreディレクトリからの相対パス）
        const baseDir = path.join(__dirname, '..');
        const relativeSrcIndex = path.relative(baseDir, srcIndex);
        const relativeBuildDir = path.relative(baseDir, buildDir);

        console.log(`Building block: ${blockName}`);
        try {
            execSync(
                `npm run build:block -- ${relativeSrcIndex} --output-path=${relativeBuildDir} --webpack-copy-php`,
                { stdio: 'inherit', cwd: baseDir }
            );
            console.log(`✅ Built: ${blockName}\n`);
            builtCount++;
        } catch (error) {
            console.error(`❌ Failed to build: ${blockName}\n`);
        }
    }
});

if (builtCount > 0) {
    console.log(`✅ All blocks built! (${builtCount} blocks)`);
} else {
    console.log('No blocks found with src/index.js');
}
