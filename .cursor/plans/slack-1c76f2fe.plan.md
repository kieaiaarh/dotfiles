---
name: Slack通知にユーザー名とチャンネル名を表示する実装計画
overview: ""
todos:
  - id: 48dceaad-10ef-4039-bc92-2f4d42a2b41d
    content: "Slack APIクライアントの共通化（オプション）: app/services/compliances/slacks/slack_api_client.rb を作成"
    status: pending
  - id: c878977d-58b5-4883-aa94-11e63e93a7ef
    content: "DetectionServiceにユーザー名取得機能を追加: fetch_and_update_user_name メソッドを実装"
    status: pending
  - id: 6bbfc417-b31b-4839-a776-c55cb48e21d6
    content: "DetectionServiceにチャンネル名取得機能を追加: fetch_channel_name メソッドを実装"
    status: pending
  - id: 3b991ad0-d871-4c87-ab95-b6b2d4bf84be
    content: "DetectionServiceのcreate_or_update_suspectを修正: ユーザー名・チャンネル名取得を統合"
    status: pending
  - id: 71a6513a-024b-40e2-ba8d-01640610c3bb
    content: "BlockBuilderのmessage_info_blockを修正: ユーザー名フィールドを追加"
    status: pending
  - id: a20b6497-a1bf-4f25-880d-6a04de71d236
    content: "DetectionServiceのspecを追加: ユーザー名・チャンネル名取得のテスト"
    status: pending
  - id: 6f89124d-b831-46f9-8243-e556fd630bcc
    content: "BlockBuilderのspecを作成: message_info_blockのテスト"
    status: pending
  - id: fabe442e-30c9-46b8-8678-c9c58aa3f698
    content: SlackApiClientのspecを作成（作成する場合）
    status: pending
  - id: de4719fe-86b9-4445-bd27-0c1137aa4781
    content: すべてのspecがpassすることを確認
    status: pending
  - id: 35900cb0-8601-45fb-9183-85db647ce3fe
    content: rubocopをpassさせる
    status: pending
---

# Slack通知にユーザー名とチャンネル名を表示する実装計画

## 概要

Slack通知時に「誰（ユーザー名）」と「チャンネル名」を表示できるようにする。DetectionService実行時にSlack APIでユーザー名とチャンネル名を取得し、DBにキャッシュする。テーブル変更は不要。

## 実装方針

- **実行タイミング**: `DetectionService.create_or_update_suspect` 内で、Suspect保存前に実行
- **データ取得**: Slack API `users.info` と `conversations.info` を使用
- **キャッシュ**: 
- ユーザー名: `compliance_slack_users.display_name` に保存（既に設定済みなら再取得しない）
- チャンネル名: `compliance_slack_suspects.channel_name` に保存（既に設定済みなら再取得しない）
- **エラーハンドリング**: API失敗時は既存のIDを保持し、処理は継続

## 実装タスク

### 1. Slack APIクライアントの共通化（オプション）

- **ファイル**: `app/services/compliances/slacks/slack_api_client.rb` (新規)
- **内容**: `Slack::Web::Client` のラッパー、Bot token取得の共通化
- **理由**: 既存の `ChannelCreatedHandler` と同じパターンを共通化

### 2. DetectionServiceの修正

- **ファイル**: `app/services/compliances/slacks/detection_service.rb`
- **変更内容**:
- `create_or_update_suspect` 内で以下を実装:
- `fetch_and_update_user_name(user_id, workspace)`: ユーザー名取得・更新
- `fetch_channel_name(channel_id, workspace)`: チャンネル名取得
- `find_or_create_slack_user` を修正: `display_name` が未設定 or `external_user_id` と同じ場合のみAPI呼び出し
- `channel_name` の設定を修正: APIで取得したチャンネル名を設定
- メモリキャッシュ（Hash）で同一プロセス内の重複API呼び出しを防止

### 3. BlockBuilderの修正

- **ファイル**: `app/models/compliances/slacks/detection_notifiers/block_builder.rb`
- **変更内容**:
- `message_info_block` に「誰（ユーザー名）」フィールドを追加
- ユーザー名は `suspect.user.display_name` を使用（フォールバック: `message.user`）
- チャンネル名は `suspect.channel_name` を使用（既存のフォールバック維持）

### 4. Specの追加・修正

#### 4.1 DetectionServiceのspec

- **ファイル**: `spec/services/compliances/slacks/detection_service_spec.rb`
- **追加内容**:
- ユーザー名取得のテスト（API成功時、失敗時、既に設定済みの場合）
- チャンネル名取得のテスト（API成功時、失敗時、既に設定済みの場合）
- メモリキャッシュのテスト
- `Slack::Web::Client` は `instance_double` でモック

#### 4.2 BlockBuilderのspec

- **ファイル**: `spec/models/compliances/slacks/detection_notifiers/block_builder_spec.rb` (新規)
- **内容**:
- `message_info_block` にユーザー名とチャンネル名が含まれることを確認
- フォールバック動作の確認

#### 4.3 SlackApiClientのspec（作成する場合）

- **ファイル**: `spec/services/compliances/slacks/slack_api_client_spec.rb` (新規)
- **内容**: Bot token取得、クライアント生成のテスト

## 実装詳細

### API呼び出しの判定条件

- **ユーザー名**: `user.display_name.blank? || user.display_name == user.external_user_id`
- **チャンネル名**: `suspect.channel_name.blank? || suspect.channel_name.start_with?('C')` (チャンネルIDっぽい場合)

### エラーハンドリング

- API呼び出しは `rescue StandardError` で捕捉
- エラー時は既存のIDを保持し、ログに記録
- 処理は継続（通知は送信される）

### パフォーマンス対策

- 同一プロセス内で同じ `user_id` / `channel_id` のAPI呼び出しを防ぐため、メモリキャッシュ（Hash）を使用
- DBに一度保存されれば、以後はAPI呼び出し不要

## 影響範囲

- **修正ファイル**:
- `app/services/compliances/slacks/detection_service.rb`
- `app/models/compliances/slacks/detection_notifiers/block_builder.rb`
- **新規ファイル**（オプション）:
- `app/services/compliances/slacks/slack_api_client.rb`
- `spec/models/compliances/slacks/detection_notifiers/block_builder_spec.rb`
- `spec/services/compliances/slacks/slack_api_client_spec.rb` (作成する場合)
- **修正spec**:
- `spec/services/compliances/slacks/detection_service_spec.rb`

## 検証項目

- [ ] `spec/services/compliances/slacks/detection_service_spec.rb` がpass
- [ ] `spec/models/compliances/slacks/detection_notifier_spec.rb` がpass
- [ ] 新規specがpass
- [ ] すべてのファイルでrubocopがpass
- [ ] 実際のSlack通知でユーザー名とチャンネル名が表示されることを確認

## 注意事項

- Bot tokenに `users:read` と `channels:read` のスコープが必要
- Slack APIのレート制限を考慮（必要に応じてリトライ処理を追加）
- 既存のSuspect/Userデータは、次回検知時に自動的に更新される