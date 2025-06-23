# Cognos 実装スターターキット

## 🚀 明日から始められる実装ガイド

このドキュメントは、Cognosプロジェクトの実装を**今すぐ開始**できるように、具体的なコード例とセットアップ手順を提供します。

## 📋 環境セットアップ（30分で完了）

### 1. 必要な依存関係インストール
```bash
# Rust インストール（まだの場合）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# バージョン確認
rustc --version  # 1.70+ が必要
cargo --version

# 開発ツール
cargo install cargo-watch cargo-tarpaulin
```

### 2. プロジェクト初期化
```bash
# 新規Rustプロジェクト作成
cargo new cognos-lang --bin
cd cognos-lang

# 必要な依存関係を Cargo.toml に追加
```

### 3. Cargo.toml 設定
```toml
[package]
name = "cognos-lang"
version = "0.1.0"
edition = "2021"
description = "Cognos Programming Language Interpreter"
license = "MIT"

[dependencies]
nom = "7.1"
thiserror = "1.0"
clap = { version = "4.0", features = ["derive"] }
rustyline = "12.0"

[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "parser_benchmark"
harness = false
```

## 📝 基本的なファイル構造（実装済みテンプレート）

### src/main.rs
```rust
use clap::Parser;
use std::fs;
use std::process;

mod lexer;
mod parser;
mod evaluator;
mod repl;
mod error;

use crate::evaluator::Environment;
use crate::repl::start_repl;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Input file to execute
    file: Option<String>,
    
    /// Start REPL mode
    #[arg(short, long)]
    interactive: bool,
}

fn main() {
    let args = Args::parse();
    
    if args.interactive || args.file.is_none() {
        println!("Cognos Language REPL v0.1.0");
        println!("Type (exit) to quit");
        if let Err(e) = start_repl() {
            eprintln!("REPL error: {}", e);
            process::exit(1);
        }
    } else if let Some(filename) = args.file {
        if let Err(e) = run_file(&filename) {
            eprintln!("Error: {}", e);
            process::exit(1);
        }
    }
}

fn run_file(filename: &str) -> Result<(), Box<dyn std::error::Error>> {
    let content = fs::read_to_string(filename)?;
    let mut env = Environment::new();
    
    match parser::parse_program(&content) {
        Ok(expressions) => {
            for expr in expressions {
                match env.eval(&expr) {
                    Ok(value) => println!("{}", value),
                    Err(e) => {
                        eprintln!("Runtime error: {}", e);
                        return Err(Box::new(e));
                    }
                }
            }
        }
        Err(e) => {
            eprintln!("Parse error: {}", e);
            return Err(Box::new(e));
        }
    }
    
    Ok(())
}
```

### src/lexer.rs
```rust
use nom::{
    branch::alt,
    bytes::complete::{tag, take_while1, take_until},
    character::complete::{char, multispace0, digit1, alpha1, alphanumeric1},
    combinator::{map, opt, recognize},
    multi::many0,
    sequence::{delimited, pair, preceded},
    IResult,
};

#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    LeftParen,
    RightParen,
    Symbol(String),
    Number(i64),
    String(String),
    Comment(String),
}

impl std::fmt::Display for Token {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Token::LeftParen => write!(f, "("),
            Token::RightParen => write!(f, ")"),
            Token::Symbol(s) => write!(f, "{}", s),
            Token::Number(n) => write!(f, "{}", n),
            Token::String(s) => write!(f, "\"{}\"", s),
            Token::Comment(s) => write!(f, ";{}", s),
        }
    }
}

pub fn tokenize(input: &str) -> IResult<&str, Vec<Token>> {
    many0(preceded(multispace0, token))(input)
}

fn token(input: &str) -> IResult<&str, Token> {
    alt((
        map(char('('), |_| Token::LeftParen),
        map(char(')'), |_| Token::RightParen),
        number,
        string_literal,
        comment,
        symbol,
    ))(input)
}

fn number(input: &str) -> IResult<&str, Token> {
    map(
        recognize(pair(opt(char('-')), digit1)),
        |s: &str| Token::Number(s.parse().unwrap())
    )(input)
}

fn string_literal(input: &str) -> IResult<&str, Token> {
    map(
        delimited(char('"'), take_until("\""), char('"')),
        |s: &str| Token::String(s.to_string())
    )(input)
}

fn comment(input: &str) -> IResult<&str, Token> {
    map(
        preceded(char(';'), take_until("\n")),
        |s: &str| Token::Comment(s.to_string())
    )(input)
}

fn symbol(input: &str) -> IResult<&str, Token> {
    map(
        recognize(pair(
            alt((alpha1, tag("_"), tag("+"), tag("-"), tag("*"), tag("/"))),
            many0(alt((alphanumeric1, tag("_"), tag("-"), tag("?"))))
        )),
        |s: &str| Token::Symbol(s.to_string())
    )(input)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenize_basic() {
        let input = "(+ 1 2)";
        let (remaining, tokens) = tokenize(input).unwrap();
        
        assert_eq!(remaining, "");
        assert_eq!(tokens, vec![
            Token::LeftParen,
            Token::Symbol("+".to_string()),
            Token::Number(1),
            Token::Number(2),
            Token::RightParen,
        ]);
    }

    #[test]
    fn test_tokenize_string() {
        let input = r#"(print "hello world")"#;
        let (_, tokens) = tokenize(input).unwrap();
        
        assert_eq!(tokens[2], Token::String("hello world".to_string()));
    }

    #[test]
    fn test_tokenize_comment() {
        let input = "; This is a comment\n(+ 1 2)";
        let (_, tokens) = tokenize(input).unwrap();
        
        assert_eq!(tokens[0], Token::Comment(" This is a comment".to_string()));
    }
}
```

### src/parser.rs
```rust
use crate::lexer::{Token, tokenize};
use crate::error::ParseError;

#[derive(Debug, Clone, PartialEq)]
pub enum SExp {
    Atom(String),
    Number(i64),
    String(String),
    List(Vec<SExp>),
}

impl std::fmt::Display for SExp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SExp::Atom(s) => write!(f, "{}", s),
            SExp::Number(n) => write!(f, "{}", n),
            SExp::String(s) => write!(f, "\"{}\"", s),
            SExp::List(exprs) => {
                write!(f, "(")?;
                for (i, expr) in exprs.iter().enumerate() {
                    if i > 0 { write!(f, " ")?; }
                    write!(f, "{}", expr)?;
                }
                write!(f, ")")
            }
        }
    }
}

pub fn parse_program(input: &str) -> Result<Vec<SExp>, ParseError> {
    let (_, tokens) = tokenize(input).map_err(|e| ParseError::LexError(e.to_string()))?;
    
    let mut expressions = Vec::new();
    let mut pos = 0;
    
    while pos < tokens.len() {
        // コメントをスキップ
        if matches!(tokens[pos], Token::Comment(_)) {
            pos += 1;
            continue;
        }
        
        let (expr, new_pos) = parse_expression(&tokens, pos)?;
        expressions.push(expr);
        pos = new_pos;
    }
    
    Ok(expressions)
}

fn parse_expression(tokens: &[Token], pos: usize) -> Result<(SExp, usize), ParseError> {
    if pos >= tokens.len() {
        return Err(ParseError::UnexpectedEof);
    }
    
    match &tokens[pos] {
        Token::LeftParen => parse_list(tokens, pos + 1),
        Token::Symbol(s) => Ok((SExp::Atom(s.clone()), pos + 1)),
        Token::Number(n) => Ok((SExp::Number(*n), pos + 1)),
        Token::String(s) => Ok((SExp::String(s.clone()), pos + 1)),
        Token::RightParen => Err(ParseError::UnexpectedToken("unexpected ')'".to_string())),
        Token::Comment(_) => Err(ParseError::UnexpectedToken("unexpected comment".to_string())),
    }
}

fn parse_list(tokens: &[Token], mut pos: usize) -> Result<(SExp, usize), ParseError> {
    let mut elements = Vec::new();
    
    while pos < tokens.len() {
        match &tokens[pos] {
            Token::RightParen => {
                return Ok((SExp::List(elements), pos + 1));
            }
            Token::Comment(_) => {
                pos += 1; // コメントをスキップ
                continue;
            }
            _ => {
                let (expr, new_pos) = parse_expression(tokens, pos)?;
                elements.push(expr);
                pos = new_pos;
            }
        }
    }
    
    Err(ParseError::UnexpectedEof)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_number() {
        let result = parse_program("42").unwrap();
        assert_eq!(result, vec![SExp::Number(42)]);
    }

    #[test]
    fn test_parse_symbol() {
        let result = parse_program("hello").unwrap();
        assert_eq!(result, vec![SExp::Atom("hello".to_string())]);
    }

    #[test]
    fn test_parse_list() {
        let result = parse_program("(+ 1 2)").unwrap();
        assert_eq!(result, vec![SExp::List(vec![
            SExp::Atom("+".to_string()),
            SExp::Number(1),
            SExp::Number(2),
        ])]);
    }

    #[test]
    fn test_parse_nested_list() {
        let result = parse_program("(if (> x 0) (+ x 1) (- x 1))").unwrap();
        // ネストした構造のテスト
        assert!(matches!(result[0], SExp::List(_)));
    }
}
```

### src/evaluator.rs
```rust
use std::collections::HashMap;
use crate::parser::SExp;
use crate::error::EvalError;

#[derive(Debug, Clone)]
pub enum Value {
    Number(i64),
    String(String),
    Boolean(bool),
    List(Vec<Value>),
    Nil,
}

impl std::fmt::Display for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Value::Number(n) => write!(f, "{}", n),
            Value::String(s) => write!(f, "{}", s),
            Value::Boolean(b) => write!(f, "{}", b),
            Value::List(items) => {
                write!(f, "(")?;
                for (i, item) in items.iter().enumerate() {
                    if i > 0 { write!(f, " ")?; }
                    write!(f, "{}", item)?;
                }
                write!(f, ")")
            }
            Value::Nil => write!(f, "nil"),
        }
    }
}

pub struct Environment {
    vars: HashMap<String, Value>,
}

impl Environment {
    pub fn new() -> Self {
        Self {
            vars: HashMap::new(),
        }
    }
    
    pub fn eval(&mut self, expr: &SExp) -> Result<Value, EvalError> {
        match expr {
            SExp::Number(n) => Ok(Value::Number(*n)),
            SExp::String(s) => Ok(Value::String(s.clone())),
            SExp::Atom(name) => {
                self.vars.get(name)
                    .cloned()
                    .ok_or_else(|| EvalError::UndefinedVariable(name.clone()))
            }
            SExp::List(exprs) => {
                if exprs.is_empty() {
                    return Ok(Value::List(vec![]));
                }
                
                match &exprs[0] {
                    SExp::Atom(op) => self.eval_builtin(op, &exprs[1..]),
                    _ => Err(EvalError::InvalidOperation("not a function".to_string())),
                }
            }
        }
    }
    
    fn eval_builtin(&mut self, op: &str, args: &[SExp]) -> Result<Value, EvalError> {
        match op {
            "+" => self.eval_arithmetic(args, |a, b| a + b),
            "-" => self.eval_arithmetic(args, |a, b| a - b),
            "*" => self.eval_arithmetic(args, |a, b| a * b),
            "/" => self.eval_arithmetic(args, |a, b| {
                if b == 0 {
                    return Err(EvalError::DivisionByZero);
                }
                Ok(a / b)
            }),
            ">" => self.eval_comparison(args, |a, b| a > b),
            "<" => self.eval_comparison(args, |a, b| a < b),
            "=" => self.eval_comparison(args, |a, b| a == b),
            "if" => self.eval_if(args),
            "let" => self.eval_let(args),
            "print" => self.eval_print(args),
            _ => Err(EvalError::UndefinedFunction(op.to_string())),
        }
    }
    
    fn eval_arithmetic<F>(&mut self, args: &[SExp], op: F) -> Result<Value, EvalError>
    where
        F: Fn(i64, i64) -> Result<i64, EvalError>,
    {
        if args.len() < 2 {
            return Err(EvalError::ArityError { expected: 2, found: args.len() });
        }
        
        let first = self.eval(&args[0])?;
        let first_num = match first {
            Value::Number(n) => n,
            _ => return Err(EvalError::TypeError("expected number".to_string())),
        };
        
        args[1..].iter().try_fold(first_num, |acc, arg| {
            let val = self.eval(arg)?;
            match val {
                Value::Number(n) => op(acc, n),
                _ => Err(EvalError::TypeError("expected number".to_string())),
            }
        }).map(Value::Number)
    }
    
    fn eval_comparison<F>(&mut self, args: &[SExp], op: F) -> Result<Value, EvalError>
    where
        F: Fn(i64, i64) -> bool,
    {
        if args.len() != 2 {
            return Err(EvalError::ArityError { expected: 2, found: args.len() });
        }
        
        let left = self.eval(&args[0])?;
        let right = self.eval(&args[1])?;
        
        match (left, right) {
            (Value::Number(a), Value::Number(b)) => Ok(Value::Boolean(op(a, b))),
            _ => Err(EvalError::TypeError("comparison requires numbers".to_string())),
        }
    }
    
    fn eval_if(&mut self, args: &[SExp]) -> Result<Value, EvalError> {
        if args.len() != 3 {
            return Err(EvalError::ArityError { expected: 3, found: args.len() });
        }
        
        let condition = self.eval(&args[0])?;
        let is_truthy = match condition {
            Value::Boolean(b) => b,
            Value::Number(n) => n != 0,
            Value::Nil => false,
            _ => true,
        };
        
        if is_truthy {
            self.eval(&args[1])
        } else {
            self.eval(&args[2])
        }
    }
    
    fn eval_let(&mut self, args: &[SExp]) -> Result<Value, EvalError> {
        if args.len() != 2 {
            return Err(EvalError::ArityError { expected: 2, found: args.len() });
        }
        
        // (let ((var value)) body)
        match &args[0] {
            SExp::List(bindings) => {
                for binding in bindings {
                    match binding {
                        SExp::List(pair) if pair.len() == 2 => {
                            if let SExp::Atom(var_name) = &pair[0] {
                                let value = self.eval(&pair[1])?;
                                self.vars.insert(var_name.clone(), value);
                            } else {
                                return Err(EvalError::TypeError("variable name must be atom".to_string()));
                            }
                        }
                        _ => return Err(EvalError::TypeError("invalid binding".to_string())),
                    }
                }
                self.eval(&args[1])
            }
            _ => Err(EvalError::TypeError("let requires binding list".to_string())),
        }
    }
    
    fn eval_print(&mut self, args: &[SExp]) -> Result<Value, EvalError> {
        for arg in args {
            let value = self.eval(arg)?;
            println!("{}", value);
        }
        Ok(Value::Nil)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::parse_program;

    fn eval_string(input: &str) -> Result<Value, EvalError> {
        let mut env = Environment::new();
        let exprs = parse_program(input).map_err(|_| EvalError::TypeError("parse error".to_string()))?;
        env.eval(&exprs[0])
    }

    #[test]
    fn test_basic_arithmetic() {
        assert_eq!(eval_string("(+ 1 2 3)").unwrap(), Value::Number(6));
        assert_eq!(eval_string("(* 2 3 4)").unwrap(), Value::Number(24));
        assert_eq!(eval_string("(- 10 3)").unwrap(), Value::Number(7));
    }

    #[test]
    fn test_comparison() {
        assert_eq!(eval_string("(> 5 3)").unwrap(), Value::Boolean(true));
        assert_eq!(eval_string("(< 5 3)").unwrap(), Value::Boolean(false));
        assert_eq!(eval_string("(= 5 5)").unwrap(), Value::Boolean(true));
    }

    #[test]
    fn test_if_expression() {
        assert_eq!(eval_string("(if (> 5 3) 42 0)").unwrap(), Value::Number(42));
        assert_eq!(eval_string("(if (< 5 3) 42 0)").unwrap(), Value::Number(0));
    }

    #[test]
    fn test_let_expression() {
        assert_eq!(eval_string("(let ((x 10)) (* x x))").unwrap(), Value::Number(100));
    }
}
```

### src/error.rs
```rust
use thiserror::Error;

#[derive(Error, Debug, Clone)]
pub enum ParseError {
    #[error("Lexical error: {0}")]
    LexError(String),
    
    #[error("Unexpected end of file")]
    UnexpectedEof,
    
    #[error("Unexpected token: {0}")]
    UnexpectedToken(String),
}

#[derive(Error, Debug, Clone)]
pub enum EvalError {
    #[error("Undefined variable: {0}")]
    UndefinedVariable(String),
    
    #[error("Undefined function: {0}")]
    UndefinedFunction(String),
    
    #[error("Type error: {0}")]
    TypeError(String),
    
    #[error("Arity error: expected {expected} arguments, found {found}")]
    ArityError { expected: usize, found: usize },
    
    #[error("Division by zero")]
    DivisionByZero,
    
    #[error("Invalid operation: {0}")]
    InvalidOperation(String),
}
```

### src/repl.rs
```rust
use rustyline::Editor;
use crate::evaluator::Environment;
use crate::parser::parse_program;
use crate::error::{ParseError, EvalError};

pub fn start_repl() -> Result<(), Box<dyn std::error::Error>> {
    let mut rl = Editor::<()>::new()?;
    let mut env = Environment::new();
    
    loop {
        let readline = rl.readline("cognos> ");
        match readline {
            Ok(line) => {
                if line.trim().is_empty() {
                    continue;
                }
                
                if line.trim() == "(exit)" {
                    break;
                }
                
                rl.add_history_entry(line.as_str());
                
                match execute_line(&line, &mut env) {
                    Ok(value) => println!("{}", value),
                    Err(e) => eprintln!("Error: {}", e),
                }
            }
            Err(rustyline::error::ReadlineError::Interrupted) => {
                println!("^C");
                break;
            }
            Err(rustyline::error::ReadlineError::Eof) => {
                println!("^D");
                break;
            }
            Err(err) => {
                eprintln!("Error: {}", err);
                break;
            }
        }
    }
    
    Ok(())
}

fn execute_line(line: &str, env: &mut Environment) -> Result<String, Box<dyn std::error::Error>> {
    let expressions = parse_program(line)?;
    
    let mut result = String::new();
    for expr in expressions {
        let value = env.eval(&expr)?;
        result = value.to_string();
    }
    
    Ok(result)
}
```

## 🚀 即座に実行可能なテストプログラム

### test_programs/basic.cognos
```lisp
; Basic arithmetic
(+ 1 2 3)

; Variables
(let ((x 10) (y 20))
  (+ x y))

; Conditionals
(if (> 10 5)
    "ten is greater"
    "five is greater")

; Nested expressions
(let ((a 5))
  (if (> a 0)
      (* a a)
      0))
```

### 実行方法
```bash
# REPL モード
cargo run -- --interactive

# ファイル実行
cargo run test_programs/basic.cognos

# テスト実行
cargo test

# ベンチマーク実行
cargo bench
```

## 📊 開発進捗の測定方法

### 日次チェックリスト
```bash
# 1. コードが正常にビルドされるか
cargo build

# 2. テストが通るか
cargo test

# 3. 新機能が動作するか
echo "(+ 1 2 3)" | cargo run -- --interactive

# 4. パフォーマンスが劣化していないか
cargo bench
```

### 週次レビュー項目
- [ ] 新機能の実装状況
- [ ] テストカバレッジの変化
- [ ] パフォーマンスの測定
- [ ] ドキュメントの更新

## ⚡ 今すぐ始める手順

```bash
# 1. このリポジトリをクローン
git clone <repository-url>
cd cognos

# 2. 上記のファイルを作成（または既存のものを確認）

# 3. 依存関係インストール
cargo build

# 4. テスト実行
cargo test

# 5. REPL起動
cargo run -- --interactive

# 6. テストプログラム実行
echo "(+ 1 2 3)" # 6が出力されるはず
```

**このスターターキットで、明日からCognos言語の実装を開始できます。**