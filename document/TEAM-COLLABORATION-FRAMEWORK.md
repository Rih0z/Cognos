# チーム協力実装フレームワーク

## 🎯 全員協力による実装体制

### チーム構成と役割分担

#### 👑 PRESIDENT（プロジェクト統括）
- 全体方針決定
- マイルストーン承認
- リソース配分

#### 🎯 boss（開発マネージャー）
- 日次進捗管理
- 技術的課題解決
- チーム間調整

#### 🤖 ai-researcher（AI/ML専門家）
- AI統合設計
- テンプレートシステム
- 安全性検証

#### 💻 os-researcher（システム専門家）
- カーネル設計
- 低レベル実装
- パフォーマンス最適化

#### 📝 lang-researcher（言語専門家）
- 言語仕様策定
- パーサー実装
- 型システム設計

## 🔄 協力作業プロセス

### 日次作業サイクル

#### 09:00-09:30 朝のスタンドアップ
```bash
# 各メンバーが報告
./agent-send.sh boss "昨日の成果: [具体的な実装内容]
今日の計画: [実装予定のタスク]  
課題: [支援が必要な部分]"
```

#### 09:30-12:00 午前実装セッション
- 個人タスクの実装
- ペアプログラミング
- コードレビュー

#### 13:00-17:00 午後統合作業
- 機能統合テスト
- ドキュメント更新
- 次日計画策定

#### 17:00-17:30 夕方振り返り
- 進捗確認
- 課題共有
- 翌日調整

### 週次作業サイクル

#### 月曜日: 計画立案
- 週次目標設定
- タスク分担
- 依存関係確認

#### 火-木曜日: 集中実装
- 個人実装タスク
- ペア作業セッション
- 中間レビュー

#### 金曜日: 統合・レビュー
- 週次統合テスト
- コード品質チェック
- 翌週計画

## 🛠️ 実装協力体制

### Phase 1: 基礎実装（Week 1-2）

#### 並行作業可能なタスク
1. **言語基礎（lang-researcher主導）**
   ```rust
   // lexer.rs - トークナイザー
   pub enum Token {
       LeftParen, RightParen,
       Symbol(String), Number(i64),
   }
   ```

2. **評価エンジン（ai-researcher主導）**
   ```rust
   // evaluator.rs - 基本評価器
   pub fn eval(expr: &Expr, env: &mut Environment) -> Result<Value, Error> {
       // 実装
   }
   ```

3. **システム基盤（os-researcher主導）**
   ```rust
   // environment.rs - 実行環境
   pub struct Environment {
       bindings: HashMap<String, Value>,
   }
   ```

#### 統合ポイント
- **毎日17:00**: 各実装の統合テスト
- **API設計会議**: 週3回（月水金）
- **ペアレビュー**: 毎日ローテーション

### Phase 2: 機能拡張（Week 3-4）

#### 協力が必要な機能
1. **型システム統合**
   - lang-researcher: 型定義
   - ai-researcher: 型推論
   - os-researcher: メモリ管理

2. **AI統合システム**
   - ai-researcher: AI API設計
   - lang-researcher: 構文統合
   - os-researcher: 実行環境

3. **テストスイート**
   - 全員: 担当機能のテスト作成
   - boss: 統合テスト管理
   - PRESIDENT: 受け入れテスト

## 📋 作業管理システム

### タスク管理
```markdown
## 実装タスクボード

### To Do
- [ ] lexer.rs 基本実装 (lang-researcher)
- [ ] parser.rs S式解析 (lang-researcher)  
- [ ] evaluator.rs 数値演算 (ai-researcher)

### In Progress  
- [x] environment.rs 変数管理 (os-researcher)
- [x] error.rs エラー型定義 (boss)

### Done
- [x] プロジェクト初期化 (全員)
- [x] 開発環境構築 (全員)
```

### コード管理
```bash
# ブランチ戦略
main                    # 安定版
├── develop            # 統合開発
├── feature/lexer      # 字句解析器
├── feature/parser     # 構文解析器
└── feature/evaluator  # 評価器
```

### レビュープロセス
1. **実装完了** → Pull Request作成
2. **2名以上レビュー** → 承認必要
3. **統合テスト通過** → マージ承認
4. **boss最終確認** → main統合

## 🤝 協力ガイドライン

### コミュニケーション
- **質問**: すぐに agent-send.sh で共有
- **発見**: 新しい知見は即座に文書化
- **課題**: 困った時は遠慮なく助けを求める

### ペアプログラミング
```bash
# 例: 言語×AI 協力
lang-researcher: パーサー構造設計
ai-researcher: AI統合ポイント特定

# 例: AI×OS 協力  
ai-researcher: メモリ要件定義
os-researcher: 効率的実装方法

# 例: OS×言語 協力
os-researcher: システム制約説明
lang-researcher: 言語機能調整
```

### 知識共有
- **技術セッション**: 週1回、知見共有
- **ドキュメント**: 実装判断の記録
- **サンプルコード**: 動作例の蓄積

## 🎯 協力成果目標

### Week 1 目標
- [ ] 全員が同一環境で開発可能
- [ ] 基本的なS式パース動作
- [ ] チーム作業プロセス確立

### Week 2 目標  
- [ ] 変数・関数の基本動作
- [ ] 統合テスト自動化
- [ ] コードレビュー体制

### Week 4 目標
- [ ] 実用的なプログラム実行可能
- [ ] 包括的テストカバレッジ
- [ ] 次フェーズ準備完了

## 📞 サポート体制

### 困った時の連絡先
```bash
# 技術的質問
./agent-send.sh [専門家] "質問内容"

# 全体的な課題
./agent-send.sh boss "協力要請: [詳細]"

# 重要な決定事項
./agent-send.sh president "承認要請: [内容]"
```

### 学習支援
- Rust初心者サポート
- nom パーサー学習会
- Git/GitHub 作業支援

---

**全員で協力して、実装可能な Cognos を作り上げましょう！**