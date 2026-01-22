# デプロイメント設定

## GitHub Actions によるデプロイ

このリポジトリでは、GitHub Actionsを使用してWordPressテーマをXServerへデプロイします。

> 💡 **環境設定の詳細ガイド**: [ENVIRONMENTS.md](ENVIRONMENTS.md) も参照してください

### デプロイ対象

- ローカル: `www/htdocs/wp-content/themes/theme-name/`
- リモート: XServer上の指定されたパス

### デプロイトリガー

- **手動実行のみ**（GitHub Actions の "Run workflow" ボタンから）
- 本番環境（production）への誤デプロイを防ぐため、自動デプロイは無効化されています

## 必要な GitHub Environment Secrets の設定

このプロジェクトでは `production`（本番環境）と `staging`（ステージング環境）の2つの環境を使用します。

### 設定手順

#### 1. 環境の作成

1. GitHubリポジトリページで `Settings` > `Environments` に移動
2. `New environment` をクリック
3. 環境名に `production` または `staging` と入力して `Configure environment` をクリック
4. （オプション）以下の保護ルールを設定できます：
   - **Required reviewers**: デプロイ前に承認者を必要とする（productionに推奨）
   - **Wait timer**: デプロイ前に待機時間を設定
   - **Deployment branches**: デプロイ可能なブランチを制限

**推奨設定:**
- `production`: Required reviewersを有効化し、承認フローを設定
- `staging`: 制限なし（開発者が自由にデプロイ可能）

#### 2. Environment Secretsの追加

1. 作成した環境（`production` または `staging`）の設定画面で `Add secret` をクリック
2. 以下のSecretsを1つずつ追加

### 必要なSecrets一覧

各環境（`production`、`staging`）にそれぞれ以下のSecretsを設定します。

| Secret名 | 説明 | 例 |
|---------|------|-----|
| `SSH_HOST` | XServerのホスト名またはIPアドレス | `example.xsrv.jp` または `123.45.67.89` |
| `SSH_PORT` | SSHポート番号（通常は10022） | `10022` |
| `SSH_USERNAME` | SSH接続用のユーザー名 | `your-server-id` |
| `SSH_PRIVATE_KEY` | SSH秘密鍵（全文） | `-----BEGIN RSA PRIVATE KEY-----...` |

### 必要なEnvironment Variables一覧

各環境（`production`、`staging`）にそれぞれ以下のVariablesを設定します。

| Variable名 | 説明 | 例 |
|---------|------|-----|
| `THEME_PATH` | テーマのデプロイ先パス | `/home/your-id/example.com/public_html/wp-content/themes/theme-name` |
| `ASSET_PATH` | 静的アセットのデプロイ先パス（オプション） | `/home/your-id/example.com/public_html/assets` |

### 環境別の設定例

#### Production（本番環境）

**Secrets:**
```
SSH_HOST: sv12345.xserver.jp
SSH_PORT: 10022
SSH_USERNAME: your-server-id
SSH_PRIVATE_KEY: [秘密鍵の内容]
```

**Variables:**
```
THEME_PATH: /home/your-id/example.com/public_html/wp-content/themes/theme-name
ASSET_PATH: /home/your-id/example.com/public_html/assets  # オプション
```

#### Staging（ステージング環境）

**Secrets:**
```
SSH_HOST: sv12345.xserver.jp（本番と同じサーバーでもOK）
SSH_PORT: 10022
SSH_USERNAME: your-server-id
SSH_PRIVATE_KEY: [秘密鍵の内容]
```

**Variables:**
```
THEME_PATH: /home/your-id/staging.example.com/public_html/wp-content/themes/theme-name
ASSET_PATH: /home/your-id/staging.example.com/public_html/assets  # オプション
```

**注意**: ステージング環境は、サブドメイン（`staging.example.com`）やテスト用ドメインを使用することを推奨します。

### SSH鍵の作成方法

XServerにSSH接続するための鍵ペアを作成します。

```bash
# 鍵ペアを生成（パスフレーズなし）
ssh-keygen -t rsa -b 4096 -C "github-actions@deploy" -f ~/.ssh/xserver_deploy -N ""

# 公開鍵をXServerに登録
# XServerのサーバーパネル > SSH設定 > 公開鍵登録
cat ~/.ssh/xserver_deploy.pub

# 秘密鍵の内容をGitHub Secretsに登録
cat ~/.ssh/xserver_deploy
```

### XServer側の設定

1. **サーバーパネル** > **SSH設定** に移動
2. **SSH設定** を「**ON[すべてのアクセスを許可]**」に変更
   - ⚠️ **重要**: 「ON[国内からのアクセスのみ許可]」では、GitHub Actions（海外サーバー）からの接続が拒否されます
   - 参考: [XserverにGitHub Actions経由でSSH接続を行った時のエラー](https://qiita.com/T5r9xysvdTHRt8b/items/e43cc2e4914121243ada)
3. **公開鍵登録・更新** で、生成した公開鍵（`.pub`ファイルの内容）を登録
4. 接続確認:
   ```bash
   ssh -p 10022 -i ~/.ssh/xserver_deploy your-username@your-server.xsrv.jp
   ```

### デプロイパスの確認方法

XServerにSSH接続して、実際のパスを確認します:

```bash
ssh -p 10022 your-username@your-server.xsrv.jp
cd ~/your-domain.com/public_html/wp-content/themes
pwd
# 出力されたパスに `/theme-name` を付けて DEPLOY_PATH に設定
```

## トラブルシューティング

### デプロイが失敗する場合

1. **GitHub Actions のログを確認**
   - リポジトリの `Actions` タブから実行ログを確認

2. **SSH接続の確認**
   - ローカルから手動でSSH接続できるか確認
   - ポート番号が正しいか確認（XServerは通常10022）

3. **パスの確認**
   - `DEPLOY_PATH` が正しいか確認
   - デプロイ先のディレクトリが存在するか確認

4. **権限の確認**
   - デプロイ先ディレクトリの書き込み権限を確認

## デプロイの実行方法

### Staging（ステージング環境）へのデプロイ

1. GitHubリポジトリページで `Actions` タブを開く
2. `Deploy Theme to XServer (Staging)` ワークフローを選択
3. `Run workflow` ボタンをクリック
4. ブランチを選択して実行

### Production（本番環境）へのデプロイ

1. GitHubリポジトリページで `Actions` タブを開く
2. `Deploy Theme to XServer` ワークフローを選択
3. `Run workflow` ボタンをクリック
4. （承認フローを設定している場合）承認者がデプロイを承認
5. ブランチを選択して実行

### 推奨ワークフロー

1. **開発** → `staging` 環境にデプロイして動作確認
2. **確認OK** → `production` 環境にデプロイ

## セキュリティ注意事項

- SSH秘密鍵は絶対にリポジトリにコミットしない
- Secretsの値は一度設定すると見えなくなるため、別途安全な場所に保管すること
- 定期的にSSH鍵をローテーションすることを推奨
