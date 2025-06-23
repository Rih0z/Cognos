# Cognos言語完全仕様書 v1.0
## 実装状況と設計段階の明確な区別

**実装状況表記:**
- ✅ **実装済み**: 動作するコードが存在
- 📝 **設計完了**: 詳細仕様あり、実装待ち
- 🔄 **設計中**: 基本方針決定、詳細化必要
- ❌ **未着手**: 将来検討項目

---

## 1. 言語概要

### 1.1 Cognos言語の目標
- AI統合による開発効率向上
- 構造的安全性保証
- 自然言語との融合
- 段階的詳細化による開発支援

### 1.2 パラダイム
- 関数型 + 命令型のハイブリッド
- 制約ベースプログラミング
- 意図宣言型プログラミング
- テンプレート駆動開発

---

## 2. 完全文法定義

### 2.1 字句規則（Lexical Grammar）✅ **実装済み**

```ebnf
(* トークン定義 *)
WHITESPACE  = (" " | "\t" | "\r" | "\n")+ ;
COMMENT     = "//" [^\n]* "\n" | "/*" (.*?) "*/" ;

(* キーワード *)
KEYWORD     = "fn" | "let" | "mut" | "if" | "else" | "match" | "while" 
            | "for" | "return" | "struct" | "trait" | "impl" | "mod"
            | "use" | "pub" | "const" | "static" | "async" | "await"
            | "intent" | "template" | "verify" | "natural" ;

(* 識別子 *)
IDENTIFIER  = LETTER (LETTER | DIGIT | "_")* ;
LETTER      = "a".."z" | "A".."Z" | "_" ;
DIGIT       = "0".."9" ;

(* リテラル *)
INTEGER     = DIGIT+ ("_" DIGIT+)* ;
FLOAT       = DIGIT+ "." DIGIT+ ([eE] [+-]? DIGIT+)? ;
STRING      = '"' (CHAR | ESCAPE)* '"' ;
CHAR        = [^"\\] ;
ESCAPE      = "\\" ("n" | "t" | "r" | "\\" | '"') ;

(* 自然言語リテラル *)
NATURAL_LANG = "`" [^`]* "`" ;

(* S式構文 *)
LPAREN      = "(" ;
RPAREN      = ")" ;
LBRACKET    = "[" ;
RBRACKET    = "]" ;
LBRACE      = "{" ;
RBRACE      = "}" ;

(* 演算子 *)
BINOP       = "+" | "-" | "*" | "/" | "%" | "==" | "!=" | "<" | ">" 
            | "<=" | ">=" | "&&" | "||" | "&" | "|" | "^" | "<<" | ">>" ;
UNOP        = "!" | "-" | "~" | "*" | "&" ;
ASSIGN      = "=" | "+=" | "-=" | "*=" | "/=" | "%=" ;

(* デリミタ *)
SEMICOLON   = ";" ;
COMMA       = "," ;
DOT         = "." ;
COLON       = ":" ;
ARROW       = "->" ;
FAT_ARROW   = "=>" ;
PIPE        = "|>" ;
AT          = "@" ;
HASH        = "#" ;
QUESTION    = "?" ;
```

### 2.2 構文規則（Syntactic Grammar）📝 **設計完了**

```ebnf
(* プログラム構造 *)
program          = module_item* ;

module_item      = use_declaration
                 | function_definition
                 | struct_definition
                 | trait_definition
                 | impl_block
                 | const_declaration
                 | macro_definition
                 | s_expression ;

(* S式統合構文 *)
s_expression     = "(" s_expr_head s_expr_args* ")" ;
s_expr_head      = IDENTIFIER | KEYWORD ;
s_expr_args      = expression | s_expression | type_annotation ;

(* 関数定義 *)
function_definition = annotation* visibility? "async"? "fn" IDENTIFIER
                     generic_params? "(" parameter_list? ")" return_type?
                     where_clause? function_body ;

function_body    = block | s_expression | intent_block ;

parameter_list   = parameter ("," parameter)* ","? ;
parameter        = pattern ":" type_annotation ;

(* 型システム *)
type_annotation  = basic_type
                 | generic_type
                 | constraint_type
                 | ai_verified_type
                 | s_expr_type ;

basic_type       = "i32" | "i64" | "f32" | "f64" | "bool" | "str" 
                 | "char" | "()" ;

generic_type     = IDENTIFIER "<" type_list ">" ;
type_list        = type_annotation ("," type_annotation)* ","? ;

constraint_type  = type_annotation "where" constraint_list ;
constraint_list  = constraint ("," constraint)* ;
constraint       = type_annotation ":" trait_bound
                 | "verify" "(" verification_expr ")" ;

ai_verified_type = "@" "ai_verify" "(" verification_level ")" type_annotation ;
verification_level = "memory_safe" | "thread_safe" | "total_correct" ;

s_expr_type      = "(" "type" type_definition ")" ;
type_definition  = IDENTIFIER type_params? type_constraints? ;

(* 意図宣言構文 *)
intent_block     = "intent" "!" "{" intent_description input_spec? "}"
                   "=>" implementation_choice ;

intent_description = STRING ;
input_spec       = IDENTIFIER ":" expression ("," IDENTIFIER ":" expression)* ;
implementation_choice = block | "ai_generate" | template_instantiation ;

(* テンプレート構文 *)
template_instantiation = "@" "template" "(" template_name template_args? ")" ;
template_name    = STRING ;
template_args    = "," expression_list ;

(* 自然言語統合 *)
natural_syscall  = NATURAL_LANG "." "syscall" "(" expression_list? ")" ;

(* 式 *)
expression       = assignment_expr ;
assignment_expr  = logical_or_expr (ASSIGN assignment_expr)? ;
logical_or_expr  = logical_and_expr ("||" logical_and_expr)* ;
logical_and_expr = equality_expr ("&&" equality_expr)* ;
equality_expr    = relational_expr (("==" | "!=") relational_expr)* ;
relational_expr  = additive_expr (("<" | ">" | "<=" | ">=") additive_expr)* ;
additive_expr    = multiplicative_expr (("+" | "-") multiplicative_expr)* ;
multiplicative_expr = unary_expr (("*" | "/" | "%") unary_expr)* ;
unary_expr       = UNOP* postfix_expr ;
postfix_expr     = primary_expr postfix* ;

postfix          = "." IDENTIFIER
                 | "[" expression "]"
                 | "(" expression_list? ")"
                 | "?" ;

primary_expr     = IDENTIFIER
                 | literal
                 | "(" expression ")"
                 | block
                 | if_expr
                 | match_expr
                 | loop_expr
                 | intent_block
                 | natural_syscall
                 | s_expression ;

(* リテラル *)
literal          = INTEGER | FLOAT | STRING | NATURAL_LANG
                 | "true" | "false" | "null" ;

(* パターンマッチング *)
pattern          = literal_pattern
                 | identifier_pattern
                 | wildcard_pattern
                 | struct_pattern
                 | tuple_pattern
                 | or_pattern ;

literal_pattern  = literal ;
identifier_pattern = IDENTIFIER ;
wildcard_pattern = "_" ;
struct_pattern   = IDENTIFIER "{" field_patterns? "}" ;
field_patterns   = field_pattern ("," field_pattern)* ","? ;
field_pattern    = IDENTIFIER ":" pattern ;
tuple_pattern    = "(" pattern_list? ")" ;
or_pattern       = pattern "|" pattern ;

(* 注釈 *)
annotation       = "#" "[" meta_item "]" | "@" attribute_item ;
meta_item        = IDENTIFIER ("(" meta_item_list? ")")? ;
attribute_item   = IDENTIFIER ("(" expression_list? ")")? ;

(* ブロック *)
block            = "{" statement* expression? "}" ;
statement        = let_statement
                 | expression_statement
                 | return_statement ;

let_statement    = "let" pattern type_annotation? "=" expression ";" ;
expression_statement = expression ";" ;
return_statement = "return" expression? ";" ;
```

### 2.3 演算子優先順位✅ **実装済み**

```
優先度  演算子           結合性    実装状況
1      postfix . [] ()   左       ✅ 実装済み
2      unary ! - ~ * &   右       ✅ 実装済み
3      * / %             左       ✅ 実装済み
4      + -               左       ✅ 実装済み
5      << >>             左       📝 設計完了
6      < > <= >=         左       ✅ 実装済み
7      == !=             左       ✅ 実装済み
8      &                 左       📝 設計完了
9      ^                 左       📝 設計完了
10     |                 左       📝 設計完了
11     &&                左       ✅ 実装済み
12     ||                左       ✅ 実装済み
13     ..                左       🔄 設計中
14     = += -= etc       右       📝 設計完了
15     =>                右       ✅ 実装済み
```

---

## 3. S式ベース構文の詳細仕様

### 3.1 S式統合アプローチ📝 **設計完了**

```cognos
// 通常の関数定義
fn factorial(n: i32) -> i32 {
    if n <= 1 { 1 } else { n * factorial(n - 1) }
}

// S式での同等定義
(function factorial
  (params (n i32))
  (returns i32)
  (body
    (if (<= n 1)
        1
        (* n (factorial (- n 1))))))

// ハイブリッド構文（AI最適化）
(ai-optimize factorial
  (intent "Calculate factorial efficiently")
  (constraints (no-stack-overflow positive-input))
  (implementation
    fn factorial(n: i32) -> i32 {
        // 通常構文での実装
    }))
```

### 3.2 型注釈付きS式📝 **設計完了**

```cognos
// 型安全なS式
(typed-function
  (signature
    (name process-users)
    (params ((users (Vec User))))
    (returns (Result (Vec ProcessedUser) Error))
    (constraints (memory-safe thread-safe)))
  (verification
    (pre-condition (not-empty users))
    (post-condition (length-preserved)))
  (implementation
    (map users process-single-user)))

// コンパイル時型チェック
(verify-types
  (expression (map users process-single-user))
  (context ((users (Vec User)) (process-single-user (Fn User ProcessedUser))))
  (expected (Vec ProcessedUser)))
```

### 3.3 メタプログラミング支援📝 **設計完了**

```cognos
// マクロ定義
(define-macro derive-debug
  (params (struct-name))
  (expansion
    (impl Debug for struct-name
      (fn fmt (self f)
        (write-struct-fields f self)))))

// テンプレート定義
(define-template web-endpoint
  (params (path method handler))
  (constraints (valid-http-method method))
  (generates
    (route path method
      (fn (req)
        (let result (handler req))
        (json-response result)))))
```

---

## 4. テンプレートシステムの技術仕様

### 4.1 テンプレート定義言語🔄 **設計中**

```cognos
// テンプレート定義構文
template WebHandler<T: Serializable> {
    // テンプレートパラメータ
    params {
        endpoint_path: String,
        request_type: Type,
        response_type: T,
    }
    
    // 制約条件
    constraints {
        verify!(valid_path(endpoint_path)),
        verify!(implements(request_type, Deserializable)),
        verify!(implements(T, Serializable)),
    }
    
    // 生成されるコード
    generates {
        async fn handle_{endpoint_path}(req: {request_type}) -> Result<{response_type}, Error> {
            // 共通のバリデーション
            validate_request(&req)?;
            
            // ユーザー実装部分
            let result = process_request(req).await?;
            
            // 共通のレスポンス処理
            Ok(serialize_response(result)?)
        }
        
        // ルート登録
        pub fn register_routes(app: &mut App) {
            app.route("{endpoint_path}", web::post().to(handle_{endpoint_path}));
        }
    }
}
```

### 4.2 テンプレート展開エンジン🔄 **設計中**

```rust
// テンプレート展開エンジンの設計
pub struct TemplateEngine {
    templates: HashMap<String, Template>,
    type_checker: TypeChecker,
    constraint_solver: ConstraintSolver,
}

impl TemplateEngine {
    pub fn expand_template(
        &self,
        template_name: &str,
        args: &TemplateArgs,
        context: &ExpansionContext
    ) -> Result<ExpandedCode, TemplateError> {
        // 1. テンプレート取得
        let template = self.templates.get(template_name)
            .ok_or(TemplateError::NotFound)?;
        
        // 2. 制約検証
        self.verify_constraints(template, args)?;
        
        // 3. 型チェック
        self.type_checker.verify_template_types(template, args)?;
        
        // 4. コード生成
        let expanded = self.generate_code(template, args, context)?;
        
        // 5. 後処理（フォーマット、最適化）
        Ok(self.post_process(expanded)?)
    }
}
```

### 4.3 テンプレート型安全性📝 **設計完了**

```cognos
// 型安全なテンプレート使用
@template(WebHandler<UserResponse>)
@verify_types(
    endpoint_path = "/users",
    request_type = CreateUserRequest,
    response_type = UserResponse
)
fn create_user_endpoint() {
    // テンプレートが生成するコードを使用
}

// コンパイル時検証
static_assert!(
    implements(CreateUserRequest, Deserializable),
    "CreateUserRequest must implement Deserializable"
);

static_assert!(
    implements(UserResponse, Serializable),
    "UserResponse must implement Serializable"
);
```

---

## 5. 型システムと制約検証の数学的定義

### 5.1 型システムの形式的定義📝 **設計完了**

#### 基本型
```
τ ::= Int | Float | Bool | String | Unit     (基本型)
    | τ₁ → τ₂                               (関数型)
    | (τ₁, τ₂, ..., τₙ)                     (タプル型)
    | [τ]                                    (配列型)
    | μα.τ                                   (再帰型)
    | ∀α.τ                                   (多相型)
    | α                                      (型変数)
    | τ where C                              (制約付き型)
    | Verified(τ, P)                         (検証済み型)
```

#### 型環境
```
Γ ::= ∅ | Γ, x: τ                          (型環境)
```

#### 型判定規則
```
(VAR)
x: τ ∈ Γ
────────
Γ ⊢ x: τ

(ABS)
Γ, x: τ₁ ⊢ e: τ₂
────────────────
Γ ⊢ λx.e: τ₁ → τ₂

(APP)
Γ ⊢ e₁: τ₁ → τ₂    Γ ⊢ e₂: τ₁
────────────────────────────
Γ ⊢ e₁ e₂: τ₂

(LET)
Γ ⊢ e₁: τ₁    Γ, x: τ₁ ⊢ e₂: τ₂
────────────────────────────────
Γ ⊢ let x = e₁ in e₂: τ₂

(INTENT)
Γ ⊢ spec: Intent(τ₁, τ₂)    Γ ⊢ impl: τ₁ → τ₂    VerifyIntent(spec, impl)
──────────────────────────────────────────────────────────────────────
Γ ⊢ intent spec impl: τ₁ → τ₂
```

### 5.2 制約システム📝 **設計完了**

#### 制約の種類
```
C ::= τ₁ ≡ τ₂                              (型等価制約)
    | τ₁ <: τ₂                             (部分型制約)
    | HasTrait(τ, T)                        (トレイト制約)
    | MemorySafe(τ)                         (メモリ安全制約)
    | ThreadSafe(τ)                         (スレッド安全制約)
    | Verified(τ, P)                        (検証制約)
    | C₁ ∧ C₂                               (制約の連言)
    | ∃α.C                                  (存在量化制約)
```

#### 制約解決アルゴリズム
```
solve(C) = case C of
    τ₁ ≡ τ₂ → unify(τ₁, τ₂)
    τ₁ <: τ₂ → check_subtype(τ₁, τ₂)
    HasTrait(τ, T) → check_trait_impl(τ, T)
    MemorySafe(τ) → verify_memory_safety(τ)
    ThreadSafe(τ) → verify_thread_safety(τ)
    Verified(τ, P) → call_external_verifier(τ, P)
    C₁ ∧ C₂ → solve(C₁) ∧ solve(C₂)
    ∃α.C → instantiate_and_solve(α, C)
```

### 5.3 単一化アルゴリズム✅ **実装済み**

```rust
// 実装済みの単一化アルゴリズム
fn unify(t1: &Type, t2: &Type, subst: &mut Substitution) -> Result<(), TypeError> {
    match (t1, t2) {
        (Type::Var(v), t) | (t, Type::Var(v)) => {
            if t.contains_var(v) {
                Err(TypeError::OccursCheck)
            } else {
                subst.insert(v.clone(), t.clone());
                Ok(())
            }
        }
        (Type::Function(f1), Type::Function(f2)) => {
            if f1.params.len() != f2.params.len() {
                return Err(TypeError::ArityMismatch);
            }
            for (p1, p2) in f1.params.iter().zip(&f2.params) {
                unify(p1, p2, subst)?;
            }
            unify(&f1.return_type, &f2.return_type, subst)
        }
        (Type::Tuple(ts1), Type::Tuple(ts2)) => {
            if ts1.len() != ts2.len() {
                return Err(TypeError::ArityMismatch);
            }
            for (t1, t2) in ts1.iter().zip(ts2) {
                unify(t1, t2, subst)?;
            }
            Ok(())
        }
        (t1, t2) if t1 == t2 => Ok(()),
        _ => Err(TypeError::UnificationFailure),
    }
}
```

---

## 6. 実装状況の明確な記載

### 6.1 実装済み要素 ✅

1. **字句解析器**
   - logos crateを使用
   - 全基本トークンをサポート
   - 自然言語リテラル認識

2. **基本パーサー**
   - 関数定義のパース
   - 式のパース（優先順位付き）
   - intent!構文のパース

3. **型システム基盤**
   - 基本型の定義
   - 単一化アルゴリズム
   - 制約表現の枠組み

### 6.2 設計完了・実装待ち 📝

1. **S式統合パーサー**
   - 完全な仕様定義済み
   - 実装予定: 2-3週間

2. **制約ソルバー統合**
   - Z3連携インターフェース設計済み
   - 実装予定: 3-4週間

3. **テンプレートエンジン**
   - 完全な仕様定義済み
   - 実装予定: 4-6週間

### 6.3 設計中 🔄

1. **AI統合インターフェース**
   - 基本方針決定済み
   - 詳細API設計中

2. **最適化パス**
   - LLVMとの統合方法検討中
   - AI支援最適化の設計

### 6.4 未着手 ❌

1. **IDE統合**
   - Language Server実装
   - VS Code拡張

2. **デバッガ**
   - ソースレベルデバッガ
   - プロファイラ

3. **パッケージマネージャ**
   - 依存関係管理
   - ビルドシステム

---

## 7. 今後の実装計画

### Phase 1 (1-3ヶ月): 基本言語機能
- [ ] S式パーサー完成
- [ ] 型推論エンジン完成
- [ ] 基本的なコード生成

### Phase 2 (3-6ヶ月): AI統合
- [ ] 制約ソルバー統合
- [ ] AI API連携
- [ ] テンプレートシステム

### Phase 3 (6-12ヶ月): 完全機能
- [ ] 最適化システム
- [ ] IDE統合
- [ ] セルフホスティング

この仕様書は実装進捗に応じて継続的に更新されます。