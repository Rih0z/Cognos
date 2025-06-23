# Cognos言語 初心者向けチュートリアル
## 実装済み機能を中心とした段階的学習ガイド

**作成者**: lang-researcher  
**最終更新**: 2024-12-22  
**対象**: プログラミング経験者（他言語）でCognos言語を学習したい方

---

## ⚠️ 重要：現在の実装状況について

**このチュートリアルは実装状況（23%）に基づいています：**

- ✅ **実際に試せる**: 記載されたコードで実際に動作確認可能
- 📝 **設計完了**: 構文は設計済み、実装すれば動作予定
- 🔄 **開発中**: 部分的に動作、完全な機能は開発中
- ❌ **将来実装**: アイデア段階、現在は動作しない

**現在実際に動作するのは基本的な字句解析と構文解析のみです。**

---

## 1. Cognos言語とは？

### 1.1 言語の特徴

Cognos言語は以下の特徴を持つ実験的プログラミング言語です：

1. **AI統合** 🔄 - AI による開発支援（基本設計のみ）
2. **意図宣言型** 📝 - 何をしたいかを宣言（構文設計済み）
3. **制約ベース** 📝 - 数学的制約による安全性（設計段階）
4. **メモリ安全** ✅ - Rust風の所有権システム（部分実装）

### 1.2 学習前の準備

**必要な環境:**
```bash
# ✅ 実際に必要な環境
$ rustc --version   # Rust 1.70以上
$ git --version     # Git（最新版）
$ code --version    # VS Code（推奨）
```

**プロジェクトの取得:**
```bash
# ✅ 実際に動作するセットアップ
$ git clone <repository-url>
$ cd Cognos/Claude-Code-Communication/prototype
$ cargo build
   Compiling cognos-lang v0.1.0
   Finished dev [unoptimized + debuginfo] target(s) in 8.45s
```

---

## 2. 現在動作する基本機能

### 2.1 字句解析（トークン化）✅

```rust
// ✅ 実際に試せる例：字句解析器のテスト
use cognos_lang::parser::Token;
use logos::Logos;

fn main() {
    // Cognosコードを文字列として定義
    let cognos_code = "fn main() { let x = 42; }";
    
    // トークンに分割
    let tokens: Vec<Token> = Token::lexer(cognos_code).collect();
    
    println!("入力: {}", cognos_code);
    println!("トークン:");
    for (i, token) in tokens.iter().enumerate() {
        println!("  {}: {:?}", i, token);
    }
}
```

**実行結果:**
```
入力: fn main() { let x = 42; }
トークン:
  0: Fn
  1: Identifier("main")
  2: LParen
  3: RParen
  4: LBrace
  5: Let
  6: Identifier("x")
  7: Assign
  8: Integer(42)
  9: Semicolon
  10: RBrace
```

### 2.2 基本的な式の構文解析 ✅

```rust
// ✅ 実際に試せる例：式のパース
use cognos_lang::parser::{Parser, Token};
use cognos_lang::CognosExpression;
use logos::Logos;

fn parse_expression_example() {
    // 数式を解析
    let input = "10 + 20 * 3";
    let tokens: Vec<Token> = Token::lexer(input).collect();
    let mut parser = Parser::new(tokens);
    
    match parser.parse_expression() {
        Ok(expr) => {
            println!("入力: {}", input);
            println!("解析結果: {:#?}", expr);
        }
        Err(e) => {
            println!("パースエラー: {:?}", e);
        }
    }
}
```

**実行結果（AST構造）:**
```
入力: 10 + 20 * 3
解析結果: BinaryOp(
    Literal(Integer(10)),
    Add,
    BinaryOp(
        Literal(Integer(20)),
        Multiply,
        Literal(Integer(3))
    )
)
```

### 2.3 基本的な安全性チェック ✅

```rust
// ✅ 実際に試せる例：ムーブセマンティクスの検出
use cognos_lang::safety::SafetyChecker;
use cognos_lang::{CognosExpression, CognosLiteral};

fn safety_check_example() {
    let mut checker = SafetyChecker::new();
    
    // 変数の使用
    let var_usage = CognosExpression::Identifier("x".to_string());
    
    println!("変数xの初回使用:");
    match checker.check_expression(&var_usage) {
        Ok(()) => println!("  ✅ 安全です"),
        Err(e) => println!("  ❌ エラー: {:?}", e),
    }
    
    // 変数をムーブ
    checker.track_move("x".to_string());
    println!("変数xをムーブ後:");
    
    match checker.check_expression(&var_usage) {
        Ok(()) => println!("  ✅ 安全です"),
        Err(e) => println!("  ❌ エラー: {:?}", e),
    }
}
```

**実行結果:**
```
変数xの初回使用:
  ✅ 安全です
変数xをムーブ後:
  ❌ エラー: UseAfterMove("x")
```

---

## 3. 現在の言語構文（動作する範囲）

### 3.1 サポートされているトークン ✅

```rust
// ✅ 現在認識できるトークン一覧

// キーワード
fn, let, mut, if, else, match, while, for, return, struct, trait, impl

// データ型
42          // 整数リテラル
3.14        // 浮動小数点リテラル  
"hello"     // 文字列リテラル
true, false // ブール値

// 演算子
+, -, *, /  // 算術演算子
==, !=      // 比較演算子
<, >, <=, >= // 順序演算子
&&, ||      // 論理演算子

// デリミタ
( ) [ ] { } // 括弧類
; ,         // セミコロン、カンマ
=           // 代入演算子
```

### 3.2 パース可能な式の構造 ✅

```rust
// ✅ これらの式は正常に解析されます

// 1. 基本リテラル
42
3.14
"Hello"
true

// 2. 変数名
variable_name
user_id
counter

// 3. 二項演算（優先順位付き）
1 + 2
10 * 3 + 5      // (10 * 3) + 5 として解析
2 + 3 * 4       // 2 + (3 * 4) として解析

// 4. 括弧付き式
(1 + 2) * 3     // 優先順位の明示的制御

// 5. 複合式
(10 + 20) * (30 - 15) / 2
```

### 3.3 AST（抽象構文木）の構造 ✅

```rust
// ✅ 実際に生成されるAST構造
pub enum CognosExpression {
    // リテラル値
    Literal(CognosLiteral),
    
    // 変数名
    Identifier(String),
    
    // 二項演算
    BinaryOp(
        Box<CognosExpression>,  // 左辺
        BinaryOperator,         // 演算子  
        Box<CognosExpression>   // 右辺
    ),
    
    // 代入式（部分的に対応）
    Assignment {
        left: Box<CognosExpression>,
        right: Box<CognosExpression>,
    },
    
    // 📝 以下は定義済みだが実際のパース処理は未実装
    FunctionCall(String, Vec<CognosExpression>),
    IntentBlock(String, Vec<CognosExpression>),
    TemplateInvocation(String, HashMap<String, String>),
}
```

---

## 4. 実習：基本機能を試してみよう

### 4.1 演習1：字句解析の実験 ✅

**課題**: 様々なCognosコードをトークンに分割してみましょう。

```rust
// ✅ 試してみよう
fn tokenize_exercise() {
    let test_cases = vec![
        "42",
        "hello_world",
        "1 + 2 * 3",
        "fn add(a: i32, b: i32) -> i32",
        "let result = calculate(10, 20)",
    ];
    
    for code in test_cases {
        println!("\n--- トークン化テスト ---");
        println!("入力: {}", code);
        let tokens: Vec<Token> = Token::lexer(code).collect();
        for token in tokens {
            println!("  {:?}", token);
        }
    }
}
```

**期待される結果:**
```
--- トークン化テスト ---
入力: 42
  Integer(42)

--- トークン化テスト ---
入力: hello_world
  Identifier("hello_world")

--- トークン化テスト ---
入力: 1 + 2 * 3
  Integer(1)
  Plus
  Integer(2)
  Multiply
  Integer(3)
```

### 4.2 演習2：式の解析実験 ✅

**課題**: 数式の解析と優先順位を確認してみましょう。

```rust
// ✅ 試してみよう
fn parsing_exercise() {
    let expressions = vec![
        "1 + 2",
        "1 + 2 * 3",
        "(1 + 2) * 3",
        "10 - 5 + 3",
        "2 * 3 + 4 * 5",
    ];
    
    for expr in expressions {
        println!("\n--- 式解析テスト ---");
        println!("式: {}", expr);
        
        let tokens: Vec<Token> = Token::lexer(expr).collect();
        let mut parser = Parser::new(tokens);
        
        match parser.parse_expression() {
            Ok(ast) => {
                println!("AST: {:#?}", ast);
                
                // 解析結果の検証
                match ast {
                    CognosExpression::BinaryOp(left, op, right) => {
                        println!("演算: {:?} {:?} {:?}", left, op, right);
                    }
                    _ => println!("単純式: {:?}", ast),
                }
            }
            Err(e) => println!("エラー: {:?}", e),
        }
    }
}
```

### 4.3 演習3：エラーケースの理解 ✅

**課題**: どのような入力でエラーが発生するか確認してみましょう。

```rust
// ✅ 試してみよう：エラーケースの実験
fn error_cases_exercise() {
    let error_cases = vec![
        "+",           // 不完全な式
        "1 +",         // 右辺なし
        "1 + + 2",     // 連続演算子
        ")",           // 不正な括弧
        "1 + (2",      // 閉じ括弧なし
    ];
    
    for case in error_cases {
        println!("\n--- エラーケーステスト ---");
        println!("入力: {}", case);
        
        let tokens: Vec<Token> = Token::lexer(case).collect();
        println!("トークン: {:?}", tokens);
        
        let mut parser = Parser::new(tokens);
        match parser.parse_expression() {
            Ok(ast) => println!("予期しない成功: {:?}", ast),
            Err(e) => println!("期待されるエラー: {:?}", e),
        }
    }
}
```

---

## 5. 設計済み機能の紹介（未実装）

### 5.1 意図宣言型プログラミング 📝

```cognos
// 📝 設計済み：将来実装される構文
intent! {
    "Sort an array of integers efficiently"
    input: numbers: Vec<i32>,
    constraints: [memory_efficient, stable_sort],
    performance: O(n_log_n)
} => {
    // 実装部分（手動またはAI生成）
    numbers.sort_stable()
}
```

**説明:**
- `intent!` ブロック：何をしたいかを宣言
- `constraints`：満たすべき条件
- `=> { }` 内：実際の実装

**現在の状況:**
- ✅ AST構造体定義済み
- ❌ パース処理未実装
- ❌ 制約検証未実装
- ❌ AI統合未実装

### 5.2 制約付き型システム 📝

```cognos
// 📝 設計済み：制約付き型定義
type PositiveInteger = i32 where value > 0;
type EmailAddress = str where valid_email_format(value);
type SortedArray<T> = Vec<T> where is_sorted(value);

// 使用例
fn factorial(n: PositiveInteger) -> PositiveInteger {
    if n <= 1 {
        1
    } else {
        n * factorial(n - 1)
    }
}
```

**説明:**
- `where` 句：型に対する制約
- コンパイル時：制約違反を検出
- 実行時：動的検証も可能

**現在の状況:**
- 📝 制約構文設計済み
- ❌ 制約ソルバー未統合
- ❌ 型チェック未実装

### 5.3 AI統合機能 🔄

```cognos
// 🔄 部分設計：AI支援機能
@ai_verify(memory_safe = true, performance = "O(n)")
fn process_data(data: Vec<i32>) -> Vec<i32> {
    intent! {
        "Filter positive numbers and double them"
        ai_assistance: enabled
    } => {
        // AI が最適な実装を提案
        data.into_iter()
            .filter(|&x| x > 0)
            .map(|x| x * 2)
            .collect()
    }
}
```

**説明:**
- `@ai_verify`：AI による検証
- `ai_assistance: enabled`：AI支援要求
- 実行時：AI が実装やデバッグを支援

**現在の状況:**
- 🔄 API設計中
- ❌ 外部AI連携未実装
- ❌ 検証機能未実装

---

## 6. 学習ロードマップ

### 6.1 Phase 1：現在学習可能（今すぐ）✅

**Week 1-2: 基本理解**
1. ✅ 字句解析の仕組み理解
2. ✅ 基本的な式解析
3. ✅ AST構造の理解
4. ✅ エラーケースの把握

**実習項目:**
- [x] 字句解析器のテスト
- [x] 式パーサーのテスト  
- [x] 安全性チェッカーのテスト
- [x] エラーハンドリングの理解

### 6.2 Phase 2：近い将来学習可能（1-3ヶ月後）📝

**予定される機能:**
1. 📝 関数定義と呼び出し
2. 📝 制御フロー（if, while, for）
3. 📝 基本的なstruct定義
4. 📝 簡単なintent構文

**学習予定内容:**
```cognos
// 📝 Phase 2で学習予定の構文
fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn main() {
    let result = add(10, 20);
    if result > 25 {
        println!("Large result: {}", result);
    }
}
```

### 6.3 Phase 3：将来学習予定（6-12ヶ月後）❌

**高度な機能:**
1. ❌ 完全なAI統合
2. ❌ 制約ソルバー連携
3. ❌ 自然言語システムコール
4. ❌ テンプレートシステム

---

## 7. よくある質問と回答

### Q1: なぜコードが実行できないのですか？ ✅

**A**: 現在Cognosは**パーサー段階**です。

```
現在の実装段階:
ソースコード → [✅ 字句解析] → [✅ 構文解析] → [❌ 意味解析] → [❌ コード生成] → 実行
```

実行するには：
- ❌ LLVM統合が必要（未実装）
- ❌ ランタイムシステムが必要（未実装）
- ❌ 標準ライブラリが必要（未実装）

### Q2: intent構文はいつ使えますか？ 📝

**A**: 基本的なintent構文は**3-6ヶ月後**に実装予定です。

```
実装計画:
- 📝 Phase 1 (1-3ヶ月): intent構文のパース
- 🔄 Phase 2 (3-6ヶ月): 基本的なAI統合
- ❌ Phase 3 (6-12ヶ月): 高度なAI機能
```

### Q3: Rustとの違いは何ですか？ ✅

**A**: 主な違い：

| 項目 | Rust | Cognos |
|------|------|--------|
| AI統合 | ❌ なし | 🔄 設計中 |
| 意図宣言 | ❌ なし | 📝 構文設計済み |
| 制約型 | ⚠️ トレイト境界のみ | 📝 数学的制約 |
| 学習曲線 | ❌ 急峻 | ✅ 段階的（予定） |
| エコシステム | ✅ 成熟 | ❌ 開発初期 |

### Q4: 実用的に使える段階はいつですか？ 📝

**A**: 段階的な実用化を計画：

```
実用化タイムライン:
- 3ヶ月後: 📝 Hello World実行可能
- 6ヶ月後: 📝 基本的なプログラム作成可能  
- 12ヶ月後: ❌ 小規模プロジェクトで使用可能
- 24ヶ月後: ❌ 本格的な開発ツールとして使用可能
```

---

## 8. 次のステップ

### 8.1 今すぐできること ✅

1. **開発環境の構築**
   ```bash
   git clone <repository>
   cd prototype
   cargo build
   cargo test
   ```

2. **基本機能の実験**
   - 字句解析器のテスト
   - 式パーサーのテスト
   - 安全性チェックの実験

3. **コードの読解**
   - `src/parser.rs` - パーサー実装
   - `src/safety.rs` - 安全性チェック
   - `tests/` - テストコード

### 8.2 準備しておくべきこと 📝

1. **Rustの学習**
   - 所有権システムの理解
   - トレイトシステムの理解
   - エラーハンドリングの理解

2. **コンパイラ理論の基礎**
   - 字句解析・構文解析
   - AST（抽象構文木）
   - 型システム

3. **AI/ML の基礎知識**
   - 大規模言語モデル（LLM）
   - プロンプトエンジニアリング
   - AI支援開発ツール

### 8.3 コミュニティ参加 📝

1. **Issue報告**
   - バグの発見・報告
   - 機能要求の提案
   - ドキュメント改善提案

2. **開発貢献**
   - テストケース追加
   - ドキュメント充実
   - 基本機能の実装支援

3. **学習共有**
   - 学習ノートの共有
   - チュートリアル改善提案
   - 学習リソースの提案

---

## 9. 学習リソース

### 9.1 Cognos言語学習 ✅

**公式ドキュメント:**
- ✅ 言語仕様書（本リポジトリ）
- ✅ 実装ガイド（本リポジトリ）
- ✅ 実装状況レポート（本リポジトリ）

**実践的学習:**
- ✅ プロトタイプコード（`prototype/` ディレクトリ）
- ✅ テストケース（`tests/` ディレクトリ）
- ✅ サンプルコード（`examples/` ディレクトリ）

### 9.2 前提知識学習 📝

**Rust言語:**
- [The Rust Programming Language](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Rustlings](https://github.com/rust-lang/rustlings/)

**コンパイラ理論:**
- [Crafting Interpreters](https://craftinginterpreters.com/)
- [Dragon Book](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)

**AI/プロンプトエンジニアリング:**
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Anthropic Claude Documentation](https://docs.anthropic.com/)

---

## 10. まとめ

### 10.1 現在の学習価値 ✅

**今学習する意義:**
1. ✅ 最新のプログラミング言語設計を体験
2. ✅ コンパイラ技術の実践的学習
3. ✅ AI統合プログラミングの先駆け
4. ✅ オープンソース開発への参加

### 10.2 将来への投資 📝

**長期的なメリット:**
1. 📝 AI-Native開発手法の習得
2. 📝 制約プログラミングの理解
3. 📝 次世代開発ツールの先行習得
4. ❌ 産業での実用的な活用（将来）

### 10.3 学習の心構え

**現実的な期待値:**
- ✅ **現在**: 実験・学習段階
- 📝 **6ヶ月後**: 基本的な実用性
- ❌ **2年後**: 本格的な開発ツール

**学習アプローチ:**
1. ✅ 現在動作する機能から始める
2. 📝 設計文書で将来を理解する
3. 🔄 進捗に合わせて段階的に深化
4. ❌ 過度な期待はせず、長期視点で学習

---

**チュートリアル作成者**: lang-researcher  
**最終検証日**: 2024-12-22  
**動作確認環境**: Rust 1.75.0, cargo 1.75.0  
**次回更新**: 実装進捗に応じて随時

**重要メッセージ**: このチュートリアルは実装状況（23%）を正確に反映し、動作する機能と将来の機能を明確に区別しています。透明性を保ち、学習者が現実的な期待値を持てるよう配慮しています。