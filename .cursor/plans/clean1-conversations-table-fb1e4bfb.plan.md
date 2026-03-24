---
name: "Phase 7, Task CLEAN1: compliance_conversations テーブル削除"
overview: ""
todos: []
---

# Phase 7, Task CLEAN1: compliance_conversations テーブル削除

## 概要

`compliance_conversations` テーブルと関連するすべてのファイル（Model、Spec、Factory）を削除し、他のファイルからのすべての参照（association、factory）も削除します。

## 削除対象ファイル（3 ファイル）

### 1. Model ファイル

- `app/models/compliances/conversation.rb`

### 2. Spec ファイル

- `spec/models/compliances/conversation_spec.rb`

### 3. Factory ファイル

- `spec/factories/compliances/conversations.rb`

## Schemafile 修正

### 4. テーブル定義削除

**ファイル**: `db/Schemafile`

**削除範囲**: 3077-3091 行（15 行）

```3077:3091:db/Schemafile
# =========================
# conversations（入れ物※各製品に命名を寄せた）
# =========================
create_table "compliance_conversations", id: :bigint, unsigned: true, comment: "会話コンテナ（チャンネル/DM/スレッド/会議/メールスレッド等）", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC" do |t|
  t.bigint   "compliance_organization_id",   unsigned: true, null: false, comment: "FK: compliance_organizations.id"
  t.integer "conversation_type", unsigned: true, null: false, comment: "会話タイプ(enum): 0=channel,1=dm,2=thread,3=meeting,4=mail_thread,5=mailbox,6=call,7=chat"
  t.string   "external_conversation_id",    limit: 191,     null: false, comment: "外部コンテナID（channelId/roomId/threadTs/meetingId 等）"
  t.string   "parent_external_id",  limit: 191,                  comment: "親の外部ID（TeamsのteamIdや親スレッド等）"
  t.string   "display_name",        limit: 191,                  comment: "表示名（任意）"
  t.json     "metadata_json",                                    comment: "補助メタ（取得ソース・公開範囲 等）"
  t.datetime "created_at",          null: false,                 comment: "作成日時"
  t.datetime "updated_at",          null: false,                 comment: "更新日時"
  t.index ["compliance_organization_id", "external_conversation_id"], unique: true, name: "ex_conversation_organization_ext"
  t.index ["compliance_organization_id", "conversation_type"], name: "idx_conversation_organization_type"
end
```

## Model 層の参照削除（2 ファイル）

### 5. Organization Model から has_many 削除

**ファイル**: `app/models/compliances/organization.rb`

**削除対象**:

```ruby
has_many :conversations, class_name: "Compliances::Conversation", foreign_key: :compliance_organization_id, inverse_of: :organization
```

### 6. Suspect Model から belongs_to 削除

**ファイル**: `app/models/compliances/suspect.rb`

**削除対象**:

```ruby
belongs_to :conversation, class_name: "Compliances::Conversation", foreign_key: :compliance_conversation_id, optional: true
```

## Spec 層の参照削除（2 ファイル）

### 7. Organization Spec から has_many テスト削除

**ファイル**: `spec/models/compliances/organization_spec.rb`

**削除対象**:

```ruby
it { is_expected.to have_many(:conversations).class_name("Compliances::Conversation").with_foreign_key(:compliance_organization_id) }
```

### 8. Suspect Spec から belongs_to テスト削除

**ファイル**: `spec/models/compliances/suspect_spec.rb`

**削除対象**:

```ruby
it { is_expected.to belong_to(:conversation).class_name("Compliances::Conversation").with_foreign_key(:compliance_conversation_id).optional }
```

## Factory の参照削除（1 ファイル）

### 9. Suspect Factory から association 削除

**ファイル**: `spec/factories/compliances/suspects.rb`

**削除対象**:

```ruby
association :conversation, factory: :compliances_conversation
```

## Service 層の参照削除（1 ファイル）

### 10. ChatSyncService から compliance_conversation_id 削除

**ファイル**: `app/services/microsoft/teams/chat_sync_service.rb`

**削除対象**: 151 行目

```ruby
compliance_conversation_id: conversation.id,
```

**注意**: `compliance_conversation_id` カラムは nullable なので、この行を削除するだけで問題ありません。

## 実装手順

1. **ファイル削除（3 ファイル）**

   - `app/models/compliances/conversation.rb`
   - `spec/models/compliances/conversation_spec.rb`
   - `spec/factories/compliances/conversations.rb`

2. **Schemafile からテーブル定義削除**

   - `db/Schemafile` の 3077-3091 行を削除

3. **Model 層の参照削除（2 ファイル）**

   - `app/models/compliances/organization.rb`
   - `app/models/compliances/suspect.rb`

4. **Spec 層の参照削除（2 ファイル）**

   - `spec/models/compliances/organization_spec.rb`
   - `spec/models/compliances/suspect_spec.rb`

5. **Factory の参照削除（1 ファイル）**

   - `spec/factories/compliances/suspects.rb`

6. **Service 層の参照削除（1 ファイル）**

   - `app/services/microsoft/teams/chat_sync_service.rb`

7. **Ridgepole Dry-run で確認**
   ```bash
   bundle exec ridgepole -c config/database.yml -E development --apply -f db/Schemafile --dry-run
   ```

8. **Ridgepole Apply で適用**
   ```bash
   bundle exec ridgepole -c config/database.yml -E development --apply -f db/Schemafile
   ```


## 完了条件

- [ ] 3 ファイル削除完了
- [ ] Schemafile からテーブル定義削除
- [ ] 6 ファイルから参照削除（Model 2 + Spec 2 + Factory 1 + Service 1）
- [ ] Dry-run でエラーなし
- [ ] Apply 実行後、テーブルが DB から削除
- [ ] `grep "Compliance::Conversation" --type ruby` で 0 件（ドキュメントファイル除く）
- [ ] `grep "compliance_conversation" --type ruby` で 0 件（schema.rb と suspects テーブル定義除く）

## 注意点

- `db/schema.rb` は Ridgepole が自動生成するため、直接編集不要
- `compliance_suspects` テーブルの `compliance_conversation_id` カラムは nullable なので、値を設定している箇所を削除するだけで問題なし
- `ChatSyncService` の `conversation` パラメータは `Compliances::Conversation` モデルを指していたが、このパラメータ自体は残す（今後の拡張で使用する可能性があるため）