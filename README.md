# dotfiles
my dotfiles

---

## Vim セットアップ（新しいマシン）

### macOS / Linux

`install.sh` が以下を自動で行います：

- `.vimrc` → `~/.vimrc` のシンボリックリンク作成
- `pathogen.vim` を `~/.vim/autoload/` にコピー
- NeoBundle を `~/.vim/bundle/neobundle.vim` に clone

```bash
bash ~/work/buzzkuri/dotfiles/install.sh
```

その後、プラグインをインストール：

```
vim
:NeoBundleInstall
```

完了後 vim を再起動して動作確認する。

> **注意**: `vimfiles/ → ~/.vim/` のシンボリックリンクは貼らないこと。
> `bundle/` がdotfilesリポに混入する原因になります。install.sh が正しく処理します。

### Windows

#### 1. シンボリックリンクを貼る（PowerShell / 管理者権限）

```powershell
New-Item -ItemType SymbolicLink -Path "$HOME\_vimrc" -Target "$HOME\work\buzzkuri\dotfiles\_vimrc"
```

#### 2. vim-plug をインストール

```powershell
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
  ni "$HOME/vimfiles/autoload/plug.vim" -Force
```

#### 3. プラグインをインストール

```
vim
:PlugInstall
```

---

## Perl 開発時の追加設定

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

### 新規プロジェクト立ち上げ時 / 既存プロジェクトへの反映

`scripts/sync-rules-to-project.sh` を使います。

#### 手順

**1. envファイルを作成する**

```bash
cp buzzkuri/_templates/rails/.env.template buzzkuri/_templates/rails/.env.local
# .env.local を編集してプロジェクトの実際の値を入力
```

`.env.local` の内容例：

```
PROJECT_NAME=buzzkuri/backend
RUBY_VERSION=3.3.6
RAILS_VERSION=6.1.7.2
DB_ENGINE=MySQL 8.4
DB_SCHEMA_TOOL=Ridgepole
JOB_FRAMEWORK=Sidekiq 5.x
API_DOC_TOOL=rswag
UPLOAD_TOOL=CarrierWave + S3
MAILER_TOOL=SendGrid
PROJECT_NAMESPACE=compliance/api
```

> `.env.local` は `.gitignore` 対象なのでコミットされません。

**2. syncスクリプトを実行する**

dotfilesのルートから実行する場合：

```bash
# どちらでも動く
bash scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend buzzkuri/_templates/rails/.env.local
./scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend buzzkuri/_templates/rails/.env.local
```

別ディレクトリから実行する場合はフルパスで：

```bash
~/work/buzzkuri/dotfiles/scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend ~/work/buzzkuri/dotfiles/buzzkuri/_templates/rails/.env.local
```

スクリプトが行うこと：
- `.claude/rules/*.md` を自動生成（プレースホルダーを置換済み）
- `.claude/settings.json` を生成（`claude-settings.json.template` から）
- `.claude/hooks/*.sh` を生成（実行権限付き）
- `CLAUDE.md` が存在しない場合はテンプレートからコピー＆置換
- `CLAUDE.md` が既存の場合はdiffを表示して手動マージを案内

**3. プロジェクトリポで確認・コミット**

```bash
cd /path/to/project
git diff
git add .claude/rules/ .claude/settings.json .claude/hooks/ CLAUDE.md
git commit -m "📝: Claude 制御ファイルを追加"
```

| テンプレート | 用途 |
|---|---|
| `buzzkuri/_templates/rails/` | Ruby on Rails API |
| `buzzkuri/_templates/nextjs/` | Next.js フロントエンド |
| `buzzkuri/_templates/infra-cdk/` | AWS CDK インフラ |
| `buzzkuri/_templates/wordpress/` | WordPress / Docker |

---

### テンプレート更新時の標準フロー

```
dotfilesのテンプレートを編集
    ↓
git commit & push → PR → マージ
    ↓
bash scripts/sync-rules-to-project.sh <種別> <プロジェクトパス> <envファイル>
    ↓
プロジェクトリポで git diff 確認 → commit & push → PR
```
