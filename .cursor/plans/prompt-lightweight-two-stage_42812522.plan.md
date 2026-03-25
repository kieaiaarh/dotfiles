---
name: prompt-lightweight-two-stage
overview: 1次(Nova Micro)プロンプトを軽量化し、2次(Nova Lite)専用プロンプトを追加。固定プレフィクス/可変サフィックス構造へ分離し、将来のPrompt Cachingに備えつつ既存パイプラインとスキーマを維持する。
todos:
  - id: todo-1765462639973-lqw9zby0l
    content: ""
    status: pending
---

## 方針
- 現行のMicro/Lite共通プロンプトを読み、固定部分と可変部分を分離してBASE_INSTRUCTION + suffix構造にリファクタ。
- 1次(Micro)プロンプトを短文化しつつYES/NO/GRAY基準を一括で簡潔に記述、教育文脈NOは1回だけ記載、reason例を圧縮。
- 2次(Lite)専用の軽量プロンプトクラスを新規追加し、入力にai1結果JSONを受けてYES/NOのみ返す短い指示にする。
- AiRunner等呼び出し側は既存署名を維持しつつ、stageに応じてMicro/Lite各プロンプトを使う構造を確認・必要なら切替。
- Prompt Cachingを見据え、固定プレフィクスを定数化・可変サフィクスをbuild内で組み立てる形にし、cacheConfigを後付けしやすくする。

## タスク
1. 現行プロンプト調査
   - `app/services/providers/llm/bedrock_provider/compliance_prompt_builder.rb` の構造・重複記述・理由指示を確認。
   - AiRunner/ScoreCalculator周辺のプロンプト呼び出し位置を確認 (`app/services/compliances/detectors/score_calculators/ai_runner.rb` など)。

2. プレフィクス/サフィクス分離
   - Micro用BuilderをBASE_INSTRUCTION(固定) + suffix(message, domain, risk_type, rule_pattern)に分割。
   - YES/NO/GRAY基準を1ブロックで簡潔化、教育文脈NOの記述を1回に集約、reason例文を圧縮。

3. Microプロンプト軽量化
   - 重複説明削除・カテゴリ説明は簡潔に維持。
   - 出力スキーマ(label/confidence/score/reason/risk_types)は現行を踏襲。
   - 目標: トークン700以下を意識した文量に整理。

4. Lite専用プロンプト新設
   - 新ファイル(例: `app/services/providers/llm/bedrock_provider/compliance_prompt_builder_lite.rb` または同階層)に2次用Builderを追加。
   - 入力: message + ai1_result(JSON)。出力: label(YES/NO), confidence, score, reason(20-30 tokens)。GRAYなし、カテゴリ説明は最小限。
   - 短い指示文でコスト200-300 tokensを目標。

5. 呼び出し側の切替確認
   - AiRunnerのstage: :triage でMicroプロンプト、:final でLiteプロンプトを使うようにする（既存署名を保つ）。
   - 既存パイプライン(1次→GRAY→2次)とスキーマを壊さないことを確認。

6. テスト追加/更新
   - Micro/Lite各Builderのユニットテストを追加: プレフィクスと可変部分が正しく連結されること、出力スキーマ例の含有確認。
   - Lite用新規プロンプトのテストを追加 (例: `spec/services/providers/llm/bedrock_provider/compliance_prompt_builder_lite_spec.rb`)。
   - 既存E2Eテストは変更せず、必要に応じてsnapshot/包含チェックのみ。

7. Prompt Caching導入ポイント明記
   - BASE_INSTRUCTIONを定数化し、後でcacheConfigを足せば効くことをコメント or TODO で簡潔に記載。
   - プレフィクス/サフィクス分離によりキャッシュキーが固定化される旨を明文化。

8. 差分案の記述
   - Micro Builder: BASE_INSTRUCTION定数、YES/NO/GRAY基準の簡潔化、教育文脈NOは1回、reason例の圧縮。
   - Lite Builder: 新規クラス、ai1 JSON参照、短い出力指示、GRAYなし。
   - AiRunner: stageごとのBuilder切替確認/最小変更に留める。

## テスト方針
- Builderユニットテストで固定/可変部分の連結と必須フィールドを確認。
- Lite Builderの出力例テスト。
- 既存スキーマ遵守のため既存specを参照し、壊れていないことを確認(必要に応じて最小の期待値更新)。