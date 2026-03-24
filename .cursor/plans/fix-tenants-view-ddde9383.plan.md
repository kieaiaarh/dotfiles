---
name: "Phase 4, Task V1: テナント一覧 View 修正"
overview: ""
todos: []
---

# Phase 4, Task V1: テナント一覧 View 修正

## 修正内容

### 修正ファイル

`app/views/compliance/api/teams/tenants/index.json.jbuilder`

### 変更点

1. **出力形式の変更**

   - 現在: `json.tenants @tenants do |tenant|` （テナントをラップ）
   - 修正後: `json.array! @tenants do |tenant|` （直接配列として出力）

2. **display_name フィールドの削除**

   - 要件に含まれていないため削除

3. **その他は維持**

   - `@tenants` の使用（ユーザー要望により維持）
   - `status_active` スコープ名（正しい）
   - `preload` によるN+1対策（パフォーマンス最適化）
   - `key_format! camelize: :lower` （JSON形式統一）

### 修正後のコード

```ruby
json.key_format! camelize: :lower

json.array! @tenants.preload(:teams_consent_callbacks, :teams_installs, :teams_subscriptions) do |tenant|
  json.id tenant.id
  json.external_organization_id tenant.external_organization_id
  json.consented tenant.consent_granted?
  json.consented_at tenant.consented_at
  json.install_count tenant.teams_installs.status_active.count
  json.subscription_count tenant.teams_subscriptions.status_active.count
end
```

### 出力例

**Before:**

```json
{
  "tenants": [
    { "id": 1, "externalOrganizationId": "...", ... }
  ]
}
```

**After:**

```json
[
  { "id": 1, "externalOrganizationId": "...", ... }
]
```

## 確認事項

- スコープ名 `status_active` は正しい（enum で `_prefix: true` を使用しているため）
- Controller側で適切にレンダリングされていることを確認