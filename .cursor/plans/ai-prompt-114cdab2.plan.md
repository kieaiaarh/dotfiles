---
name: AI判定プロンプト改善計画
overview: ""
todos: []
---

# AI判定プロンプト改善計画

## 問題

現在、AIの判定理由とスコアが不一致：

- 「良い取り組み」「問題ない」という判定理由なのに、AIスコアが90点（高リスク）になっている
- プロンプトが曖昧で、スコアの意味（0=問題なし、100=違反）が明確でない
- domain_keyとrisk_typeがプロンプトで使われていない

## 解決策

プロンプトを改善し、以下を明確化：

1. スコアの定義（0=問題なし、100=重大違反）
2. domain_keyごとの判定観点を明示
3. 違反例・セーフ例を提示（Few-shot learning）
4. ネガティブ検出（問題を探すタスク）の明示
5. rule_scoreの活用

## 実装ステップ

### STEP 1: YAMLテンプレート作成

**ファイル**: `config/compliances/ai_prompt_templates.yml`

domain_keyごとの説明、違反例（5-10個）、セーフ例（5-10個）を定義：

```yaml
power_harassment:
  description: "パワーハラスメント（脅迫、侮辱、過度な叱責、退職強要など）"
  violation_examples:
    - "バカ"
    - "死ね"
    - "使えないやつ"
    - "さっさと辞めろ"
    - "給料泥棒"
  safe_examples:
    - "改善をお願いします"
    - "次回までに修正してください"
    - "別のアプローチを検討しましょう"
    - "サポートします"
    - "一緒に取り組みましょう"

sexual_harassment:
  description: "セクシャルハラスメント（性的発言、身体的特徴への言及など）"
  violation_examples:
    - "セクシー"
    - "スタイルいいね"
    - "胸"
  safe_examples:
    - "プレゼンお疲れ様でした"
    - "良い提案ですね"

others:
  description: "情報漏洩・個人情報・ITポリシー違反"
  violation_examples:
    - "パスワードは12345"
    - "社外秘"
  safe_examples:
    - "資料を共有します"
    - "Notionページを作成しました"
```

**確認**: YAMLファイル作成後、RuboCopは不要（YAML）

### STEP 2: CompliancePromptBuilder作成とテスト

**ファイル**: `app/services/providers/llm/bedrock_provider/compliance_prompt_builder.rb`

実装内容：

- YAMLテンプレート読み込み
- domain_key/risk_type/rule_scoreを使った詳細プロンプト生成
- スコア定義、役割、違反例、セーフ例を含む構造化プロンプト

**ファイル**: `spec/services/providers/llm/bedrock_provider/compliance_prompt_builder_spec.rb`

テスト内容：

- 各domain_keyでプロンプトが生成されること
- 違反例・セーフ例が含まれること
- rule_scoreが反映されること
- スコア定義が明記されていること

**確認**:

1. RuboCop実行: `bundle exec rubocop -A app/services/providers/llm/bedrock_provider/compliance_prompt_builder.rb`
2. Spec実行: `bundle exec rspec spec/services/providers/llm/bedrock_provider/compliance_prompt_builder_spec.rb`
3. 全てpassすることを確認

### STEP 3: BaseProvider修正

**ファイル**: `app/services/providers/llm/base_provider.rb`

修正内容：

- コンストラクタに`domain_key: nil`、`risk_type: nil`を追加
- `detect`メソッドのシグネチャに`rule_score: nil`を追加

**確認**:

1. RuboCop実行: `bundle exec rubocop -A app/services/providers/llm/base_provider.rb`

### STEP 4: BedrockProvider修正とテスト更新

**ファイル**: `app/services/providers/llm/bedrock_provider.rb`

修正内容：

1. コンストラクタに`domain_key`、`risk_type`を追加
2. `detect(content, rule_score: nil)`にシグネチャ変更
3. `prompt_body(content, rule_score)`に変更
4. `compliance_prompt`を`CompliancePromptBuilder`に委譲

**ファイル**: `spec/services/providers/llm/bedrock_provider_spec.rb`

修正内容：

- 全てのproviderインスタンス生成に`domain_key: 'power_harassment'`、`risk_type: 'verbal'`を追加
- `detect`呼び出しを`detect(content, rule_score: 70)`形式に変更（必要に応じて）
- `prompt_body`のテストを更新

**確認**:

1. RuboCop実行: `bundle exec rubocop -A app/services/providers/llm/bedrock_provider.rb spec/services/providers/llm/bedrock_provider_spec.rb`
2. Spec実行: `bundle exec rspec spec/services/providers/llm/bedrock_provider_spec.rb`
3. 全てpassすることを確認

### STEP 5: AiDetector修正とテスト更新

**ファイル**: `app/services/compliances/detectors/ai_detector.rb`

修正内容：

1. `triage_model`と`final_model`のmodel_optionsに`domain_key: @domain_key`、`risk_type: @risk_type`を追加
2. `ai_model.detect(content, rule_score: @rule_score)`に変更

**ファイル**: `spec/services/compliances/detectors/ai_detector_spec.rb`

修正内容：

- モックの`detect`メソッド呼び出しに`rule_score`引数の期待値を追加
- 必要に応じてテストケースを追加

**確認**:

1. RuboCop実行: `bundle exec rubocop -A app/services/compliances/detectors/ai_detector.rb spec/services/compliances/detectors/ai_detector_spec.rb`
2. Spec実行: `bundle exec rspec spec/services/compliances/detectors/ai_detector_spec.rb`
3. 全てpassすることを確認

### STEP 6: 統合テストと影響範囲確認

compliance関連の全テストがpassすることを確認：

**1. 個別テスト実行**:

```bash
# Providersのテスト
bundle exec rspec spec/services/providers/llm/

# Detectorsのテスト
bundle exec rspec spec/services/compliances/detectors/
```

**2. compliance関連の全テスト実行**:

```bash
# Models
bundle exec rspec spec/models/compliances/

# Requests
bundle exec rspec spec/requests/compliance/

# Services
bundle exec rspec spec/services/compliances/

# Jobs
bundle exec rspec spec/jobs/compliances/
```

**3. エラーが出た場合の対応**:

- モックの引数不一致: `detect`メソッドに`rule_score`引数を追加
- コンストラクタエラー: `domain_key`、`risk_type`をオプショナル引数として追加
- 既存のテストが失敗する場合は、該当テストを修正

**4. RuboCop全体チェック**:

```bash
bundle exec rubocop app/services/providers/llm/ app/services/compliances/detectors/ spec/services/
```

## 変更ファイル一覧

### 新規作成

- `config/compliances/ai_prompt_templates.yml`
- `app/services/providers/llm/bedrock_provider/compliance_prompt_builder.rb`
- `spec/services/providers/llm/bedrock_provider/compliance_prompt_builder_spec.rb`

### 修正

- `app/services/providers/llm/base_provider.rb`
- `app/services/providers/llm/bedrock_provider.rb`
- `app/services/compliances/detectors/ai_detector.rb`
- `spec/services/providers/llm/bedrock_provider_spec.rb`
- `spec/services/compliances/detectors/ai_detector_spec.rb`

### 影響を受ける可能性のあるテスト（必要に応じて修正）

- `spec/models/compliances/*` - DetectionLog等のモデルテスト
- `spec/requests/compliance/*` - APIリクエストテスト
- `spec/services/compliances/*` - DetectionService等のサービステスト
- `spec/jobs/compliances/*` - Jobのテスト

## 各STEP完了条件

各STEPは以下の条件を全て満たした時点で完了とする：

1. コード実装が完了している
2. RuboCopが全てpassしている（`-A`で自動修正済み）
3. 関連するSpecが全てpassしている
4. 変更による既存テストへの影響を確認し、必要に応じて修正済み

## STEP 6完了条件

以下の全テストがpassすること：

- `spec/models/compliances/*`
- `spec/requests/compliance/*`
- `spec/services/compliances/*`
- `spec/jobs/compliances/*`
- `spec/services/providers/llm/*`

## 期待される効果

1. AIスコアと判定理由が一致する
2. 「良い取り組み」→低スコア、「違反」→高スコアの正しい判定
3. カテゴリごとの適切な判定（パワハラ/セクハラ/情報漏洩）
4. Few-shot learningによる精度向上
5. 既存機能への影響なし（全テストpass）