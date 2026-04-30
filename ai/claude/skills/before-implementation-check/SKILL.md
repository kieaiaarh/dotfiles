---
name: before-implementation-check
description: コード変更・新規ファイル作成・リファクタリング・実装の前に必ず発動して事前チェックを行う。「実装」「修正」「追加」「リファクタ」「直して」「変更」「create」「edit」「write」「fix」「refactor」「add」「実装して」「修正して」のようなキーワードで自動起動。実装計画提案前にも必須で発動。
---

# 実装前の必須チェック

実装に着手する前に、以下を**必ず**確認する。1つでも未達なら実装を始めてはいけない。

## ステップ 0: ブランチ確認（最重要）

```bash
git branch --show-current
```

- `master` または `main` の場合: 直ちに以下を実行
  ```bash
  git checkout -b feature/<topic>
  ```

## ステップ 1: ルールの読み込み（**階層全部**）

Claude Code は **working directory から root まで** すべての `CLAUDE.md` を walk up して自動読込する。ただし以下を必ず確認：

1. **直近の編集対象ディレクトリから順に上位の `CLAUDE.md` 全部** が context にあるか確認する。
   - サブディレクトリで作業する場合、そのサブディレクトリ独自の `CLAUDE.md` が遅延ロードされていない可能性がある → `find . -maxdepth 4 -name "CLAUDE.md"` で存在確認し、必要なら Read する。
2. **path-scoped rules**（`.claude/rules/*.md`）は編集対象パスに応じて auto-load される。確認するなら `ls .claude/rules/` で一覧。
3. **session 圧縮（compaction）後** は context から CLAUDE.md が消えている可能性が高い。直近の context に CLAUDE.md / rules の内容が見当たらなければ、明示的に Read し直す。

## ステップ 2: 設計方針の提示と承認取得

実装の前に**必ず**以下をテキストでユーザーに提示する:
- 何を変えるか（差分の概要）
- なぜ変えるか
- 影響範囲（同時に変わるファイル・コード）
- 採用するアプローチに選択肢があれば併記

ユーザーの承認を得てから実装を開始する。

## ステップ 3: TDD と atomic commits の検討

新規機能・バグ修正は **TDD** に従う:
1. 失敗するテストを書く → コミット
2. 失敗を確認する（必ず実行する）
3. 最小実装でグリーンにする → コミット
4. リファクタする → コミット

**1コミット1目的（atomic）**を守る。こまめなコミットで切り戻し単位を小さく保つ。

## チェックリスト

実装開始前に**全項目**を満たすこと:

- [ ] `git branch --show-current` を実行し、master/main でないことを確認した
- [ ] working directory ＋親ディレクトリ ＋（サブで作業する場合は）当該サブディレクトリの `CLAUDE.md` が context にあることを確認した
- [ ] 編集対象パスに該当する `.claude/rules/*.md` が context にある（または明示的に Read した）
- [ ] 設計方針をユーザーに提示し、承認を得た
- [ ] TDD と atomic commits の実施計画を立てた

**1つでも未達なら実装を始めてはいけない。**
