# dotfiles
my dotfiles

if you use Perl for developing, add charset as follow

```
set encoding=euc-jp
set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
```

---

## AI制御ファイル（Claude Code）

### 新しいマシンでのセットアップ手順

#### 1. このリポジトリをクローン

```bash
git clone <this-repo> ~/work/buzzkuri/dotfiles
```

#### 2. シンボリックリンクを貼る

```bash
cd ~/work/buzzkuri/dotfiles
bash install.sh
```

以下のsymlinkが作成されます：

| symlink | 実体 |
|---|---|
| `~/.claude/CLAUDE.md` | `ai/claude/CLAUDE.md` |
| `~/.claude/settings.json` | `ai/claude/settings.json` |
| `~/.claude/mystatus.sh` | `ai/claude/mystatus.sh` |
| `~/.claude/commands/think.md` | `ai/claude/commands/think.md` |

#### 3. Claude にログイン

```bash
claude login
```

`~/.claude.json` が自動生成されます。

#### 4. MCP・個人設定を追記

`ai/claude/claude.json.template` を参考に、`~/.claude.json` へ以下を手動で追記します：

```json
{
  "autoUpdates": false,
  "deepLinkTerminal": "iTerm",
  "mcpServers": {
    "memory": { ... },
    "sequential-thinking": { ... },
    "aws-docs": { ... },
    "aws-cdk": { ... },
    "sentry": {
      "args": ["--access-token=<実際のトークン>", "--organization-slug=<org>"]
    },
    "context7": { ... }
  }
}
```

Sentryのアクセストークンは [Sentry の設定画面](https://sentry.io/settings/) から取得してください。

#### 5. Claudeプラグインの再インストール

`ai/claude/settings.json` の `enabledPlugins` に記載のプラグインは、初回起動時に自動インストールされます。

---

### 新規プロジェクト立ち上げ時

`buzzkuri/_templates/` 配下にプロジェクト種別ごとのテンプレートがあります。

```bash
# 例: Railsプロジェクト
cp buzzkuri/_templates/rails/CLAUDE.md.template /path/to/new-project/CLAUDE.md
cp buzzkuri/_templates/rails/claude-settings.json.template /path/to/new-project/.claude/settings.json

# rulesファイルも一括コピー
mkdir -p /path/to/new-project/.claude/rules
for f in buzzkuri/_templates/rails/rules/*.md.template; do
  cp "$f" "/path/to/new-project/.claude/rules/$(basename "$f" .template)"
done
```

`{{RUBY_VERSION}}` 等のプレースホルダーをプロジェクトに合わせて置き換えてください。

| テンプレート | 用途 |
|---|---|
| `buzzkuri/_templates/rails/` | Ruby on Rails API |
| `buzzkuri/_templates/nextjs/` | Next.js フロントエンド |
| `buzzkuri/_templates/infra-cdk/` | AWS CDK インフラ |
| `buzzkuri/_templates/wordpress/` | WordPress / Docker |

---

### 既存プロジェクトへのテンプレート変更反映手順

dotfilesのテンプレートを更新した後、既存プロジェクトへ反映するには `scripts/sync-rules-to-project.sh` を使います。

#### 使い方

```bash
bash scripts/sync-rules-to-project.sh <テンプレート種別> <プロジェクトパス>

# 例
bash scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend
bash scripts/sync-rules-to-project.sh infra-cdk ~/work/buzzkuri/infra
```

#### スクリプトの動作

1. `.claude/rules/*.md` をテンプレートと比較し、差分があれば表示
2. 新規ファイルは自動追加、既存ファイルは差分確認後に上書きするか選択
3. `CLAUDE.md` はプレースホルダーが含まれるため自動更新しない。diffを表示するので手動でマージ

#### テンプレート更新時の標準フロー

```
dotfilesのテンプレートを編集
    ↓
git commit & push → PR → マージ
    ↓
bash scripts/sync-rules-to-project.sh <種別> <プロジェクトパス>
    ↓
プロジェクトリポで git diff 確認 → commit & push → PR
```
