---
name: "Task CFG1: Teams ルート確認結果"
overview: ""
todos: []
---

# Task CFG1: Teams ルート確認結果

## 確認結果: ✅ すべて実装済み

`config/routes.rb` の compliance namespace 内で、TEAMS_PLAN_RAILS.md で指定された Teams 関連ルートは **すべて実装済み** です。

## 実装済みルート一覧

### 1. OAuth 関連 (785-786行目)

```ruby
get "teams/oauth", to: "teams/oauth#authorize"
get "teams/oauth/callback", to: "teams/oauth#callback"
```

- ✅ `GET /compliance/api/teams/oauth` → `Oauth#authorize`
- ✅ `GET /compliance/api/teams/oauth/callback` → `Oauth#callback`

### 2. テナント管理 (789行目)

```ruby
get "teams/tenants", to: "teams/tenants#index"
```

- ✅ `GET /compliance/api/teams/tenants` → `Tenants#index`

### 3. 購読管理 (791-793行目)

```ruby
get "teams/subscriptions", to: "teams/subscriptions#index"
post "teams/subscriptions", to: "teams/subscriptions#create"
delete "teams/subscriptions/:id", to: "teams/subscriptions#destroy"
```

- ✅ `GET /compliance/api/teams/subscriptions` → `Subscriptions#index`
- ✅ `POST /compliance/api/teams/subscriptions` → `Subscriptions#create`
- ✅ `DELETE /compliance/api/teams/subscriptions/:id` → `Subscriptions#destroy`

### 4. インストール管理 (787行目)

```ruby
post "teams/installs/conversation_update", to: "teams/installs#conversation_update"
```

- ✅ `POST /compliance/api/teams/installs/conversation_update` → `Installs#conversation_update`

**補足**: TEAMS_PLAN_RAILS.md では `post "teams/installs", to: "installs#create"` を想定していましたが、実装では `#conversation_update` という名前で、より具体的なエンドポイント名になっています。

**Controller**: `app/controllers/compliance/api/teams/installs_controller.rb` で実装済み。Bot Framework からの conversationUpdate イベントを受信し、InstallDetector サービスを呼び出します。

### 5. Webhook 受信 (807行目)

```ruby
post "integration/teams/webhook", to: "integration/teams#webhook", as: :teams_webhook
```

- ✅ `POST /compliance/api/integration/teams/webhook` → `Integration::Teams#webhook`

### 6. Webhook 健全性チェック

❌ **実装なし**（ユーザーから「途中でなしにした」との指示あり）

## 結論

✅ **Phase 5, Task CFG1 は完了済み** - 必要なすべてのルートが実装されています。

webhook_health 以外の全ルートが既に存在し、適切なコントローラにマッピングされています。追加作業は不要です。

## 確認コマンド

実装済みルートを確認：

```bash
bundle exec rake routes | grep teams
```