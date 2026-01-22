# デプロイ環境の設定ガイド

このドキュメントでは、GitHub Environmentsを使用した環境別デプロイの設定方法を説明します。

## 環境の概要

| 環境 | 用途 | ワークフロー | 保護設定 |
|------|------|------------|---------|
| **Staging** | 開発・テスト | `Deploy Theme to XServer (Staging)` | なし（自由にデプロイ可能） |
| **Production** | 本番サイト | `Deploy Theme to XServer` | 承認フロー推奨 |

## クイック設定ガイド

### ステップ1: Staging環境の作成

1. **GitHub リポジトリの Settings を開く**
   ```
   https://github.com/[username]/[repository]/settings/environments
   ```

2. **New environment をクリック**

3. **環境名を入力**
   ```
   staging
   ```

4. **Configure environment をクリック**

5. **Secretsを追加**（Add secret ボタンから）
   
   | Secret名 | 値の例 |
   |---------|-------|
   | SSH_HOST | `sv12345.xserver.jp` |
   | SSH_PORT | `10022` |
   | SSH_USERNAME | `your-server-id` |
   | SSH_PRIVATE_KEY | `-----BEGIN RSA PRIVATE KEY-----...` |

6. **Variablesを追加**（Add variable ボタンから）
   
   | Variable名 | 値の例 |
   |---------|-------|
   | THEME_PATH | `/home/your-id/staging.example.com/public_html/wp-content/themes/theme-name/` |
   | ASSET_PATH | `/home/your-id/staging.example.com/public_html/assets/` (オプション) |

7. **保護ルールは設定しない**（開発者が自由にデプロイ可能にする）

### ステップ2: Production環境の作成

1. **New environment をクリック**

2. **環境名を入力**
   ```
   production
   ```

3. **Configure environment をクリック**

4. **保護ルールを設定（推奨）**
   
   ✅ **Required reviewers**
   - 承認者を1名以上選択
   - デプロイ前に承認が必要になります
   
   ⏱️ **Wait timer**（オプション）
   - 例：5分待機後にデプロイ
   
   🌿 **Deployment branches**（オプション）
   - `main` または `master` ブランチのみ許可

5. **Secretsを追加**（Add secret ボタンから）
   
   | Secret名 | 値の例 |
   |---------|-------|
   | SSH_HOST | `sv12345.xserver.jp` |
   | SSH_PORT | `10022` |
   | SSH_USERNAME | `your-server-id` |
   | SSH_PRIVATE_KEY | `-----BEGIN RSA PRIVATE KEY-----...` |

6. **Variablesを追加**（Add variable ボタンから）
   
   | Variable名 | 値の例 |
   |---------|-------|
   | THEME_PATH | `/home/your-id/example.com/public_html/wp-content/themes/theme-name` |
   | ASSET_PATH | `/home/your-id/example.com/public_html/assets` (オプション) |

## デプロイフロー

### 開発フロー

```
1. ローカルで開発
   ↓
2. GitHubにプッシュ
   ↓
3. Staging環境にデプロイ
   ↓ GitHub Actions > Deploy Theme to XServer (Staging) > Run workflow
   ↓
4. Staging環境で動作確認
   ↓ ブラウザで staging.example.com を確認
   ↓
5. 問題なければProduction環境にデプロイ
   ↓ GitHub Actions > Deploy Theme to XServer > Run workflow
   ↓
6. 承認者が承認（Required reviewersを設定している場合）
   ↓
7. 本番環境にデプロイ完了
```

## 環境の確認方法

### GitHub Environmentsの設定を確認

```
Settings > Environments
```

各環境をクリックすると：
- 設定した Secrets の一覧（値は見えない）
- 保護ルールの設定
- デプロイ履歴

が確認できます。

### デプロイ履歴の確認

```
Actions タブ > ワークフローを選択
```

各実行をクリックすると：
- どの環境にデプロイされたか
- いつ、誰がデプロイしたか
- 承認者は誰か（productionの場合）
- デプロイの結果（成功/失敗）

が確認できます。

## トラブルシューティング

### 「Environment protection rules」のエラー

**原因**: Production環境で承認者が設定されているが、承認されていない

**対処法**: 
1. GitHub Actionsのページで「Review deployments」ボタンをクリック
2. 承認者がレビューして「Approve and deploy」をクリック

### Secretsが見つからないエラー

**原因**: 環境にSecretsが設定されていない、または環境名が間違っている

**対処法**:
1. `Settings` > `Environments` > 該当環境を開く
2. 必要な5つのSecretsがすべて登録されているか確認
3. ワークフローファイルの `environment:` の値が正しいか確認

### デプロイ先パスが見つからないエラー

**原因**: DEPLOY_PATHが間違っている、またはディレクトリが存在しない

**対処法**:
1. XServerにSSH接続
   ```bash
   ssh -p 10022 -i ~/.ssh/xserver_deploy user@sv12345.xserver.jp
   ```
2. ディレクトリが存在するか確認
   ```bash
   ls -la /home/your-id/example.com/public_html/wp-content/themes/
   ```
3. 必要に応じてディレクトリを作成
   ```bash
   mkdir -p /home/your-id/example.com/public_html/wp-content/themes/theme-name
   ```

## セキュリティのベストプラクティス

### ✅ 推奨設定

- **Production環境には必ず承認フローを設定**
  - 誤デプロイを防止
  - 複数人でレビュー可能

- **SSH鍵は環境ごとに分ける（オプション）**
  - Staging用とProduction用で別の鍵を使用
  - 万が一鍵が漏洩しても被害を最小化

- **定期的なSSH鍵のローテーション**
  - 3〜6ヶ月ごとに鍵を再生成
  - 退職者がいた場合はすぐに更新

### ❌ 避けるべき設定

- Repository Secretsの使用
  - Environment Secretsを使用してください
  - 環境ごとに異なる値を設定できます

- 承認フローなしのProduction環境
  - 誤操作のリスクが高まります
  - 最低1名は承認者を設定してください

## 関連ドキュメント

- [DEPLOYMENT.md](DEPLOYMENT.md) - 詳細なデプロイ設定
- [README.md](../README.md) - プロジェクト全体の説明
