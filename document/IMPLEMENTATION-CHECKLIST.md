# Cognos実装チェックリスト

## 🎯 実装可能状態への完全チェックリスト

### ✅ 即座に実行可能な項目

#### 環境準備（30分で完了）
- [ ] Rust 1.70+ インストール確認
- [ ] cargo, rustc 動作確認
- [ ] Git 設定完了
- [ ] エディタ/IDE 準備（VS Code + Rust Analyzer推奨）

#### プロジェクト初期化（15分で完了）
```bash
# 実行コマンド
cargo new cognos-implementation --bin
cd cognos-implementation
```

#### 依存関係設定（10分で完了）
```toml
# Cargo.toml に追加
[dependencies]
nom = "7.1"
thiserror = "1.0" 
clap = { version = "4.0", features = ["derive"] }
rustyline = "12.0"
```

#### ファイル構造作成（5分で完了）
```bash
mkdir -p src/{parser,evaluator,types} tests examples
touch src/{lexer,parser,ast,evaluator,environment,error,repl}.rs
```

### 📋 Week 1 実装チェックリスト

#### Day 1: プロジェクト基盤
- [ ] 開発環境構築完了
- [ ]基本ファイル構造作成
- [ ] Hello World 動作確認
- [ ] Git リポジトリ初期化

#### Day 2-3: 字句解析器
- [ ] Token 型定義
- [ ] 基本トークナイザー実装
- [ ] 数値・記号の認識
- [ ] 単体テスト作成

```rust
// 実装目標例
#[derive(Debug, PartialEq)]
pub enum Token {
    LeftParen,
    RightParen, 
    Symbol(String),
    Number(i64),
}
```

#### Day 4-5: 構文解析器
- [ ] AST 型定義
- [ ] S式パーサー実装
- [ ] パースエラーハンドリング
- [ ] パーサーテスト

```rust
// 実装目標例
#[derive(Debug, PartialEq)]
pub enum Expr {
    Number(i64),
    Symbol(String),
    List(Vec<Expr>),
}
```

#### Day 6-7: 基本評価器
- [ ] Environment 実装
- [ ] 基本演算評価
- [ ] 変数束縛
- [ ] REPL 基本動作

```rust
// 実装目標例
pub fn eval(expr: &Expr, env: &mut Environment) -> Result<Value, EvalError> {
    match expr {
        Expr::Number(n) => Ok(Value::Number(*n)),
        Expr::Symbol(s) => env.lookup(s),
        Expr::List(items) => eval_application(items, env),
    }
}
```

### 📋 Week 2 機能拡張チェックリスト

#### 関数システム
- [ ] 関数定義構文 `(fn name (args) body)`
- [ ] 関数呼び出し
- [ ] 引数バインディング
- [ ] 再帰関数サポート

#### 制御構文
- [ ] 条件分岐 `(if cond then else)`
- [ ] 繰り返し `(while cond body)`
- [ ] パターンマッチ基礎
- [ ] エラーハンドリング

#### 型システム基礎
- [ ] 基本型定義（Number, String, Bool）
- [ ] 型チェック基礎
- [ ] 型エラー報告
- [ ] 型推論準備

### 📋 品質保証チェックリスト

#### テスト体制
- [ ] 単体テスト 80% カバレッジ
- [ ] 統合テスト実装
- [ ] エラーケーステスト
- [ ] パフォーマンステスト基礎

#### コード品質
- [ ] `cargo clippy` 警告ゼロ
- [ ] `cargo fmt` 適用済み
- [ ] ドキュメンテーション充実
- [ ] コードレビュー完了

#### 動作確認
- [ ] REPL で基本演算動作
- [ ] ファイル実行動作
- [ ] エラーメッセージ表示
- [ ] 使用例動作確認

### 🎯 協力体制チェックリスト

#### チーム連携
- [ ] 日次進捗報告体制
- [ ] agent-send.sh 活用
- [ ] ペアプログラミング実施
- [ ] 知識共有セッション

#### 作業分担
- [ ] lang-researcher: パーサー担当
- [ ] ai-researcher: 評価器担当  
- [ ] os-researcher: 環境・基盤担当
- [ ] boss: 統合・調整担当

#### プロセス管理
- [ ] Git ブランチ戦略実施
- [ ] Pull Request レビュー
- [ ] 継続的統合設定
- [ ] 定期ミーティング実施

### 🚀 成功基準（Week 1 終了時）

#### 技術的成功
```bash
# これらが動作すること
cargo run
> Cognos REPL v0.1.0
> (+ 1 2 3)
6
> (let x 10)
10
> (* x 2)
20
```

#### 協力体制成功
- [ ] 全メンバーが実装に参加
- [ ] 毎日の進捗共有実施
- [ ] 課題の即座共有・解決
- [ ] 知識とコードの共有

### 📊 進捗追跡

#### 毎日確認項目
```markdown
## [日付] 進捗チェック

### 技術的進捗
- [ ] 今日のタスク完了
- [ ] テスト追加・更新
- [ ] ドキュメント更新

### チーム連携
- [ ] 進捗報告実施
- [ ] 課題共有・解決
- [ ] 翌日計画確認

### 品質確認
- [ ] コード品質チェック
- [ ] 動作確認テスト
- [ ] レビューフィードバック対応
```

### 🎓 学習サポート

#### Rust 学習項目
- [ ] 基本文法理解
- [ ] 所有権システム理解
- [ ] エラーハンドリング
- [ ] テスト記述方法

#### 実装技術学習
- [ ] nom パーサーコンビネータ
- [ ] AST 設計パターン
- [ ] インタープリター実装
- [ ] REPL 実装技術

### 🔧 トラブルシューティング

#### よくある課題と解決
1. **コンパイルエラー**
   - `cargo check` で詳細確認
   - エラーメッセージ読解
   - チームで課題共有

2. **テスト失敗** 
   - `cargo test -- --nocapture` で詳細確認
   - 期待値と実際値の比較
   - テストケース見直し

3. **Git 競合**
   - 早期の頻繁コミット
   - ブランチ戦略遵守
   - チーム調整

---

**このチェックリストを使って、確実に実装可能な状態を達成しましょう！**