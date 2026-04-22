# dotfiles

Vim・tmux・Claude Code の設定を管理するリポジトリです。  
新しいマシンでは `install.sh` を実行するだけで、シンボリックリンクの作成・NeoBundle のインストール・Claude 制御ファイルの配布が完了します。

---

## 新しいマシンでのセットアップ

### セットアップ完了後の状態

| 項目 | 適用方法 | 備考 |
|---|---|---|
| グローバル CLAUDE.md / settings.json / コマンド | install.sh で symlink（**自動**） | Claude Code 起動時に即適用 |
| プラグイン（superpowers 等） | settings.json の `enabledPlugins`（**自動**） | Claude 初回起動時に自動インストール |
| 各プロジェクトの CLAUDE.md / rules / settings / hooks | install.sh 内の sync（**自動**） | repos.local に記載されたリポが対象 |
| .git/info/exclude（AI ファイルの除外） | install.sh（**自動**） | |
| Claude ログイン | `claude login`（**手動**） | PC ごとに認証が必要 |
| MCP サーバー設定 | `~/.claude.json` に手動追記（**手動**） | 秘密情報を含むため自動化不可 |
| Vim / tmux | install.sh で symlink + clone（**自動**） | プラグインインストールのみ手動 |

### Step 1: このリポジトリをクローン

```bash
mkdir -p ~/work/buzzkuri
git clone <this-repo> ~/work/buzzkuri/dotfiles
cd ~/work/buzzkuri/dotfiles
```

---

### Step 2: repos.local を作成する

このマシンで使うリポジトリのパス一覧を記載します。  
`install.sh` はここに書かれたリポジトリに Claude 制御ファイルを同期します。

```bash
cp repos.template repos.local
# エディタで repos.local を開き、自分のマシンの clone 先パスに合わせて編集する
```

`repos.template` は標準的なパス（`~/work/buzzkuri/backend` 等）で記載していますが、PC によって clone 先が異なる場合があります。`repos.local` のパスを自分の環境に合わせて書き換えてください。

```
# 例: clone 先が ~/projects 配下の場合
~/projects/buzzkuri/backend rails
~/projects/compliance-police/frontend cp-nextjs
```

> `repos.local` は `.gitignore` 対象のためコミットされません。  
> 未 clone のリポジトリは自動でスキップされ、clone を促すメッセージが表示されます。

次に、テンプレートの `.env.template` をコピーして `.env.local` を作成します。  
compliance-police 系は `.env.template` の内容がそのまま使えるため、コピーするだけで OK です。

```bash
# 例: compliance-police 系
cp buzzkuri/_templates/cp-rails/.env.template buzzkuri/_templates/cp-rails/.env.local
cp buzzkuri/_templates/cp-nextjs/.env.template buzzkuri/_templates/cp-nextjs/.env.local
cp buzzkuri/_templates/cp-infra-cdk/.env.template buzzkuri/_templates/cp-infra-cdk/.env.local

# buzzkuri 系はプロジェクト固有値の編集が必要
cp buzzkuri/_templates/rails/.env.template buzzkuri/_templates/rails/.env.local
# .env.local を編集してプロジェクトの実際の値を入力
```

---

### Step 3: install.sh を実行する

```bash
bash install.sh
```

以下が自動で行われます：

| 処理 | 内容 |
|---|---|
| symlink | `~/.claude/CLAUDE.md` → `ai/claude/CLAUDE.md` 他 |
| symlink | `~/.vimrc` → `.vimrc` |
| symlink | `~/.tmux.conf` → `.tmux.conf` |
| copy | `~/.vim/autoload/pathogen.vim` |
| clone | NeoBundle → `~/.vim/bundle/neobundle.vim` |
| 設定 | 各リポジトリの `.git/info/exclude` に AI ファイルを追加 |
| sync | clone 済みリポジトリに `.claude/rules/` 等を同期 |

> **注意**: `vimfiles/ → ~/.vim/` のシンボリックリンクは貼らないこと。  
> `bundle/` が dotfiles リポに混入する原因になります。`install.sh` が正しく処理します。

---

### Step 4: Vim プラグインをインストール

```bash
vim
```

vim 起動後、以下のコマンドを実行：

```
:NeoBundleInstall
```

インストールが完了したら vim を終了し、tmux を再起動（または `tmux source ~/.tmux.conf`）して動作確認します。

---

### Step 5: Claude にログイン

```bash
claude login
```

`~/.claude.json` が自動生成されます。

---

### Step 6: MCP・個人設定を追記

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

Sentry のアクセストークンは [Sentry の設定画面](https://sentry.io/settings/) から取得してください。

---

### Step 7: Claude プラグインの確認

`ai/claude/settings.json` の `enabledPlugins` に記載のプラグインは、Claude 初回起動時に自動インストールされます。  
起動後にプラグインが有効になっていることを確認してください。

---

## Windows での Vim セットアップ

### 1. シンボリックリンクを貼る（PowerShell / 管理者権限）

```powershell
New-Item -ItemType SymbolicLink -Path "$HOME\_vimrc" -Target "$HOME\work\buzzkuri\dotfiles\_vimrc"
```

### 2. vim-plug をインストール

```powershell
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
  ni "$HOME/vimfiles/autoload/plug.vim" -Force
```

### 3. プラグインをインストール

```
vim
:PlugInstall
```

---

## 新規プロジェクト立ち上げ時 / 既存プロジェクトへの Claude ルール反映

`scripts/sync-rules-to-project.sh` を使います。

### 1. env ファイルを作成する

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

### 2. sync スクリプトを実行する

dotfiles のルートから実行：

```bash
bash scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend buzzkuri/_templates/rails/.env.local
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
- `CLAUDE.md` が既存の場合は diff を表示して手動マージを案内

### 3. プロジェクトリポで確認・コミット

```bash
cd /path/to/project
git diff
git add .claude/rules/ .claude/settings.json .claude/hooks/ CLAUDE.md
git commit -m "📝: Claude 制御ファイルを追加"
```

利用可能なテンプレート：

| テンプレート | 用途 |
|---|---|
| `buzzkuri/_templates/rails/` | Ruby on Rails API（buzzkuri） |
| `buzzkuri/_templates/nextjs/` | Next.js フロントエンド（buzzkuri） |
| `buzzkuri/_templates/infra-cdk/` | AWS CDK インフラ（buzzkuri） |
| `buzzkuri/_templates/wordpress/` | WordPress / Docker |
| `buzzkuri/_templates/cp-rails/` | Ruby on Rails API（compliance-police） |
| `buzzkuri/_templates/cp-nextjs/` | Next.js フロントエンド（compliance-police） |
| `buzzkuri/_templates/cp-infra-cdk/` | AWS CDK インフラ（compliance-police） |

---

## テンプレート更新時の標準フロー

```
dotfiles のテンプレートを編集
    ↓
git commit & push → PR → マージ
    ↓
bash scripts/sync-rules-to-project.sh <種別> <プロジェクトパス> <envファイル>
    ↓
プロジェクトリポで git diff 確認 → commit & push → PR
```

---

## 補足：Perl 開発時の追加設定

Perl で開発する場合は、`.vimrc` に以下を追記してください：

```
set encoding=euc-jp
set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
```
