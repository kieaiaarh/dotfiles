---
name: ルール検知スコア刷新プラン
overview: ""
todos: []
---

# ルール検知スコア刷新プラン

## 概要

Slack/Teams の検知フローに新しい ScoreCalculator を組み込み、detection_labels_json を正式スキーマで保存しつつ、ルール定義へ explanation_template を追加する。既存挙動との後方互換を保ちつつ、構造化スコアと説明を提供できるようにする。

## 実装ステップ

1. **現状調査とレポート作成**

- `app/services/compliances/detection_service.rb` と `slacks/teams/detection_service.rb`、`detectors/rule_detector.rb`、`detectors/rule_loader.rb` を読み込み、検知呼び出しフローと Suspect 保存箇所、辞書読込箇所を整理し、コメント付きレポートを作成する。

2. **detection_labels_json スキーマ調整**

- `db/Schemafile` (テーブル `compliance_slack_suspects`, `compliance_teams_suspects`) の JSON コメント・デフォルトを更新し、必要であれば Ridgepole 用差分ファイルを追加。
- `app/models/compliances/slacks/suspect.rb` と `.../teams/suspect.rb` に JSON 形状のバリデーション/ヘルパを追加して後方互換を担保。

3. **ルール定義の explanation_template 拡張**

- `tmp/phrase_detection_rules.json` 等の辞書ファイルへ `explanation_template` を optional で追記。
- `lib/tasks/compliances/import_detection_rules_from_json.rake` 等、辞書読込コードを更新して template を DB の `metadata_json` または専用列に保存できるようにする。

4. **ScoreCalculator の刷新**

- `app/services/compliances/detectors/score_calculator.rb` を新仕様に合わせて書き換え、辞書ランク/フレーズ/構造ルールの配点ロジックを実装。
- 返却値を `{ rule_score:, rule_hits: [...] }` に変更し、AI 系フィールドは未使用で常に null を返すよう整理。

5. **Slack/Teams 検知フローの更新**

- `Compliances::DetectionService` とプラットフォーム別 detection_service を更新し、ScoreCalculator からの出力をもとに `detection_labels_json` を `{ rule_score, rule_hits, ai_score, ai_label, ai_reason, final_score, severity }` 形式で構築。
- `severity` マッピング (>=80: red / >=50: orange / >=30: yellow / else none) を実装し、`compliance_slack_suspects` / `compliance_teams_suspects` の保存ロジックを調整。

6. **RSpec 追加/更新**

- `spec/services/compliances/detectors/score_calculator_spec.rb` で配点・rule_hits・explanation_template の挙動を検証。
- Slack/Teams detection サービスのリクエスト/サービススペックを追加し、`detection_labels_json` が想定スキーマで保存されることと severity 変換をテスト。
- ルールインポートタスクや JSON 変更に伴うユニットテストを追加し、後方互換を確認。
- **必須要件**: 新規作成および変更した以下の spec ファイルについては、必ず単体テストを pass する形で保証する。
- `spec/models/compliances/*`
- `spec/requests/compliance/*`
- `spec/services/compliances/*`
- `spec/jobs/compliances/*`

## TODO

- architecture-report: 現状検知フローのレポート作成
- schema-update: detection_labels_json のスキーマ反映
- rules-template: ルールJSONへ explanation_template 追加
- scorecalc-impl: 新ScoreCalculator実装
- detection-flow: Slack/Teams検知保存の更新
- specs: ScoreCalc/保存ロジックのRSpec整備