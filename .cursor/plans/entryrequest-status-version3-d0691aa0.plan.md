---
name: Events::EntryRequests::Status Version3 実装計画
overview: ""
todos:
  - id: 49c1069e-73b0-44de-9a18-100d20435d06
    content: Status.from と initialize を screen/version 対応に修正
    status: pending
  - id: adb3914b-703e-4c40-b63b-03f2ee9d961c
    content: Version3 クラスを追加（COMMON_CHECKS / BUSINESS_CHECKS 定義、business_status / admins_status 実装）
    status: pending
  - id: b1d962ea-3628-4cea-a3e2-0cac70dbfe70
    content: EntryRequest#status(screen) メソッドを実装（画面別キャッシュ）
    status: pending
  - id: abc93bd2-4bad-4ad0-9f7b-47646b3d1b16
    content: Version3 の spec を追加（検出、画面別判定、キャッシュ、例外フォールバック）
    status: pending
  - id: b364048b-0a99-4d37-acc2-ed65cb8d3588
    content: RuboCop と既存 spec の確認・修正
    status: pending
---

# Events::EntryRequests::Status Version3 実装計画

## 概要

`Events::EntryRequests::Status` に Version3 を追加し、画面（UI/コンテキスト）ごとに `business_status` / `admins_status` の判定条件を切り替えられるようにする。既存の命名（`business_status` / `admins_status`）は維持し、Version1/2 の互換性を保つ。

## 実装ファイル

### 1. `app/models/events/entry_requests/status.rb`

- `VERSION3_START_AT` 定数を追加（仮値: `Time.zone.local(2024, 1, 1)`）
- `Status.from(request, screen: nil, version: nil)` を実装
  - `version:` が指定されれば強制的にそのバージョンを返す
  - 未指定時は `detect_version(request)` で判定（`created_at >= VERSION3_START_AT` で Version3）
- `Status#initialize(request, screen: nil)` を修正して `screen` を受け取る
- `Version3 < Status` クラスを追加
  - `COMMON_CHECKS`: 全画面共通のチェック（Proc配列）
  - `BUSINESS_CHECKS`: 画面別のチェック定義（Hash、キーは `:default`, `:simple_form`, `:admins` など）
  - `business_status`: 画面別判定（`COMMON_CHECKS + BUSINESS_CHECKS[@screen]` を評価）
  - `admins_status`: Version2 と同等のロジック（必要なら画面別にも対応可能）
  - `safe_eval_check(&proc)`: 例外を rescue してログ出力し `false` を返すヘルパー
- 画面分割定義は提供されたYAML例をコード内定数として実装（後で正式定義に置換可能）

### 2. `app/models/events/entry_request.rb`

- `status(screen = nil)` メソッドを追加/置換
  - `screen` が `nil` の場合は既存の `@status` キャッシュを使用
  - `screen` が指定された場合は `@status_by_screen` ハッシュで画面別キャッシュ
  - 既存の `delegate` は維持（互換性のため）

### 3. `spec/models/events/entry_requests/status_spec.rb`

- Version3 検出 spec（`created_at >= VERSION3_START_AT` で Version3 を返す）
- `Status.from(request, version: 2)` で Version2 を強制取得できること
- `business_status` の画面別 spec
  - `:default` で全項目チェック
  - `:simple_form` で簡易項目のみチェック
  - `:admins` で最小限チェック
- `admins_status` の挙動 spec（Version2 互換）
- `EntryRequest#status(screen)` のキャッシュ spec
  - 同一 screen で同一オブジェクト（`be`）を返す
  - 異なる screen は別オブジェクトを返す
- 例外フォールバック spec（チェック Proc が例外を投げたとき `:drafted` を返し、ログに警告）

## 実装詳細

### 画面分割定義（初期実装）

提供されたYAML例をコード内定数として実装：

```ruby
COMMON_CHECKS = [
  -> { event_purpose.present? if questionnaire_creatable? },
  -> { purpose_details.any? if questionnaire_creatable? },
  -> { explicitly_entered?("required_questionnaire") }
].freeze

BUSINESS_CHECKS = {
  default: [
    -> { explicitly_entered?("what_plan") },
    -> { meetup_entered? },
    -> { participant_types.present? },
    -> { participant_relationship_entered? },
    -> { explicitly_entered?("participants_number") },
    -> { participant_name_pattern_entered? },
    -> { client_participant_information_entered? },
    -> { quiz_ready? if program_required_ranking? }
  ],
  simple_form: [
    -> { explicitly_entered?("what_plan") },
    -> { participant_types.present? },
    -> { explicitly_entered?("participants_number") }
  ],
  admins: [] # 最小限（admins_status は別途判定）
}.freeze
```

### チェック評価ロジック

```ruby
def business_status
  checks = COMMON_CHECKS + BUSINESS_CHECKS[@screen || :default]
  results = checks.map { |c| safe_eval_check(&c) }
  results.all? ? :entered : :drafted
end

def safe_eval_check(&proc)
  instance_exec(&proc)
rescue StandardError => e
  Rails.logger.warn("Status check failed: #{e.class} - #{e.message}")
  false
end
```

### バージョン検出

```ruby
def self.detect_version(request)
  return 3 if request.created_at >= VERSION3_START_AT
  return 2 if request.created_at >= VERSION2_START_AT
  1
end

def self.from(request, screen: nil, version: nil)
  v = version || detect_version(request)
  case v
  when 3
    Version3.new(request, screen: screen)
  when 2
    Version2.new(request)
  else
    Version1.new(request)
  end
end
```

## 互換性

- 既存の `Status.from(request)` 呼び出しは `screen: nil` で動作（既存挙動維持）
- `EntryRequest#status` の引数なし呼び出しは既存の `@status` キャッシュを使用
- Version1/2 の `business_status` / `admins_status` 実装は変更なし
- 既存の spec は全て通過することを確認

## テスト要件

- `bundle exec rspec spec/models/events/entry_requests/status_spec.rb` が全て通過
- `bundle exec rubocop` が通過
- 既存の Version1/2 の spec は変更せずに全て通過

## 注意事項

- `VERSION3_START_AT` は仮値で実装し、PR にリリース時に更新する説明を記載
- 画面分割定義は後で正式定義に置換可能な構造にする
- 例外フォールバックは `Rails.logger.warn` を使用