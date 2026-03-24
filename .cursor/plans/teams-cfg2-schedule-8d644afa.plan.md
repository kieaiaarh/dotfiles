---
name: "Phase 5, Task CFG2: 定期実行設定"
overview: ""
todos: []
---

# Phase 5, Task CFG2: 定期実行設定

## 目的

Microsoft Teams 監視システムの定期実行ジョブを `config/schedule.rb` に追加します。

## 実装内容

### 1. ファイル編集

**対象**: `config/schedule.rb`

ファイル末尾に以下の3つのジョブスケジュールを追加:

```ruby
# Teams スキャンジョブ（1 時間に 1 回）
every 1.hour do
  runner "Compliances::TeamsScanTeamsJob.perform_later"
  runner "Compliances::TeamsScanChannelsJob.perform_later"
end

# 購読更新ジョブ（1 時間に 1 回）
every 1.hour do
  runner "Compliances::TeamsSubscriptionRenewJob.perform_later"
end

# DeadLetter 再試行ジョブ（10 分に 1 回）
every 10.minutes do
  runner "Compliances::TeamsDeadletterRetryJob.perform_later"
end
```

### 2. 制約遵守

- 既存スケジュール（207行まで）に影響を与えない
- ファイル末尾に追加
- 既存の書式（インデント、改行）に合わせる

### 3. 確認コマンド

```bash
bundle exec whenever
```

実行して cron 設定が正しく生成されることを確認します。

## チェックリスト

- [ ] `config/schedule.rb` の末尾に3つのジョブブロックを追加
- [ ] 既存のスケジュール設定に変更がないことを確認
- [ ] `bundle exec whenever` で cron 設定が表示されることを確認

## 参照

- @TEAMS_PLAN_RAILS.md Phase 5, Task CFG2 (966-1002行)
- 既存ジョブ: Phase 2 で実装済み（J1, J2, J3, J6）