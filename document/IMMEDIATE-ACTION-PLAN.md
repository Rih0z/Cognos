# 実装即座開始アクションプラン

## 🚀 今すぐ実行できるアクション

### 即座実行（次の30分）

#### 1. 開発環境確認
```bash
# 各自で実行して確認
rustc --version   # 1.70+ 必要
cargo --version   # 動作確認
git --version     # 動作確認
```

#### 2. プロジェクト作成
```bash
# プロジェクトルートで実行
cargo new cognos-implementation --bin
cd cognos-implementation
```

#### 3. 基本設定
```bash
# ディレクトリ作成
mkdir -p src tests examples docs

# 基本ファイル作成
touch src/{lexer,parser,ast,evaluator,environment,error,repl}.rs
```

### 今日中に完了（次の3時間）

#### Cargo.toml 設定
```toml
[package]
name = "cognos-implementation"
version = "0.1.0"
edition = "2021"

[dependencies]
nom = "7.1"
thiserror = "1.0"
clap = { version = "4.0", features = ["derive"] }
rustyline = "12.0"

[dev-dependencies]
criterion = "0.5"
```

#### 最初の動作確認
```rust
// src/main.rs
fn main() {
    println!("Cognos Implementation v0.1.0");
    println!("Setup complete!");
}
```

```bash
cargo run
# 出力: Cognos Implementation v0.1.0
#       Setup complete!
```

## 📋 チーム分担作業（明日から開始）

### lang-researcher（言語専門家）
#### Day 1 タスク
```rust
// src/lexer.rs の実装開始
#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    LeftParen,
    RightParen,
    Symbol(String),
    Number(i64),
    Whitespace,
    Comment,
}

pub fn tokenize(input: &str) -> Vec<Token> {
    // 実装開始
}
```

### ai-researcher（AI専門家）
#### Day 1 タスク
```rust
// src/evaluator.rs の準備
#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Number(i64),
    Symbol(String),
    List(Vec<Value>),
    Function(/* 関数定義 */),
}

pub fn eval(expr: &Expr, env: &Environment) -> Result<Value, EvalError> {
    // 実装準備
}
```

### os-researcher（システム専門家）
#### Day 1 タスク
```rust
// src/environment.rs の実装開始
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Environment {
    bindings: HashMap<String, Value>,
    parent: Option<Box<Environment>>,
}

impl Environment {
    pub fn new() -> Self {
        // 実装開始
    }
}
```

## 🎯 1週間の具体的目標

### Day 1: 基盤構築
- [ ] 全員の開発環境構築完了
- [ ] プロジェクト初期化完了
- [ ] 基本ファイル構造作成
- [ ] Hello World 動作確認

### Day 2-3: 字句解析
- [ ] Token 型定義完了
- [ ] 基本トークナイザー実装
- [ ] 数値・記号の認識
- [ ] トークンテスト作成

### Day 4-5: 構文解析
- [ ] AST 型定義完了
- [ ] S式パーサー実装
- [ ] パースエラーハンドリング
- [ ] パーサーテスト作成

### Day 6-7: 基本評価
- [ ] 基本演算実装
- [ ] 変数束縛実装
- [ ] REPL 基本動作
- [ ] 統合テスト

## 📞 協力体制

### 日次ミーティング
#### 朝のスタンドアップ（09:00-09:30）
```bash
# 各自が agent-send.sh で報告
./agent-send.sh boss "
進捗: [昨日の実装内容]
今日: [今日の予定]
課題: [支援が必要な内容]
"
```

#### 夕方の振り返り（17:00-17:30）
```bash
# 実装結果の共有
./agent-send.sh boss "
完了: [実装できた機能]
テスト: [動作確認結果]  
明日: [翌日の予定]
"
```

### ペアプログラミング
#### 推奨ペア構成
- **月水金**: lang + ai （パーサー＋評価器連携）
- **火木**: ai + os （評価器＋環境管理連携）
- **適宜**: 困ったときの相互支援

### コードレビュー
```bash
# ブランチ作成
git checkout -b feature/lexer-implementation

# 実装・テスト
# ...

# Pull Request 作成
git push origin feature/lexer-implementation
# GitHub でPR作成、2名以上のレビュー
```

## 🔨 実装支援ツール

### 開発効率化
```bash
# ウォッチモード（コード変更で自動テスト）
cargo install cargo-watch
cargo watch -x test

# コード品質チェック
cargo clippy
cargo fmt

# テストカバレッジ
cargo install cargo-tarpaulin
cargo tarpaulin
```

### デバッグ支援
```rust
// デバッグ出力の活用
#[derive(Debug)]
pub struct MyStruct { /* ... */ }

// テスト駆動開発
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_tokenize_number() {
        assert_eq!(tokenize("42"), vec![Token::Number(42)]);
    }
}
```

## 📊 成功基準

### Week 1 終了時の目標
```bash
# これが動作すること
cargo run
> Cognos REPL v0.1.0
> (+ 1 2 3)
6
> (let x 10)
10
> x
10
```

### 品質基準
- [ ] `cargo test` 全テスト通過
- [ ] `cargo clippy` 警告ゼロ
- [ ] テストカバレッジ 70% 以上
- [ ] 全機能の動作確認完了

## 🚨 緊急時の対応

### 技術的問題
```bash
# 即座にチーム共有
./agent-send.sh boss "緊急: [問題内容] 支援求む"
```

### 作業遅延
- 遠慮なく支援要請
- ペアプログラミング活用
- タスク再分担検討

---

**実装準備完了！今すぐ開始しましょう！**

まずは `cargo new cognos-implementation --bin` から始めてください。