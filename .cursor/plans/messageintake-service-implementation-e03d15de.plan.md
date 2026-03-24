---
name: AI統合実装計画
overview: ""
todos:
  - id: 22ff585d-b74e-4100-b354-d66f2c4a4ab5
    content: Teams::Suspectモデルのenum修正
    status: pending
  - id: 8db52a11-0eb4-4bae-9dc6-3ad809133268
    content: Slack::Suspectモデルのenum修正
    status: pending
  - id: 5e804efe-f5ad-45de-9e92-b2034b62f511
    content: 共通ScoreCalculatorのseverity修正
    status: pending
  - id: edcdffa3-99bd-4745-8171-924562585d3f
    content: Teams版ScoreCalculatorのcolor_code削除とseverity修正
    status: pending
  - id: c7529e77-2227-4c17-83c2-051414480f72
    content: BackfillServiceの初期値修正
    status: pending
  - id: ae7e66ca-c918-4edc-98d4-f4e1358224f5
    content: Factory修正
    status: pending
  - id: d2d009de-8319-42b6-b774-196d00baca41
    content: I18n修正
    status: pending
  - id: 0b7169d7-aed2-48f9-affc-51c003789edf
    content: RSpec修正
    status: pending
  - id: c3c9cee4-2c40-4528-bef2-0d5869c6400b
    content: 重複抑止機能実装
    status: pending
  - id: ad439c3d-3d16-4929-9143-40a44bcf1020
    content: LOWER(pattern)インデックス追加
    status: pending
  - id: 3c1ef9ff-119c-40e8-83ff-7d655f545b52
    content: Slack版TTL統一
    status: pending
---

# AI統合実装計画

## 設計方針

### コーディング原則

- **宣言的**: メソッド名は「何をするか」を表現（`fetch_`でなく名詞形）
- **イミュータブル**: 可能な限りインスタンス変数の書き換えを避け、値を返す
- **テスタブル**: 各クラスが単一責任を持ち、依存を注入可能

### エラーハンドリング戦略

- AI呼び出し失敗時は`score: 0`で継続（ルール検知は動作）
- エラー詳細を構造化ログ＋Sentryで記録
- 監査ログに`ai_detection_failed`を記録

### platform取得戦略

- `organization.provider.provider_key`から動的取得
- `"microsoft.teams"` → `"teams"`
- `"slack.slack"` → `"slack"`
- 引数として渡さず、必要な場所で計算

---

## Phase 1: LLMプロバイダー基盤

### 1-1. BaseProviderクラス

**ファイル**: `app/services/providers/llm/base_provider.rb`

```ruby
module Providers
  module LLM
    class BaseProvider
      attr_reader :model_name, :region
      
      def initialize(model_name:, api_key:, secret_key:, region:)
        @model_name = model_name
        @api_key = api_key
        @secret_key = secret_key
        @region = region
      end
      
      def detect(content)
        raise NotImplementedError
      end
      
      private
      
      def masked_content(content)
        content
          .gsub(/\b\d{3}-\d{4}-\d{4}\b/, "[PHONE]")
          .gsub(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, "[EMAIL]")
          .gsub(/\b\d{4}-\d{4}-\d{4}-\d{4}\b/, "[CARD]")
      end
      
      def truncated_content(content, max_length: 1000)
        content.length > max_length ? "#{content[0...max_length]}..." : content
      end
    end
  end
end
```

**設計ポイント**:

- マスク・トリムは元の文字列を変更せず、新しい文字列を返す
- メソッド名は形容詞＋名詞（`masked_content`, `truncated_content`）

### 1-2. BedrockProviderクラス

**ファイル**: `app/services/providers/llm/bedrock_provider.rb`

```ruby
module Providers
  module LLM
    class BedrockProvider < BaseProvider
      def detect(content)
        processed_content = truncated_content(masked_content(content))
        start_time = Time.current
        
        response = bedrock_client.invoke_model(
          model_id: model_name,
          body: prompt_body(processed_content).to_json
        )
        
        parsed_result(response, start_time)
      rescue Aws::BedrockRuntime::Errors::ServiceError => e
        log_and_notify_error(e, content)
        failed_result(e)
      end
      
      private
      
      def bedrock_client
        @bedrock_client ||= Aws::BedrockRuntime::Client.new(
          region: region,
          access_key_id: @api_key,
          secret_access_key: @secret_key
        )
      end
      
      def prompt_body(content)
        {
          prompt: compliance_prompt(content),
          max_tokens: 500,
          temperature: 0.1
        }
      end
      
      def compliance_prompt(content)
        <<~PROMPT
          以下のメッセージをコンプライアンス観点で分析してください。
          
          メッセージ: "#{content}"
          
          以下の形式で回答してください：
          SCORE: [0-100の数値]
          CONFIDENCE: [0-1の数値]
          REASONING: [簡潔な理由]
        PROMPT
      end
      
      def parsed_result(response, start_time)
        body = JSON.parse(response.body.read)
        text = body.dig('completions', 0, 'data', 'text')
        
        {
          score: extract_score(text),
          confidence: extract_confidence(text),
          reasoning: extract_reasoning(text),
          model_name: model_name,
          latency_ms: elapsed_milliseconds(start_time)
        }
      end
      
      def extract_score(text) = text.match(/SCORE: (\d+)/)[1].to_i
      def extract_confidence(text) = text.match(/CONFIDENCE: ([\d.]+)/)[1].to_f
      def extract_reasoning(text) = text.match(/REASONING: (.+)/)[1]
      
      def elapsed_milliseconds(start_time)
        ((Time.current - start_time) * 1000).round
      end
      
      def failed_result(error)
        {
          score: 0,
          confidence: 0,
          reasoning: "AI呼び出し失敗: #{error.class.name}",
          model_name: model_name,
          latency_ms: 0
        }
      end
      
      def log_and_notify_error(error, content)
        Rails.logger.error(
          "[BedrockProvider] AI detection failed",
          error_class: error.class.name,
          error_message: error.message,
          model_name: model_name,
          content_length: content.length,
          region: region
        )
        
        return if Rails.env.test?
        
        Sentry.capture_exception(error, extra: {
          provider: "bedrock",
          model_name: model_name,
          content_length: content.length,
          region: region
        })
      end
    end
  end
end
```

**設計ポイント**:

- 各メソッドは値を返すのみ（副作用なし）
- エラー処理は専用メソッドに分離
- endレス定義で簡潔に

### 1-3. TriageModel / FinalModel

**ファイル**: `app/services/providers/llm/triage_model.rb`, `final_model.rb`

```ruby
module Providers
  module LLM
    class TriageModel < BedrockProvider
      def initialize(model_name:, api_key:, secret_key:, region:)
        super
      end
    end
    
    class FinalModel < BedrockProvider
      def initialize(model_name:, api_key:, secret_key:, region:)
        super
      end
    end
  end
end
```

---

## Phase 2: AI検知器

### 2-1. AiDetectorクラス

**ファイル**: `app/services/compliances/detectors/ai_detector.rb`

```ruby
module Compliances
  module Detectors
    class AiDetector
      attr_reader :content, :rule_score, :domain_key, :risk_type, :organization
      
      def initialize(content:, rule_score:, domain_key:, risk_type:, organization:)
        @content = content
        @rule_score = rule_score
        @domain_key = domain_key
        @risk_type = risk_type
        @organization = organization
      end
      
      def detect
        return skipped_result if skip_ai?
        
        ai_model.detect(content)
      end
      
      private
      
      def skip_ai?
        !ai_enabled? || strong_rule_match? || rule_definitive_risk?
      end
      
      def ai_enabled?
        compliance_config.dig(platform.to_sym, :ai_enabled) || false
      end
      
      def strong_rule_match? = rule_score >= 90
      
      def rule_definitive_risk?
        %w[pii credential regulatory_phrase].include?(risk_type)
      end
      
      def ai_model
        case ai_tier
        when :triage then triage_model
        when :final then final_model
        else raise "Invalid AI tier: #{ai_tier}"
        end
      end
      
      def ai_tier
        case rule_score
        when 60..89 then :triage
        when 40..59 then :final
        else :none
        end
      end
      
      def triage_model
        @triage_model ||= Providers::LLM::TriageModel.new(
          model_name: ai_config[:models][:triage],
          api_key: aws_credentials[:access_key_id],
          secret_key: aws_credentials[:secret_access_key],
          region: aws_credentials[:region]
        )
      end
      
      def final_model
        @final_model ||= Providers::LLM::FinalModel.new(
          model_name: ai_config[:models][:final],
          api_key: aws_credentials[:access_key_id],
          secret_key: aws_credentials[:secret_access_key],
          region: aws_credentials[:region]
        )
      end
      
      def platform
        @platform ||= organization.provider.provider_key.split('.').first
      end
      
      def compliance_config
        @compliance_config ||= Rails.application.credentials.compliance[Rails.env.to_sym]
      end
      
      def ai_config
        @ai_config ||= compliance_config[:ai]
      end
      
      def aws_credentials
        @aws_credentials ||= ai_config[:aws]
      end
      
      def skipped_result
        {
          score: 0,
          confidence: 0,
          reasoning: "AI呼び出しスキップ（rule_score: #{rule_score}, risk_type: #{risk_type}）",
          model_name: "skipped",
          latency_ms: 0
        }
      end
    end
  end
end
```

**設計ポイント**:

- 判定ロジックは述語メソッド（`skip_ai?`, `ai_enabled?`）で宣言的に
- 設定読み込みはメモ化で1度だけ
- `platform`は動的計算

---

## Phase 3: ScoreCalculator改修

### 3-1. AI統合

**ファイル**: `app/services/compliances/detectors/score_calculator.rb`

```ruby
module Compliances
  module Detectors
    class ScoreCalculator
      DetectionResult = Struct.new(
        :rule_score, :ai_score, :total_score,
        :severity, :labels, keyword_init: true
      )
      
      THRESHOLDS = {
        default: { red: 80, yellow: 50 },
        personal_information: { red: 75, yellow: 50 },
        credential: { red: 75, yellow: 50 }
      }.freeze
      
      def initialize(message:, organization:)
        @message = message
        @organization = organization
      end
      
      def calculate(hits)
        return empty_result if hits.empty?
        
        max_hit = hits.max_by { |h| h[:score] }
        rule_score = max_hit[:score]
        
        ai_result = ai_detection_result(max_hit, rule_score)
        total_score = synthesized_score(rule_score, ai_result)
        severity = severity_for(total_score, max_hit[:rule])
        
        DetectionResult.new(
          rule_score: rule_score,
          ai_score: ai_result[:score],
          total_score: total_score,
          severity: severity,
          labels: detection_labels(hits, max_hit, total_score, ai_result)
        )
      end
      
      private
      
      def empty_result
        DetectionResult.new(
          rule_score: 0, ai_score: 0, total_score: 0,
          severity: :low, labels: {}
        )
      end
      
      def ai_detection_result(max_hit, rule_score)
        ai_detector.detect
      rescue StandardError => e
        log_ai_failure(e, max_hit)
        create_audit_log_for_failure(e, max_hit)
        { score: 0, confidence: 0, reasoning: "AI例外: #{e.class.name}", latency_ms: 0 }
      end
      
      def ai_detector
        @ai_detector ||= AiDetector.new(
          content: normalized_content,
          rule_score: rule_score,
          domain_key: max_hit[:rule].domain_key,
          risk_type: max_hit[:rule].risk_type,
          organization: @organization
        )
      end
      
      def synthesized_score(rule_score, ai_result)
        ai_total = ai_result[:score] + 
                   context_bonus(ai_result) + 
                   behavior_bonus + 
                   inversion_bonus(ai_result)
        
        [rule_score, ai_total].max.clamp(0, 100)
      end
      
      def context_bonus(ai_result)
        case ai_result[:confidence]
        when 0.9..1.0 then 10
        when 0.7...0.9 then 7
        when 0.5...0.7 then 5
        else 0
        end
      end
      
      def behavior_bonus = 0 # 将来実装
      
      def inversion_bonus(ai_result)
        ai_result[:reasoning]&.include?("皮肉") ? 5 : 0
      end
      
      def severity_for(total, rule)
        threshold = threshold_for(rule)
        return :high if total >= threshold[:red]
        return :medium if total >= threshold[:yellow]
        :low
      end
      
      def threshold_for(rule)
        if rule.risk_type == "credential"
          THRESHOLDS[:credential]
        else
          THRESHOLDS[rule.domain_key.to_sym] || THRESHOLDS[:default]
        end
      end
      
      def detection_labels(hits, max_hit, total_score, ai_result)
        rule = max_hit[:rule]
        metadata = parsed_metadata(rule.metadata_json)
        
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
      end
      
      def evidence_summary(hits, max_hit)
        {
          hits_count: hits.size,
          max_score_rule: max_hit[:rule].pattern,
          all_evidence: hits.pluck(:evidence)
        }
      end
      
      def ai_model_info(ai_result)
        {
          name: ai_result[:model_name],
          confidence: ai_result[:confidence],
          reasoning: ai_result[:reasoning],
          latency_ms: ai_result[:latency_ms]
        }
      end
      
      def parsed_metadata(json_string)
        return {} if json_string.blank?
        JSON.parse(json_string)
      rescue JSON::ParserError
        {}
      end
      
      def normalized_content
        @normalized_content ||= ContentNormalizer.normalize(@message.content_text)
      end
      
      def log_ai_failure(error, max_hit)
        Rails.logger.error(
          "[ScoreCalculator] AI detection exception",
          error_class: error.class.name,
          error_message: error.message,
          message_id: @message.id,
          organization_id: @organization.id,
          domain_key: max_hit[:rule].domain_key
        )
      end
      
      def create_audit_log_for_failure(error, max_hit)
        Compliances::AuditLog.create!(
          business_id: @organization.business_id,
          actor_type: "system",
          action: "ai_detection_failed",
          resource_type: "ai_detector",
          audit_context_json: {
            error_class: error.class.name,
            error_message: error.message,
            message_id: @message.id,
            organization_id: @organization.id,
            domain_key: max_hit[:rule].domain_key
          }
        )
      rescue StandardError => e
        Rails.logger.error("[ScoreCalculator] Failed to create audit log: #{e.message}")
      end
    end
  end
end
```

**設計ポイント**:

- 計算ロジックは小さなメソッドに分割
- 各メソッドは値を返すのみ
- エラー処理は専用メソッドに分離

---

## Phase 4: RuleDetector改修

### 4-1. ScoreCalculatorへのmessage/organization注入

**ファイル**: `app/services/compliances/detectors/rule_detector.rb`

```ruby
def score_calculator
  @score_calculator ||= ScoreCalculator.new(
    message: message,
    organization: organization
  )
end
```

---

## Phase 5: Rails Credentials設定

### 5-1. credentials.yml.enc編集

```bash
EDITOR="code --wait" rails credentials:edit
```
```yaml
compliance:
  development:
    # 既存設定
    base_url: https://compliancepolice.local
    slack: { ... }
    
    # AI統合設定
    teams:
      duplicate_prevention_enabled: true
      duplicate_prevention_window_minutes: 5
      ai_enabled: true
    slack:
      duplicate_prevention_enabled: true
      duplicate_prevention_window_minutes: 5
      ai_enabled: true
    ai:
      provider: "bedrock"
      models:
        triage: "anthropic.claude-3-haiku-20240307"
        final: "anthropic.claude-3-sonnet-20240229"
      aws:
        access_key_id: "AKIA..."
        secret_access_key: "..."
        region: "us-east-1"
```

---

## Phase 6: テスト実装

### 6-1. BedrockProviderテスト

**ファイル**: `spec/services/providers/llm/bedrock_provider_spec.rb`

```ruby
RSpec.describe Providers::LLM::BedrockProvider do
  describe "#detect" do
    context "正常系" do
      it "Bedrockからスコアを取得する"
      it "PIIをマスクする"
      it "1000文字を超える場合はトリムする"
      it "レイテンシを記録する"
    end
    
    context "異常系" do
      it "Bedrock APIエラー時はスコア0を返す"
      it "エラーログを出力する"
      it "Sentryに通知する"
    end
  end
end
```

### 6-2. AiDetectorテスト

**ファイル**: `spec/services/compliances/detectors/ai_detector_spec.rb`

```ruby
RSpec.describe Compliances::Detectors::AiDetector do
  describe "#detect" do
    context "AI呼び出しスキップ条件" do
      it "ai_enabled: falseの場合はスキップ"
      it "rule_score >= 90の場合はスキップ"
      it "risk_type: pii/credential/regulatory_phraseの場合はスキップ"
    end
    
    context "AI tierの選択" do
      it "rule_score 60-89はtriageモデル"
      it "rule_score 40-59はfinalモデル"
    end
  end
end
```

### 6-3. ScoreCalculatorテスト更新

**ファイル**: `spec/services/compliances/detectors/score_calculator_spec.rb`

```ruby
RSpec.describe Compliances::Detectors::ScoreCalculator do
  describe "#calculate" do
    context "AI統合" do
      it "ルールスコアとAIスコアを合成する"
      it "ボーナス補正を適用する"
      it "AI失敗時もルール検知は継続する"
      it "AI失敗時は監査ログを記録する"
    end
  end
end
```

---

## Definition of Done

- [ ] BedrockProvider実装完了（PII マスク、トリム、エラー処理）
- [ ] AiDetector実装完了（ゲーティング、tier選択、platform動的取得）
- [ ] ScoreCalculator改修完了（AI統合、合成式、ボーナス計算）
- [ ] Rails Credentials設定完了
- [ ] 全RSpecグリーン（Teams/Slack両方）
- [ ] AI無効化時は既存のルール検知が正常動作
- [ ] AI失敗時はスコア0で継続＋監査ログ記録
- [ ] Sentryでエラー詳細が確認可能
- [ ] コードが宣言的でイミュータブル