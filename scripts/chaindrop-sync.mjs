#!/usr/bin/env node
/**
 * chaindrop-scan.mjs の doc 埋め込みと CI 用コピーを同期
 */
import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const source = join(root, 'scripts/chaindrop-scan.mjs');
const ciTarget = join(root, '.github/scripts/chaindrop-scan.mjs');
const docPath = join(root, 'docs/chaindrop-supply-chain-attack.md');

const content = await readFile(source, 'utf8');
await mkdir(dirname(ciTarget), { recursive: true });
await copyFile(source, ciTarget);

const doc = await readFile(docPath, 'utf8');
const start = '<!-- chaindrop-scan-embed:start -->';
const end = '<!-- chaindrop-scan-embed:end -->';
const startIdx = doc.indexOf(start);
const endIdx = doc.indexOf(end);
if (startIdx === -1 || endIdx === -1) {
  throw new Error('chaindrop-sync: embed markers not found in docs');
}

const before = doc.slice(0, startIdx + start.length);
const after = doc.slice(endIdx);
const embed = `

<details>
<summary><code>chaindrop-scan.mjs</code> 全文（クリックで展開）</summary>

\`\`\`javascript
${content}\`\`\`

</details>
`;

await writeFile(docPath, before + embed + after, 'utf8');
console.log('chaindrop-sync: updated docs embed and .github/scripts/chaindrop-scan.mjs');
