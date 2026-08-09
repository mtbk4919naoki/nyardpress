# GitHub 運用（nyardpress）

npm サプライチェーン（ChainDrop）対策と依存更新フローの運用メモ。デプロイ関連は `DEPLOYMENT.md` / `ENVIRONMENTS.md` を参照。

## Supply chain gate（`supply-chain-gate.yml`）

- Aikido Safe Chain（`--ci`）→ `npm ci`。既存 `chaindrop-scan.yml`（Wiz CSV 照合）と併用。
- job 名は **`gate`**。ブランチ保護（`main`）の required status check に `gate` を追加する（UI 作業）。

## Dependabot（`dependabot.yml`）

- npm（`/`）+ github-actions を weekly 更新。`cooldown.default-days: 7` は `.npmrc` の `min-release-age=7` と揃えている。
- ラベル `dependencies` / `github-actions` は **事前にリポジトリへ作成**しておく。
- WordPress テーマ/プラグインのサブプロジェクト（`www/htdocs/wp-content/...`）は現状 dependabot 対象外。必要なら `directory` を追加する。

## auto-merge（`dependabot-automerge.yml`）

- npm patch + direct、github-actions patch + minor のみ `--auto`（条件付き）。**無条件 auto-merge はしない**。
- 有効化に Settings → Actions → General → **Allow GitHub Actions to create and approve pull requests** を ON。マージは required check（`gate`）通過後。

## Cursor 自動レビュー

- `.github/cursor/dependabot-review.md` を Cursor Automation の Instructions 正本に使う（リポごとに 1 Automation）。

## 通知

- 対象リポを Watch（Custom → Pull requests）し、メール通知を有効化。
