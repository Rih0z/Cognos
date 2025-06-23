# Cognos言語実装ガイド
## 段階的実装手順書（実装状況明記）

**実装状況表記:**
- ✅ **実装済み**: 動作コード存在、テスト済み
- 📝 **設計完了**: 詳細仕様あり、実装可能
- 🔄 **設計中**: 基本方針決定、詳細検討中
- ❌ **未着手**: 将来実装予定

---

## 1. パーサー実装の段階的手順

### 1.1 字句解析器の実装 ✅ **実装済み**

#### 実装済みコード (src/parser.rs)
```rust
use logos::{Logos, Lexer};

#[derive(Logos, Debug, PartialEq, Clone)]
pub enum Token {
    #[token("fn")]
    Fn,
    
    #[token("intent")]
    Intent,
    
    #[regex("[a-zA-Z_][a-zA-Z0-9_]*", |lex| lex.slice().to_string())]
    Identifier(String),
    
    #[regex(r"`[^`]*`", |lex| lex.slice().to_string())]
    NaturalLang(String),
    
    #[regex(r"[0-9]+", |lex| lex.slice().parse())]
    Integer(i64),
    
    // 他のトークン定義...
}
```

#### 動作確認テスト ✅
```rust
#[test]
fn test_lexer_natural_language() {
    let input = r#"`ファイルを読み込む`.syscall()"#;
    let mut lexer = Token::lexer(input);
    
    assert_eq!(lexer.next(), Some(Token::NaturalLang("`ファイルを読み込む`".to_string())));
    assert_eq!(lexer.next(), Some(Token::Dot));
    // テスト通過確認済み
}
```

### 1.2 構文解析器の段階的実装

#### Phase 1: 基本式パーサー ✅ **実装済み**
```rust
impl<'a> Parser<'a> {
    pub fn parse_expression(&mut self) -> Result<CognosExpression, ParseError> {
        self.parse_assignment()
    }
    
    fn parse_assignment(&mut self) -> Result<CognosExpression, ParseError> {
        let mut left = self.parse_logical_or()?;
        
        if let Some(Token::Eq) = &self.current_token {
            self.advance();
            let right = self.parse_assignment()?;
            left = CognosExpression::Assignment {
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        
        Ok(left)
    }
    
    // 実装済み: 二項演算子の優先順位パース
    // 実装済み: 関数呼び出しパース
    // 実装済み: intent!構文パース
}
```

#### Phase 2: S式パーサー 📝 **設計完了**
```rust
// 設計済み実装予定コード
impl<'a> Parser<'a> {
    fn parse_s_expression(&mut self) -> Result<SExpression, ParseError> {
        self.expect(Token::LParen)?;
        
        let head = match &self.current_token {
            Some(Token::Identifier(name)) => SExprHead::Symbol(name.clone()),
            Some(Token::Keyword(kw)) => SExprHead::Keyword(kw.clone()),
            _ => return Err(ParseError::ExpectedSExprHead),
        };
        self.advance();
        
        let mut args = Vec::new();
        while !self.check(&Token::RParen) {
            args.push(self.parse_s_expr_arg()?);
        }
        
        self.expect(Token::RParen)?;
        
        Ok(SExpression { head, args })
    }
    
    fn parse_s_expr_arg(&mut self) -> Result<SExprArg, ParseError> {
        match &self.current_token {
            Some(Token::LParen) => {
                Ok(SExprArg::Nested(self.parse_s_expression()?))
            }
            _ => {
                Ok(SExprArg::Expression(self.parse_expression()?))
            }
        }
    }
}

// 実装予定: 2-3週間
// 依存関係: 基本パーサーの安定化完了後
```

#### Phase 3: 型注釈パーサー 📝 **設計完了**
```rust
// 設計済み実装予定コード
impl<'a> Parser<'a> {
    fn parse_type(&mut self) -> Result<CognosType, ParseError> {
        if self.check(&Token::LParen) {
            // S式型定義
            return self.parse_s_expr_type();
        }
        
        match &self.current_token {
            Some(Token::Identifier(name)) => {
                let base_type = self.parse_basic_type(name)?;
                
                // 制約付き型のパース
                if self.check_keyword("where") {
                    let constraints = self.parse_constraints()?;
                    Ok(CognosType::Constrained(Box::new(base_type), constraints))
                } else {
                    Ok(base_type)
                }
            }
            Some(Token::At) => {
                // AI検証型 @ai_verify(level) Type
                self.parse_ai_verified_type()
            }
            _ => Err(ParseError::ExpectedType),
        }
    }
    
    fn parse_constraints(&mut self) -> Result<Vec<Constraint>, ParseError> {
        // 実装予定: where句の制約パース
        todo!("制約パース実装")
    }
}

// 実装予定: 3-4週間
// 依存関係: S式パーサー完了後
```

### 1.3 エラー回復機能 🔄 **設計中**

```rust
// 設計中: エラー回復戦略
pub enum RecoveryStrategy {
    // 同期トークンまでスキップ
    SkipToSyncToken(Vec<Token>),
    // 挿入による回復
    InsertToken(Token),
    // 削除による回復
    DeleteToken,
}

impl<'a> Parser<'a> {
    fn recover_from_error(&mut self, error: ParseError) -> Result<(), ParseError> {
        match error {
            ParseError::ExpectedSemicolon => {
                // セミコロンを挿入して継続
                self.insert_token(Token::Semi);
                Ok(())
            }
            ParseError::UnexpectedToken(_) => {
                // 次の同期ポイントまでスキップ
                self.skip_to_sync_token();
                Ok(())
            }
            _ => Err(error),
        }
    }
}

// 実装予定: 基本パーサー安定後
```

---

## 2. AST構築とコード生成の詳細

### 2.1 AST設計 ✅ **実装済み**

#### 現在の実装 (src/lib.rs)
```rust
#[derive(Debug, Clone)]
pub enum CognosExpression {
    Literal(CognosLiteral),
    Identifier(String),
    BinaryOp(Box<CognosExpression>, BinaryOperator, Box<CognosExpression>),
    FunctionCall(String, Vec<CognosExpression>),
    IntentBlock(String, Vec<CognosExpression>),
    TemplateInvocation(String, HashMap<String, String>),
}

#[derive(Debug, Clone)]
pub enum CognosLiteral {
    Integer(i64),
    Float(f64),
    String(String),
    Boolean(bool),
}

// 実装済み: 基本的なAST構造
// テスト済み: パーサーからのAST構築
```

#### 拡張AST設計 📝 **設計完了**
```rust
// 設計済み拡張AST
#[derive(Debug, Clone)]
pub enum CognosExpression {
    // 既存要素...
    
    // S式拡張
    SExpression(SExpr),
    
    // 型付き式
    TypedExpression {
        expression: Box<CognosExpression>,
        type_annotation: CognosType,
        constraints: Vec<Constraint>,
    },
    
    // AI検証式
    AIVerified {
        expression: Box<CognosExpression>,
        verification_level: VerificationLevel,
        proof: Option<Proof>,
    },
    
    // パターンマッチング
    Match {
        scrutinee: Box<CognosExpression>,
        arms: Vec<MatchArm>,
    },
}

#[derive(Debug, Clone)]
pub struct SExpr {
    pub head: SExprHead,
    pub args: Vec<SExprArg>,
    pub location: SourceLocation,
}

#[derive(Debug, Clone)]
pub enum SExprHead {
    Symbol(String),
    Keyword(String),
    Operator(BinaryOperator),
}

// 実装予定: S式パーサー完了と同時
```

### 2.2 意味解析フェーズ 📝 **設計完了**

```rust
// 設計済み意味解析器
pub struct SemanticAnalyzer {
    type_checker: TypeChecker,
    constraint_solver: ConstraintSolver,
    scope_analyzer: ScopeAnalyzer,
    ai_verifier: Option<AIVerifier>,
}

impl SemanticAnalyzer {
    pub fn analyze(&mut self, ast: &CognosAST) -> Result<AnalyzedAST, SemanticError> {
        // Phase 1: スコープ解析
        let scoped_ast = self.scope_analyzer.analyze(ast)?;
        
        // Phase 2: 型推論
        let typed_ast = self.type_checker.infer_types(&scoped_ast)?;
        
        // Phase 3: 制約解決
        let constraint_solution = self.constraint_solver.solve(&typed_ast)?;
        
        // Phase 4: AI検証（オプション）
        let verified_ast = if let Some(verifier) = &mut self.ai_verifier {
            verifier.verify(&typed_ast, &constraint_solution)?
        } else {
            typed_ast
        };
        
        Ok(AnalyzedAST {
            ast: verified_ast,
            type_info: constraint_solution.type_assignments,
            verification_info: constraint_solution.verifications,
        })
    }
}

// 実装予定: 型システム完成後（4-6週間）
```

### 2.3 コード生成 🔄 **設計中**

#### LLVM IRジェネレータ設計
```rust
// 設計中: LLVM統合
pub struct LLVMCodeGenerator {
    context: LLVMContextRef,
    module: LLVMModuleRef,
    builder: LLVMBuilderRef,
    type_mapper: TypeToLLVMMapper,
}

impl LLVMCodeGenerator {
    pub fn generate(&mut self, analyzed_ast: &AnalyzedAST) -> Result<LLVMModule, CodeGenError> {
        // 型情報からLLVM型にマッピング
        let type_context = self.type_mapper.create_context(&analyzed_ast.type_info)?;
        
        // 関数定義の生成
        for function in &analyzed_ast.ast.functions {
            self.generate_function(function, &type_context)?;
        }
        
        // 検証
        self.verify_module()?;
        
        Ok(LLVMModule::from_raw(self.module))
    }
    
    fn generate_intent_block(
        &mut self,
        intent: &IntentBlock,
        context: &CodeGenContext
    ) -> Result<LLVMValueRef, CodeGenError> {
        match &intent.implementation {
            IntentImplementation::AIGenerated(code) => {
                // AI生成コードのLLVM IR生成
                self.generate_ai_code(code, context)
            }
            IntentImplementation::Manual(expr) => {
                // 手動実装のLLVM IR生成
                self.generate_expression(expr, context)
            }
            IntentImplementation::Template(template) => {
                // テンプレート展開後のLLVM IR生成
                let expanded = self.expand_template(template)?;
                self.generate_expression(&expanded, context)
            }
        }
    }
}

// 実装予定: 意味解析完成後（6-8週間）
```

---

## 3. 制約ソルバー（Z3/CVC5）統合仕様

### 3.1 制約ソルバー統合インターフェース 📝 **設計完了**

```rust
// 設計済み制約ソルバー統合
use z3::{Config, Context, Solver};

pub struct ConstraintSolver {
    z3_context: Context,
    solver: Solver,
    constraint_translator: ConstraintToSMTTranslator,
}

impl ConstraintSolver {
    pub fn new() -> Result<Self, ConstraintSolverError> {
        let config = Config::new();
        let context = Context::new(&config);
        let solver = Solver::new(&context);
        
        Ok(Self {
            z3_context: context,
            solver,
            constraint_translator: ConstraintToSMTTranslator::new(),
        })
    }
    
    pub fn solve_constraints(
        &mut self,
        constraints: &[Constraint]
    ) -> Result<ConstraintSolution, ConstraintSolverError> {
        // 制約をSMT式に変換
        let smt_constraints = constraints.iter()
            .map(|c| self.constraint_translator.translate(c, &self.z3_context))
            .collect::<Result<Vec<_>, _>>()?;
        
        // ソルバーに制約を追加
        for constraint in smt_constraints {
            self.solver.assert(&constraint);
        }
        
        // 充足可能性チェック
        match self.solver.check() {
            z3::SatResult::Sat => {
                let model = self.solver.get_model().unwrap();
                Ok(self.extract_solution(&model))
            }
            z3::SatResult::Unsat => {
                Err(ConstraintSolverError::Unsatisfiable)
            }
            z3::SatResult::Unknown => {
                Err(ConstraintSolverError::Timeout)
            }
        }
    }
}

// 実装予定: 型システム安定後（3-4週間）
```

### 3.2 制約の種類とSMT変換 📝 **設計完了**

```rust
// 設計済み制約変換
pub struct ConstraintToSMTTranslator;

impl ConstraintToSMTTranslator {
    pub fn translate(
        &self,
        constraint: &Constraint,
        ctx: &Context
    ) -> Result<z3::ast::Bool, TranslationError> {
        match constraint {
            Constraint::TypeEquality(t1, t2) => {
                // τ₁ ≡ τ₂ → (= type1 type2)
                let type1_var = self.type_to_smt_var(t1, ctx)?;
                let type2_var = self.type_to_smt_var(t2, ctx)?;
                Ok(type1_var._eq(&type2_var))
            }
            
            Constraint::MemorySafe(expr) => {
                // メモリ安全性制約の変換
                self.memory_safety_to_smt(expr, ctx)
            }
            
            Constraint::ThreadSafe(expr) => {
                // スレッド安全性制約の変換
                self.thread_safety_to_smt(expr, ctx)
            }
            
            Constraint::UserDefined(name, args) => {
                // ユーザー定義制約の変換
                self.user_constraint_to_smt(name, args, ctx)
            }
        }
    }
    
    fn memory_safety_to_smt(
        &self,
        expr: &CognosExpression,
        ctx: &Context
    ) -> Result<z3::ast::Bool, TranslationError> {
        match expr {
            CognosExpression::Dereference(ptr_expr) => {
                // *ptr が安全 ↔ ptr != null ∧ valid(ptr)
                let ptr_var = self.expr_to_smt_var(ptr_expr, ctx)?;
                let null_ptr = ctx.from_i64(0);
                let not_null = ptr_var._eq(&null_ptr).not();
                let valid = self.create_validity_predicate(&ptr_var, ctx);
                Ok(z3::ast::Bool::and(ctx, &[&not_null, &valid]))
            }
            // 他のメモリ操作の安全性変換...
            _ => Err(TranslationError::UnsupportedExpression),
        }
    }
}

// 実装予定: 制約ソルバー基盤完成後（4-5週間）
```

### 3.3 AI検証制約 🔄 **設計中**

```rust
// 設計中: AI検証制約の統合
pub struct AIVerificationConstraint {
    pub expression: CognosExpression,
    pub verification_level: VerificationLevel,
    pub ai_proof: Option<AIProof>,
}

impl ConstraintToSMTTranslator {
    fn ai_verification_to_smt(
        &self,
        constraint: &AIVerificationConstraint,
        ctx: &Context
    ) -> Result<z3::ast::Bool, TranslationError> {
        match constraint.verification_level {
            VerificationLevel::AIAssisted => {
                // AI支援検証: 基本制約 + AI証明の信頼度
                let basic_constraints = self.basic_safety_constraints(&constraint.expression, ctx)?;
                
                if let Some(proof) = &constraint.ai_proof {
                    let confidence = ctx.from_f64(proof.confidence);
                    let threshold = ctx.from_f64(0.95); // 95%以上の信頼度
                    let ai_constraint = confidence.ge(&threshold);
                    
                    Ok(z3::ast::Bool::and(ctx, &[&basic_constraints, &ai_constraint]))
                } else {
                    Ok(basic_constraints)
                }
            }
            VerificationLevel::Formal => {
                // 形式的検証: 完全な数学的証明が必要
                self.formal_verification_to_smt(&constraint.expression, ctx)
            }
        }
    }
}

// 実装予定: AI統合インターフェース完成後（8-10週間）
```

---

## 4. セルフホスティング計画の具体的ロードマップ

### 4.1 セルフホスティングの段階定義 📝 **設計完了**

#### Stage 0: ブートストラップ準備 ✅ **部分実装**
```
現在の状況:
- Rustでの基本コンパイラ実装: 23%完了
- 基本的なCognosコードの解析: 可能
- 簡単なAST構築: 動作確認済み

完了判定:
- Hello WorldレベルのCognosコードがパース可能
- 基本的な型チェックが動作
- 単純な関数定義がコンパイル可能

実装期間: 現在進行中、あと1-2ヶ月で完了
```

#### Stage 1: 最小セルフコンパイラ 📝 **設計完了**
```rust
// セルフホスティング最小版の設計
// cognos_bootstrap.cog - Cognosで書かれた最小コンパイラ

use cognos::parser::{Parser, Token};
use cognos::types::{TypeChecker, Type};

fn main() -> Result<(), CompilerError> {
    let source = read_source_file("input.cog")?;
    let tokens = tokenize(source)?;
    let ast = parse(tokens)?;
    let typed_ast = type_check(ast)?;
    let code = generate_code(typed_ast)?;
    write_output(code)?;
    Ok(())
}

// 基本的な機能のみ
fn tokenize(source: String) -> Result<Vec<Token>, ParseError> {
    intent! {
        "Tokenize Cognos source code into basic tokens"
        input: source
    } -> {
        // AI生成または手動実装
        basic_tokenizer(source)
    }
}

// 実装予定: Stage 0完了後、3-4ヶ月
```

#### Stage 2: 機能拡張セルフコンパイラ 🔄 **設計中**
```
機能範囲:
- 完全なCognos構文サポート
- AI統合機能
- 最適化機能
- エラー回復

判定条件:
- 自分自身をコンパイル可能
- 生成されたバイナリが元のコンパイラと同等
- 全テストスイートが通過

実装予定: Stage 1完了後、4-6ヶ月
```

#### Stage 3: 完全セルフホスティング ❌ **未着手**
```
最終目標:
- Cognosコンパイラ全体をCognosで記述
- 開発ツール全体のセルフホスティング
- コミュニティによる継続開発

実装予定: 12-18ヶ月後
```

### 4.2 セルフホスティング検証プロセス 📝 **設計完了**

```rust
// 設計済みセルフホスティング検証
pub struct SelfHostingVerifier {
    original_compiler: RustCompiler,
    bootstrap_compiler: CognosCompiler,
}

impl SelfHostingVerifier {
    pub fn verify_self_hosting(&self) -> Result<VerificationReport, VerificationError> {
        // Step 1: 原本コンパイラでブートストラップコンパイラをコンパイル
        let bootstrap_binary = self.original_compiler
            .compile("cognos_bootstrap.cog")?;
        
        // Step 2: ブートストラップコンパイラで自分自身をコンパイル
        let self_compiled_binary = bootstrap_binary
            .compile("cognos_bootstrap.cog")?;
        
        // Step 3: バイナリ比較
        let binary_hash_1 = compute_hash(&bootstrap_binary);
        let binary_hash_2 = compute_hash(&self_compiled_binary);
        
        // Step 4: 機能テスト
        let functional_tests = self.run_comprehensive_tests(&self_compiled_binary)?;
        
        Ok(VerificationReport {
            binary_reproducible: binary_hash_1 == binary_hash_2,
            functional_tests_passed: functional_tests.all_passed(),
            performance_comparison: self.compare_performance(&bootstrap_binary, &self_compiled_binary)?,
        })
    }
}

// 実装予定: Stage 1準備段階（2-3ヶ月後）
```

---

## 5. 実装優先順位と依存関係

### 5.1 クリティカルパス分析 📝 **設計完了**

```
Phase 1 (基盤): 1-3ヶ月
  ✅ 字句解析器 → ✅ 基本パーサー → 📝 S式パーサー
  ↓
  📝 型システム基盤 → 📝 制約ソルバー基盤
  
Phase 2 (統合): 3-6ヶ月  
  📝 AI統合インターフェース → 🔄 テンプレートシステム
  ↓
  🔄 意味解析器 → 🔄 コード生成器
  
Phase 3 (完成): 6-12ヶ月
  ❌ LLVM統合 → ❌ 最適化システム
  ↓
  ❌ セルフホスティング → ❌ IDE統合
```

### 5.2 リスク評価と対策 📝 **設計完了**

#### 高リスク項目
1. **AI統合の複雑性**
   - リスク: 外部APIの不安定性、レスポンス時間
   - 対策: オフライン代替手段、キャッシュ機構

2. **制約ソルバーの性能**
   - リスク: 大規模プログラムでの解決時間爆発
   - 対策: 制約の段階的解決、ヒューリスティック導入

3. **セルフホスティングの複雑性**
   - リスク: 循環依存、デバッグ困難
   - 対策: 段階的移行、広範囲テスト

#### 実装予定とリスク軽減
```rust
// リスク軽減のための設計パターン
pub trait CompilerBackend {
    fn compile(&self, ast: &AnalyzedAST) -> Result<CompiledCode, CompileError>;
}

// 複数バックエンドでリスク分散
pub struct RustBackend; // 安定版
pub struct LLVMBackend; // 高性能版
pub struct InterpreterBackend; // デバッグ版

// 段階的移行を可能にする設計
pub struct HybridCompiler {
    rust_backend: RustBackend,
    llvm_backend: Option<LLVMBackend>,
}
```

---

## 6. 今後の実装スケジュール

### 6.1 短期目標（1-3ヶ月）
- [ ] S式パーサー完成
- [ ] 型推論エンジン完成  
- [ ] 制約ソルバー基本統合
- [ ] 基本的なコード生成

### 6.2 中期目標（3-6ヶ月）
- [ ] AI統合インターフェース
- [ ] テンプレートシステム
- [ ] 完全な意味解析
- [ ] LLVM統合開始

### 6.3 長期目標（6-12ヶ月）
- [ ] セルフホスティング達成
- [ ] IDE統合
- [ ] 最適化システム
- [ ] パッケージマネージャ

この実装ガイドは進捗に応じて継続的に更新し、実装状況を正確に反映します。