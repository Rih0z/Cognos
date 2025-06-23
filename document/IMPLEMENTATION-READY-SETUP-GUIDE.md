# Cognos実装準備完了ガイド

## 🎯 目的
全チームメンバーが即座に実装を開始できる状態を構築

## 🚀 即座に開始可能なセットアップ

### 1. 開発環境セットアップ（30分）

#### 必要なツール
```bash
# Rust開発環境
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 開発ツール
cargo install cargo-watch cargo-tarpaulin rustfmt clippy

# プロジェクト作成
cargo new cognos-lang --bin
cd cognos-lang
```

#### Cargo.toml設定
```toml
[package]
name = "cognos-lang"
version = "0.1.0"
edition = "2021"

[dependencies]
nom = "7.1"
thiserror = "1.0"
clap = { version = "4.0", features = ["derive"] }
rustyline = "12.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

[dev-dependencies]
criterion = "0.5"
```

### 2. 基本ファイル構造
```
cognos-lang/
├── src/
│   ├── main.rs           # エントリーポイント
│   ├── lexer.rs          # 字句解析器
│   ├── parser.rs         # 構文解析器
│   ├── ast.rs            # 抽象構文木
│   ├── evaluator.rs      # 評価器
│   ├── environment.rs    # 環境・変数管理
│   ├── types.rs          # 型システム
│   ├── error.rs          # エラーハンドリング
│   └── repl.rs           # REPL実装
├── tests/                # 統合テスト
├── examples/             # サンプルコード
└── docs/                 # ドキュメント
```

### 3. 動作するスターターコード

#### src/main.rs
```rust
use clap::Parser;
use std::fs;

mod lexer;
mod parser;
mod ast;
mod evaluator;
mod environment;
mod error;
mod repl;

use crate::evaluator::eval;
use crate::environment::Environment;
use crate::parser::parse_program;
use crate::repl::start_repl;

#[derive(Parser)]
#[command(name = "cognos")]
#[command(about = "Cognos Programming Language")]
struct Cli {
    /// File to execute
    file: Option<String>,
    
    /// Start REPL
    #[arg(short, long)]
    repl: bool,
}

fn main() {
    let cli = Cli::parse();
    
    if cli.repl || cli.file.is_none() {
        println!("Cognos REPL v0.1.0");
        start_repl();
    } else if let Some(file) = cli.file {
        run_file(&file);
    }
}

fn run_file(filename: &str) {
    match fs::read_to_string(filename) {
        Ok(content) => {
            let mut env = Environment::new();
            match parse_program(&content) {
                Ok(program) => {
                    for expr in program {
                        match eval(&expr, &mut env) {
                            Ok(value) => println!("{}", value),
                            Err(e) => eprintln!("Error: {}", e),
                        }
                    }
                }
                Err(e) => eprintln!("Parse error: {}", e),
            }
        }
        Err(e) => eprintln!("File error: {}", e),
    }
}
```

## 📋 チーム作業分担

### Phase 1: 基礎実装（1-2週間）

#### 言語チーム
- [ ] **lexer.rs** - トークナイザー実装
- [ ] **parser.rs** - S式パーサー実装  
- [ ] **ast.rs** - 抽象構文木定義
- [ ] **基本テスト** - パース動作確認

#### 評価チーム
- [ ] **evaluator.rs** - 基本評価器実装
- [ ] **environment.rs** - 変数環境管理
- [ ] **types.rs** - 基本型システム
- [ ] **統合テスト** - 評価動作確認

#### インターフェースチーム
- [ ] **repl.rs** - 対話的実行環境
- [ ] **error.rs** - エラーハンドリング
- [ ] **examples/** - サンプルコード作成
- [ ] **ドキュメント** - 使用方法説明

### Phase 2: 拡張実装（3-4週間）

#### 型システムチーム
- [ ] 型チェッカー実装
- [ ] 型推論基礎
- [ ] 制約システム統合

#### 標準ライブラリチーム
- [ ] 基本関数実装
- [ ] I/O操作
- [ ] 文字列処理

#### AI統合チーム
- [ ] テンプレートシステム
- [ ] 外部AI API連携
- [ ] 安全性検証

## 🔨 実装開始手順

### Step 1: プロジェクト作成（今すぐ）
```bash
git clone https://github.com/Rih0z/Cognos.git
cd Cognos
cargo new cognos-implementation --bin
cd cognos-implementation
```

### Step 2: 基本構造作成（今日中）
```bash
# ファイル構造作成
mkdir -p src tests examples docs
touch src/{lexer,parser,ast,evaluator,environment,types,error,repl}.rs
```

### Step 3: 最初の実装（明日から）
1. **lexer.rs** - 基本トークナイザー
2. **parser.rs** - S式パーサー
3. **evaluator.rs** - 数値演算評価器

### Step 4: 動作確認（3日後）
```bash
cargo run
# > Cognos REPL v0.1.0
# > (+ 1 2 3)
# 6
```

## 📚 実装ガイドライン

### コード品質基準
- すべてのpublic関数にドキュメント
- `cargo test`でテスト実行
- `cargo clippy`でlint実行
- `cargo fmt`でフォーマット

### Git運用ルール
```bash
# ブランチ作成
git checkout -b feature/lexer-implementation

# 実装・テスト・コミット
git add src/lexer.rs tests/lexer_test.rs
git commit -m "Implement basic lexer for S-expressions"

# レビュー・マージ
git push origin feature/lexer-implementation
```

### テスト駆動開発
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_number() {
        assert_eq!(parse("42"), Ok(Expr::Number(42)));
    }
}
```

## 🎯 週次マイルストーン

### Week 1: 基礎実装
- [ ] 開発環境構築完了
- [ ] 基本パーサー動作
- [ ] 簡単な評価器動作
- [ ] REPL起動確認

### Week 2: 機能拡張
- [ ] 変数定義・参照
- [ ] 関数定義・呼び出し
- [ ] 基本的な制御構文
- [ ] エラーハンドリング

### Week 3: 統合テスト
- [ ] 包括的テストスイート
- [ ] パフォーマンス測定
- [ ] ドキュメント整備
- [ ] 使用例作成

### Week 4: 品質向上
- [ ] コードレビュー完了
- [ ] ベンチマーク実装
- [ ] CI/CD設定
- [ ] リリース準備

## 🚀 成功基準

### 技術的成功
- [ ] S式のパース・評価が動作
- [ ] REPL で対話的実行可能
- [ ] 基本的な演算・変数・関数が動作
- [ ] テストカバレッジ80%以上

### チーム協力成功
- [ ] 全メンバーが実装に参加
- [ ] 毎日の進捗共有
- [ ] コードレビューの実施
- [ ] 知識共有・ペアプログラミング

## 📞 サポート体制

### 日次ミーティング
- 時間: 毎日17:00-17:30
- 内容: 進捗報告・課題共有・翌日計画

### 実装サポート
- Slack/Discord での質問受付
- ペアプログラミングセッション
- コードレビュー体制

### 学習リソース
- Rust公式ドキュメント
- nom パーサーコンビネータ
- 実装例・参考コード

---

**今すぐ実装を開始できます！まずはcargo newから始めましょう。**