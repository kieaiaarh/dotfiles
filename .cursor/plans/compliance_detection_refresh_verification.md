# コンプライアンス検知ロジック刷新 - 動作確認手順

## 前提条件

- 開発環境が起動している
- データベースが最新の状態
- 既存の検知ルールが投入されている

## ステップ 1: パワハラ 12 軸の定義を生成

```bash
# パワハラ12軸の定義をYAML/JSON形式で生成
bundle exec rake compliances:power_harassment:show_axes

# 生成されたファイルを確認
cat config/compliances/power_harassment_axes.yml
cat config/compliances/power_harassment_axes.json
```

**確認ポイント**:

- 12 軸すべてが定義されているか
- 各軸に`axis_key`, `axis_label`, `description`, `examples`が含まれているか

## ステップ 2: 既存データの移行（注意: 本番環境では慎重に）

```bash
# 移行前の状態を確認
bundle exec rails runner "puts Compliances::DetectionRule.group(:domain_key).count"

# 移行スクリプトを実行（開発環境のみ）
bundle exec rake compliances:detection_rules:migrate_domain_keys

# 移行後の状態を確認
bundle exec rails runner "puts Compliances::DetectionRule.group(:domain_key).count"
```

**確認ポイント**:

- `power_harassment: 0`に既存の harassment ルールが移行されているか
- `sexual_harassment: 1`にセクハラ系ルールが移行されているか
- `others: 2`にその他のカテゴリが移行されているか

## ステップ 3: ContentNormalizer のテスト実行

```bash
# ContentNormalizerのテストを実行
bundle exec rspec spec/services/compliances/detectors/content_normalizer_spec.rb

# 手動で動作確認
bundle exec rails runner "
  content = 'こんにちは <@U12345> https://example.com :thumbsup: 👍 さん'
  result = Compliances::Detectors::ContentNormalizer.normalize(content)
  puts result
"
```

**確認ポイント**:

- メンションが`<mention>`に正規化されるか
- URL が`<url>`に正規化されるか
- スタンプが`<stamp>`に正規化されるか
- 絵文字が`<emoji>`に正規化されるか

## ステップ 4: KeywordDetector のテスト実行

```bash
# KeywordDetectorのテストを実行
bundle exec rspec spec/services/compliances/detectors/keyword_detector_spec.rb

# 手動で動作確認（長いパターン優先の確認）
cat > /tmp/test_keyword_detector.rb << 'EOF'
content = "無能な奴だ"
rules = [
  Compliances::DetectionRule.create!(
    domain_key: :power_harassment,
    risk_type: :verbal,
    rule_type: :keyword,
    pattern: "無能",
    base_score: 85
  ),
  Compliances::DetectionRule.create!(
    domain_key: :power_harassment,
    risk_type: :verbal,
    rule_type: :keyword,
    pattern: "無能な奴",
    base_score: 90
  )
]
detector = Compliances::Detectors::KeywordDetector.new(content: content, rules: rules)
result = detector.detect
puts "検知数: #{result.size}"
result.each { |r| puts "  - #{r[:rule].pattern}: #{r[:score]}点" }
EOF
bundle exec rails runner /tmp/test_keyword_detector.rb
```

**確認ポイント**:

- 長いパターン（「無能な奴」）が優先されるか
- 短いパターン（「無能」）が重複としてスキップされるか

## ステップ 5: Slack データ分析（データがある場合）

```bash
# 半年分のSlackデータを分析
bundle exec rake compliances:slack_data:analyze

# 生成されたファイルを確認
cat tmp/slack_analysis_results.csv | head -20
cat tmp/slack_analysis_stats.json | jq '.top_words' | head -20
```

**確認ポイント**:

- 分析結果が CSV/JSON 形式で出力されているか
- 頻出単語・フレーズが抽出されているか
- パワハラキーワードを含む未検知メッセージが抽出されているか

## ステップ 6: Knowledge Bases への Markdown アップロード（手動）

1. AWS コンソールにログイン
2. Amazon Bedrock > Knowledge bases に移動
3. 対象の Knowledge Base を選択
4. 「Add data source」または「Sync」を実行
5. `docs/knowledge_bases/power_harassment.md`をアップロード

**確認ポイント**:

- Markdown ファイルが Knowledge Base に正しくアップロードされているか
- インデックスが完了しているか（通常数分かかります）

## ステップ 7: 辞書生成（Knowledge Bases アップロード後）

```bash
# Knowledge Base IDを環境変数で指定して辞書生成
export KNOWLEDGE_BASE_ID=your-knowledge-base-id
export AWS_REGION=ap-northeast-1

bundle exec rake compliances:dictionary:generate

# 生成されたJSONを確認
cat tmp/detection_rules.json | jq '.axes[0]' | head -30
```

**確認ポイント**:

- 各軸に対してパターンが生成されているか
- `type`（word/phrase/regex）が適切に設定されているか
- `strength`（strong/medium/weak）が適切に設定されているか

## ステップ 8: 生成された辞書を DB に投入

```bash
# JSONファイルからDBに投入
bundle exec rake compliances:detection_rules:import_from_json JSON_FILE=tmp/detection_rules.json

# 投入結果を確認
bundle exec rails runner "
  puts \"投入されたルール数: #{Compliances::DetectionRule.count}\"
  puts \"パワハラルール数: #{Compliances::DetectionRule.where(domain_key: :power_harassment).count}\"
  puts \"有効なルール数: #{Compliances::DetectionRule.enabled.count}\"
"
```

**確認ポイント**:

- 新規ルールが追加されているか
- 既存ルールが更新されているか
- `metadata_json`に`axis_key`と`axis_label`が保存されているか

## ステップ 9: 実際のメッセージで検知動作確認

```bash
# テストメッセージで検知を実行
bundle exec rails runner "
  # テスト用のメッセージを作成
  message = Compliances::Slacks::Message.new(
    text: '無能な奴は死ね',
    business_id: 1,
    workspace_id: 1,
    ts: Time.current.to_f.to_s,
    user: 'U12345',
    channel: 'C12345'
  )

  # 検知を実行
  service = Compliances::Slacks::DetectionService.new(message: message)
  result = service.detect

  puts \"検知結果:\"
  puts \"  スコア: #{result[:total_score]}\"
  puts \"  重大度: #{result[:severity]}\"
  puts \"  ルール数: #{result[:rule_hits].size}\"
  result[:rule_hits].each do |hit|
    puts \"    - #{hit[:rule].pattern}: #{hit[:score]}点\"
  end
"
```

**確認ポイント**:

- パワハラ的な表現が正しく検知されるか
- 長いパターンが優先されているか
- スコアが適切に計算されているか

## ステップ 10: 既存ルールとの整合性確認

```bash
# 既存の検知ルールが正しく動作するか確認
bundle exec rails runner "
  # 既存のルールで検知されるメッセージをテスト
  test_messages = [
    '無能',
    '死ね',
    'クビ',
    'バカ',
    '草、無能',
    'w 使えない'
  ]

  test_messages.each do |text|
    message = Compliances::Slacks::Message.new(
      text: text,
      business_id: 1,
      workspace_id: 1,
      ts: Time.current.to_f.to_s,
      user: 'U12345',
      channel: 'C12345'
    )

    normalized = Compliances::Detectors::ContentNormalizer.normalize(text)
    puts \"\\nメッセージ: #{text}\"
    puts \"正規化後: #{normalized}\"

    rules = Compliances::DetectionRule.enabled.where(domain_key: :power_harassment, rule_type: :keyword)
    detector = Compliances::Detectors::KeywordDetector.new(content: normalized, rules: rules)
    hits = detector.detect

    if hits.any?
      puts \"  検知: #{hits.map { |h| h[:rule].pattern }.join(', ')}\"
    else
      puts \"  未検知\"
    end
  end
"
```

**確認ポイント**:

- 既存のルールが引き続き動作するか
- 新しい正規化処理が既存ルールに影響を与えていないか

## ステップ 11: パフォーマンステスト（オプション）

```bash
# 大量のメッセージでパフォーマンスを確認
bundle exec rails runner "
  require 'benchmark'

  test_message = '無能な奴は死ね。草、マジでやばい。w'
  normalized = Compliances::Detectors::ContentNormalizer.normalize(test_message)
  rules = Compliances::DetectionRule.enabled.where(domain_key: :power_harassment, rule_type: :keyword)

  time = Benchmark.measure do
    1000.times do
      detector = Compliances::Detectors::KeywordDetector.new(content: normalized, rules: rules)
      detector.detect
    end
  end

  puts \"1000回の検知にかかった時間: #{time.real.round(3)}秒\"
  puts \"1回あたり: #{(time.real * 1000 / 1000).round(3)}ms\"
"
```

**確認ポイント**:

- 検知処理が十分に高速か（1 メッセージあたり数 ms 以下が理想）

## トラブルシューティング

### エラー: `domain_key`が存在しない

```bash
# enumが正しく更新されているか確認
bundle exec rails runner "puts Compliances::DetectionRule.domain_keys.keys"
```

### エラー: Knowledge Base ID が見つからない

```bash
# 環境変数を確認
echo $KNOWLEDGE_BASE_ID

# またはcredentials.yml.encを確認
EDITOR=vim bundle exec rails credentials:edit
```

### エラー: テストが失敗する

```bash
# テストデータベースをリセット
RAILS_ENV=test bundle exec rake db:reset

# テストを再実行
bundle exec rspec spec/services/compliances/detectors/
```

## 次のステップ

1. **本番環境への適用**: 開発環境で十分に動作確認した後、本番環境に適用
2. **監視**: 検知率と False Positive 率を監視
3. **継続的改善**: 実際の検知結果を分析し、辞書を継続的に改善
