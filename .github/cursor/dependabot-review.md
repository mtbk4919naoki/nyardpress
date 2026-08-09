# Dependabot PR レビュー（Cursor Automation Instructions）

Cursor Automation の Instructions 欄にこの内容を貼り付けて使う。対象リポジトリ: `nyardpress`。

## スコープ（最初に判定）

次の **いずれか** を満たす PR のみ処理。満たさなければ **コメントも Slack もせず終了**。

- ラベル `dependencies` がある
- head ブランチが `dependabot/` で始まる
- author が `dependabot[bot]`

## 目的

Dependabot PR をレビューし、**マージ可否を PR コメントで報告**。コード変更は原則しない。

## 前提

- ターゲットブランチ: `main`
- Required check: **`gate`**（supply-chain-gate workflow）
- auto-merge: npm は patch + direct のみ / github-actions は patch + minor
- npm ルートは `/`（WordPress テーマ/プラグインのサブプロジェクトは対象外。必要なら別途 directory 追加）

## 確認項目

1. 更新種別: patch / minor / major
2. エコシステム: npm / github-actions
3. lockfile が更新意図と一致するか（`package-lock.json`）
4. Supply chain: `.npmrc` の `min-release-age=7` / `pnpm-workspace.yaml` / `.aikido` 168h と矛盾しないか
5. CI: check `gate` が success か（pending なら「gate 待ち」とコメントして終了）
6. 破壊的変更: release notes / changelog

## エスカレーション

以下なら ⚠️/❌ コメント。**Send to Slack ツールがある場合のみ** 同内容を送る:

- semver minor / major
- ビルド・実行直結（`npm-run-all2` などデプロイ/ビルドスクリプトが依存するもの）
- lockfile 異常 / gate fail / breaking 記載 / auto-merge 対象外 / 自信がない

✅ patch + direct + gate pass + 影響小 → マージ可。PR コメントのみ。
❌ **マージは実行しない**（auto-merge workflow に委ねる）。

## 出力形式

```
## Dependabot review (Cursor)
**Verdict:** ✅ マージ可 / ⚠️ 要確認 / ❌ マージ非推奨

| 項目 | 値 |
|------|-----|
| 更新種別 | {patch/minor/major} |
| 依存 | {name} |
| auto-merge 対象 | はい / いいえ |

### 根拠
- （1〜3 行）

### CI
- gate: {pass/fail/pending}
```
