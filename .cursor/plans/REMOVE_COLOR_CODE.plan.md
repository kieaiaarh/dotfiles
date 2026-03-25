その通りです！`color_code`はNext.js側の責務ですね。データベースに保存する必要はありません。

## `color_code`の責務分析

### 🎨 **UI表示の責務**
```typescript
// Next.js側で実装すべき
const getColorCode = (totalScore: number, domain: string, riskType: string): 'red' | 'yellow' | 'green' => {
  // RAG判定ロジック
  if (domain === 'personal_information' || riskType === 'credential') {
    return totalScore >= 75 ? 'red' : totalScore >= 50 ? 'yellow' : 'green'
  }
  return totalScore >= 80 ? 'red' : totalScore >= 50 ? 'yellow' : 'green'
}
```

### 📊 **データベース設計の見直し**

**現在の問題**:
```sql
-- 不要なカラム
t.string "color_code", limit: 10, comment: "RAG評価(red/yellow/green)"
```

**修正後**:
```sql
-- color_codeを削除
-- total_scoreから動的に計算可能
```

### 🔧 **修正が必要な箇所**

1. **スキーマ修正**
   - `compliance_teams_suspects`から`color_code`カラムを削除
   - `compliance_slack_suspects`でも同様

2. **モデル修正**
   ```ruby
   # app/models/compliances/teams/suspect.rb
   # color_codeのバリデーションを削除
   ```

3. **サービス修正**
   ```ruby
   # app/services/compliances/teams/detection_service.rb
   def create_or_update_suspect(result)
     Compliances::Teams::Suspect.find_or_initialize_by(message_id: message.id).tap do |suspect|
       suspect.assign_attributes(
         # color_code: result.color_code,  # 削除
         total_score: result.total_score,
         # ...
       )
     end
   end
   ```

4. **ScoreCalculator修正**
   ```ruby
   # app/services/compliances/teams/detectors/score_calculator.rb
   def build_labels
     {
       domain: domain_key,
       risk_type: risk_type,
       total_score: total_score,
       # color_code: color_code,  # 削除
       # ...
     }
   end
   ```

### 📋 **修正手順**

1. **スキーマから`color_code`を削除**
2. **モデルのバリデーションから`color_code`を削除**
3. **サービスから`color_code`の設定を削除**
4. **テストから`color_code`の期待値を削除**
