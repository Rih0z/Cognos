# 言語優先実装指令書

## 🎯 正式決定事項

技術的分析に基づき、Cognosプロジェクトは**言語優先開発アプローチ**を採用する。

## 📋 実装優先順位

### 第1優先: Cognos言語仕様と実装（1-2ヶ月）

#### Week 1-2: 言語仕様確定
```
必須成果物:
□ BNF文法定義（完全版）
□ 型システム仕様書
□ 標準ライブラリAPI
□ エラーハンドリング仕様
```

#### Week 3-4: パーサー実装
```rust
// 実装開始コード例
pub mod cognos_parser {
    use nom::{
        IResult,
        branch::alt,
        bytes::complete::tag,
        // ... 詳細実装
    };
    
    pub fn parse_program(input: &str) -> IResult<&str, Program> {
        // 1週目で動作する最小実装
    }
}
```

#### Week 5-8: 型システムと安全性保証
```
□ 型チェッカー実装
□ 構造的バグ防止機構
□ テンプレートシステム
□ 制約ソルバー統合
```

### 第2優先: AI統合層（並行開発可能）

#### 言語-AI インターフェース
```rust
// AI統合API例
pub trait AIIntegration {
    fn analyze_intent(&self, code: &str) -> IntentResult;
    fn suggest_completion(&self, context: &Context) -> Vec<Suggestion>;
    fn verify_safety(&self, ast: &AST) -> SafetyReport;
}
```

### 第3優先: OS基盤（言語API確定後）

#### 最小言語要件
```
- システムコール用FFI
- メモリ管理プリミティブ
- 並行性サポート
- ハードウェア抽象層
```

## 🚀 1週間実装計画

### Day 1-2: 開発環境構築
```bash
# セットアップスクリプト
cargo new cognos-lang
cd cognos-lang
cargo add nom thiserror clap

# ディレクトリ構造
mkdir -p src/{parser,ast,types,codegen}
```

### Day 3-4: 最小パーサー
```rust
// src/parser/mod.rs
#[derive(Debug, Clone)]
pub enum Expr {
    Number(i64),
    Symbol(String),
    List(Vec<Expr>),
}

pub fn parse_minimal(input: &str) -> Result<Expr, ParseError> {
    // S式パーサーの最小実装
}
```

### Day 5-6: 基本評価器
```rust
// src/evaluator/mod.rs
pub fn eval(expr: &Expr, env: &mut Environment) -> Result<Value, EvalError> {
    match expr {
        Expr::Number(n) => Ok(Value::Number(*n)),
        Expr::Symbol(s) => env.lookup(s),
        Expr::List(items) => eval_application(items, env),
    }
}
```

### Day 7: 統合テスト
```rust
#[test]
fn test_basic_evaluation() {
    let program = "(+ 1 2 3)";
    let result = run_program(program);
    assert_eq!(result, Ok(Value::Number(6)));
}
```

## 📊 成功基準

### 1週間後
- [ ] 基本的なS式が評価可能
- [ ] 簡単な型チェック動作
- [ ] 10個以上のテストケース合格

### 1ヶ月後
- [ ] 完全な言語仕様実装
- [ ] 型システムによる安全性保証
- [ ] AI統合プロトタイプ

### 2ヶ月後
- [ ] セルフホスティング可能
- [ ] OS開発開始可能
- [ ] ドキュメント完備

## ⚡ 必須ドキュメント（48時間以内）

### 言語仕様書の構成
```
1. 構文仕様（BNF）
2. 意味論定義
3. 型システム詳細
4. 標準ライブラリ
5. FFI仕様
6. エラーハンドリング
7. 実装ガイド
8. テスト戦略
```

### コード例の要件
- **動作確認済み**: cargo testで検証
- **段階的**: 簡単→複雑
- **完全**: importから実行まで
- **説明付き**: 各行にコメント

## 🔥 実装開始チェックリスト

### 言語チーム
- [ ] parser/lexer.rs（500行）
- [ ] ast/nodes.rs（300行）
- [ ] types/checker.rs（800行）
- [ ] 実行可能なサンプル10個

### AIチーム
- [ ] 統合API仕様
- [ ] プロトタイプ実装
- [ ] 性能ベンチマーク

### OSチーム
- [ ] 必要言語機能リスト
- [ ] FFI設計
- [ ] 統合テスト計画

## 📅 タイムライン

```
Week 1: 最小実装
Week 2: 言語仕様完成
Week 3-4: パーサー/評価器
Week 5-6: 型システム
Week 7-8: AI統合
Week 9-12: OS並行開発
```

## ⚠️ 重要指示

**これは議論ではなく実装指令である。**

- コードで示せ
- 動作するものを作れ
- 48時間で仕様確定
- 1週間で最初の動作

実装なき設計は無価値。今すぐ開始せよ。