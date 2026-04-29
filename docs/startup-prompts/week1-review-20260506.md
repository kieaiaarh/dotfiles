# Week 1 振り返り起動プロンプト（2026-05-06 用）

## 使い方

1. ターミナルで dotfiles ディレクトリに移動：
   ```bash
   cd ~/work/buzzkuri/dotfiles
   claude
   ```
2. Claude Code 起動後、下の「起動プロンプト」を **そのままコピペ**してエンターを送る
3. AI が振り返り routine の出力を起点に作業を進める

---

## 起動プロンプト

```
1 週間運用フェーズの振り返りを行います。

5/6 09:00 JST に発火した振り返り routine が
kieaiaarh/dotfiles の Issue #33 にコメント 3 つ
（PR-4 Codemap 雛形 / Week 1 ローカル集計依頼 / 次の優先 PR）
を投稿しているはずです。

以下の順で進めてください：

1. Issue #33 の最新 3 コメントを確認
   gh issue view 33 --repo kieaiaarh/dotfiles --comments | tail -200

2. 「Week 1 ローカル集計依頼」コメントの jq コマンドを順に実行し、
   各メトリクス（plugin/skill 利用回数、hook 違反検知数、active tools 数、
   CLAUDE.md 蓄積差分）を集計した結果を Issue #33 にコメント投稿

3. その結果と「Week 1 振り返り: 次の優先 PR」推奨を突き合わせて、
   今週着手する PR を 1〜2 個に絞り、設計提案を出す
   （ECC 採用是非の判断は不要、Phase 1 で確定済み）

4. 設計承認を取ってから実装に着手

参考：
- 親 Issue: kieaiaarh/dotfiles#33（Phase 1 完了、umbrella）
- 後続 Issue: kieaiaarh/dotfiles#44（Phase 2: 全 repo への .github 反映）
- 当初プラン: ~/.claude/plans/claude-code-cli開発の最適化（dotfiles局所改善）.md
- 振り返り routine ID: trig_0117dKA28KjyBc5GTVYFVZ3N

なお、時刻表記はすべて JST（東京拠点なので UTC 併記不要）。
```

---

## 補足

### routine が動かなかった場合のフォールバック

```bash
gh api repos/kieaiaarh/dotfiles/issues/33/comments --jq '.[] | "\(.created_at) | \(.body | split("\n")[0])"'
```

直近のコメントが routine 由来でなければ、AI に「振り返り routine が未投稿。手動で Step 2 の集計依頼を作成して」と指示する。

### スニペットの寿命

本ファイルは 2026-05-06 振り返り専用。次の振り返り（5/13 等）では同階層に
`weekN-review-YYYYMMDD.md` を新規追加していく運用。

### 関連

- 起動プロンプト全般のテンプレ化: 本 PR で `docs/startup-prompts/` を新設
- routine 自体の管理: https://claude.ai/code/routines/trig_0117dKA28KjyBc5GTVYFVZ3N
