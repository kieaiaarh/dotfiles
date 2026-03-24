# コンプライアンス検知フロー現状レポート

## 概要

本レポートは、Slack/Teams の検知フロー、suspects 保存処理、ルール読み込み部分の現状を整理したものです。

## 検知フロー呼び出し構造

### 1. エントリーポイント

#### Slack

- **ファイル**: `app/services/compliances/slacks/detection_service.rb`
- **呼び出し元**: `app/models/compliances/api/integration/slack_event/message_handler.rb` (line 50)
  - `Compliances::Slacks::DetectionService.run(message:)`

#### Teams

- **ファイル**: `app/services/compliances/teams/detection_service.rb`
- **呼び出し元**: 未確認（要調査）

### 2. 基底クラス: DetectionService

**ファイル**: `app/services/compliances/detection_service.rb`

**処理フロー**:

1. `execute` メソッドが呼ばれる（private）
2. `rule_detector.detect` で検知実行
3. `detection_result.total_score < 30` の場合は nil を返す（保存しない）
4. 重複チェック（`duplicate_check?` と `recent_duplicate_exists?`）
5. `create_or_update_suspect(detection_result)` で保存（プラットフォーム固有）
6. `create_audit_log` で監査ログ作成

**重要メソッド**:

- `rule_detector`: `Compliances::Detectors::RuleDetector` を生成
- `create_or_update_suspect`: サブクラスで実装必須

### 3. 検知エンジン: RuleDetector

**ファイル**: `app/services/compliances/detectors/rule_detector.rb`

**処理フロー**:

1. `detect` メソッドで各検知器を実行
   - `keyword_detector.detect` (KeywordDetector)
   - `regex_detector.detect` (RegexDetector)
   - `pii_detector.detect` (PiiDetector)
   - `url_detector.detect` (UrlDetector)
2. 各検知器は `hits` 配列を返す（`{ rule:, evidence:, score: }` 形式）
3. `score_calculator.calculate(hits)` でスコア計算

**検知器クラス**:

- `KeywordDetector`: キーワード辞書マッチング
- `RegexDetector`: 正規表現パターンマッチング
- `PiiDetector`: PII（個人情報）検知
- `UrlDetector`: URL パターン検知

### 4. スコア計算: ScoreCalculator

**ファイル**: `app/services/compliances/detectors/score_calculator.rb`

**現状の処理**:

1. `calculate(hits)` で hits を受け取る
2. `max_hit = hits.max_by { |h| h[:score] }` で最大スコアの hit を取得
3. `rule_score = max_hit[:score]` でルールスコアを設定（現状は最大値のみ）
4. `ai_detection_result(max_hit, rule_score)` で AI 検知を実行
5. `synthesized_score` で合成スコア計算
6. `severity_for` で重大度判定
7. `DetectionResult` 構造体を返す

**DetectionResult 構造**:

```ruby
DetectionResult = Struct.new(
  :rule_score, :ai_score, :total_score,
  :severity, :labels, keyword_init: true
)
```

**labels の現状構造**:

```ruby
{
  domain: rule.domain_key,
  risk_type: rule.risk_type,
  policy_key: metadata["policy_key"],
  evidence: evidence_summary(hits, max_hit),
  rule_score: max_hit[:score],
  ai_score: ai_result[:score],
  total_score: total_score,
  ai_model: ai_model_info(ai_result)
}
```

### 5. ルール読み込み: RuleLoader

**ファイル**: `app/services/compliances/detectors/rule_loader.rb`

**処理フロー**:

1. `load` メソッドでルールを読み込む
2. `Compliances::DetectionRule.enabled.to_a` で共通ルールを取得
3. `organization_rules` で組織固有ルールを取得
4. `apply_overrides` で組織固有の上書きを適用
5. ルール配列を返す

**ルール定義テーブル**:

- `compliance_detection_rules`: 共通ルール
- `compliance_organization_detection_rules`: 組織固有ルール

**ルールモデル**: `app/models/compliances/detection_rule.rb`

- `domain_key`: ドメイン種別（power_harassment, sexual_harassment, others）
- `risk_type`: リスク種別（verbal, pii, credential, confidential, url_sharing, regulatory_phrase, financial_unreleased）
- `rule_type`: ルール種別（keyword, regex, url_pattern, pii_pattern）
- `pattern`: 検知パターン
- `base_score`: 基礎スコア（40-100）
- `metadata_json`: 追加情報（JSON 形式）

## Suspects 保存処理

### Slack Suspects

**ファイル**: `app/services/compliances/slacks/detection_service.rb`

**保存処理** (`create_or_update_suspect`):

1. `Compliances::Slacks::Suspect.find_or_initialize_by(message_id: message.id)`
2. `find_or_create_slack_user` でユーザーを取得/作成
3. `assign_attributes` で以下を設定:
   - `severity: result.severity`
   - `rule_score: result.rule_score`
   - `ai_score: result.ai_score`
   - `total_score: result.total_score`
   - `detection_labels_json: result.labels.to_json`
4. `suspect.save!`

**モデル**: `app/models/compliances/slacks/suspect.rb`

- テーブル: `compliance_slack_suspects`
- `severity` enum: `{ low: 1, medium: 2, high: 3 }`
- `detection_labels_json` カラム: JSON 型

### Teams Suspects

**ファイル**: `app/services/compliances/teams/detection_service.rb`

**保存処理** (`create_or_update_suspect`):

1. `Compliances::Teams::Suspect.find_or_initialize_by(message_id: message.id)`
2. `assign_attributes` で以下を設定:
   - `severity: result.severity`
   - `rule_score: result.rule_score`
   - `ai_score: result.ai_score`
   - `total_score: result.total_score`
   - `detection_labels_json: result.labels.to_json`
3. `suspect.save!`

**モデル**: `app/models/compliances/teams/suspect.rb`

- テーブル: `compliance_teams_suspects`
- `severity` enum: `{ low: 1, medium: 2, high: 3 }`
- `detection_labels_json` カラム: JSON 型

## ルール定義読み込み箇所

### 1. データベースから読み込み

**RuleLoader** (`app/services/compliances/detectors/rule_loader.rb`):

- `Compliances::DetectionRule.enabled.to_a` で共通ルールを取得
- `Compliances::OrganizationDetectionRule` で組織固有ルールを取得

### 2. JSON ファイルからインポート

**タスク**: `lib/tasks/compliances/import_detection_rules_from_json.rake`

- `tmp/detection_rules.json` または `ENV['JSON_FILE']` から読み込み
- `tmp/phrase_detection_rules.json` も存在（構造確認済み）

**JSON 構造**:

```json
{
  "domains": [
    {
      "domain_key": "power_harassment",
      "risk_type": "verbal",
      "axes": [
        {
          "axis_key": "pressure",
          "axis_label": "圧・詰め",
          "policy_key": "HR-HAR-PHRASE-001",
          "patterns": [
            {
              "type": "phrase",
              "text": "なんでそんなこともできないの",
              "strength": "medium"
            }
          ]
        }
      ]
    }
  ]
}
```

**変換マッピング**:

- `strength` → `base_score`: `{ "strong" => 95, "medium" => 70, "weak" => 40 }`
- `type` → `rule_type`: `{ "word" => 1, "phrase" => 1, "regex" => 2 }`
- `metadata_json` に `policy_key`, `axis_key`, `axis_label`, `pattern_type` を保存

## 現状の課題

1. **スコア計算が最大値のみ**: 複数ルールがヒットしても最大スコアのみ使用
2. **rule_hits の構造化不足**: どのルールがヒットしたかの詳細が labels に含まれていない
3. **explanation_template 未実装**: ルール定義に説明テンプレートがない
4. **severity マッピングが固定**: 80/50 の閾値が固定で、新しい severity レベル（red/orange/yellow/none）に対応していない
5. **detection_labels_json の形式が非統一**: 現状は `result.labels.to_json` で保存されているが、正式スキーマが定義されていない

## 次期実装で必要な変更

1. **ScoreCalculator の刷新**: 複数ルールのスコアを統合し、rule_hits を構造化
2. **detection_labels_json の正式スキーマ化**: `{ rule_score, rule_hits, ai_score, ai_label, ai_reason, final_score, severity }` 形式
3. **ルール定義への explanation_template 追加**: JSON ファイルと DB の metadata_json に追加
4. **severity マッピングの更新**: red/orange/yellow/none への対応
5. **後方互換性の確保**: 既存の detection_labels_json を壊さない
