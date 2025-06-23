# Phase 0 実装ロードマップ: Cognos基本言語処理系

## 🎯 Phase 0 目標（現実的・実装可能）

**期間**: 3-6ヶ月  
**ゴール**: 動作するCognos言語インタープリターの構築  
**検証**: QEMU Linux環境での実行確認

## 📅 週次実装スケジュール

### Week 1-2: 開発環境構築
**責任者**: 全チーム  
**成果物**: 
- [ ] Rust開発環境セットアップ（cargo, rustc 1.70+）
- [ ] Git workflow確立（feature branch運用）
- [ ] CI/CD pipeline構築（GitHub Actions）
- [ ] QEMU環境準備（Ubuntu 22.04 LTS）

**検証基準**:
```bash
# 動作確認コマンド
cargo --version  # 1.70+必須
rustc --version  # 1.70+必須
qemu-system-x86_64 --version  # 7.0+推奨
```

### Week 3-4: S式パーサー実装
**責任者**: lang-specialist  
**技術スタック**: Rust + nom parser combinator

#### 実装項目
1. **トークナイザー**
```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    LeftParen,
    RightParen,
    Symbol(String),
    Number(i64),
    String(String),
    Comment(String),
}
```

2. **パーサー**
```rust
pub fn parse_sexp(input: &str) -> IResult<&str, SExp> {
    alt((
        parse_atom,
        parse_list,
    ))(input)
}
```

**検証基準**:
- [ ] `(+ 1 2 3)`をパース可能
- [ ] ネストした構造`(if (> x 0) (+ x 1) (- x 1))`を処理
- [ ] 1MB のS式ファイルを10秒以内でパース
- [ ] エラー位置の正確な報告

### Week 5-6: AST構築と基本評価器
**責任者**: lang-specialist  

#### AST定義
```rust
#[derive(Debug, Clone)]
pub enum SExp {
    Atom(String),
    Number(i64),
    String(String),
    List(Vec<SExp>),
}

#[derive(Debug, Clone)]
pub enum Value {
    Number(i64),
    String(String),
    List(Vec<Value>),
    Function(fn(&[Value]) -> Result<Value, EvalError>),
}
```

**実装機能**:
- [ ] 基本算術演算（+, -, *, /）
- [ ] 比較演算（>, <, =, >=, <=）
- [ ] 条件分岐（if）
- [ ] 変数束縛（let）

**検証基準**:
```lisp
;; 実行可能なテストケース
(+ 1 2 3)  ; => 6
(if (> 5 3) "greater" "less")  ; => "greater"
(let ((x 10)) (* x x))  ; => 100
```

### Week 7-8: エラーハンドリングと型チェック
**責任者**: lang-specialist + ai-specialist（レビュー）

#### エラーシステム
```rust
#[derive(Debug, Clone)]
pub enum EvalError {
    TypeError { expected: String, found: String, position: usize },
    UndefinedVariable { name: String, position: usize },
    ArityError { expected: usize, found: usize, position: usize },
    DivisionByZero { position: usize },
}
```

**実装機能**:
- [ ] 型エラーの検出と報告
- [ ] 未定義変数の検出
- [ ] 関数引数数チェック
- [ ] 実行時エラーのスタックトレース

### Week 9-10: ファイルI/Oと基本ライブラリ
**責任者**: os-specialist + lang-specialist

#### システム統合
```rust
// ファイル読み込み
pub fn load_file(path: &str) -> Result<String, IoError>

// REPL環境
pub fn repl_loop() -> Result<(), ReplError>
```

**実装機能**:
- [ ] `.cognos`ファイルの読み込み
- [ ] REPL（Read-Eval-Print-Loop）環境
- [ ] 基本的なファイル操作関数
- [ ] エラーメッセージの表示

### Week 11-12: テストとドキュメント
**責任者**: 全チーム

#### テストスイート
```rust
#[cfg(test)]
mod tests {
    #[test]
    fn test_basic_arithmetic() { /* ... */ }
    
    #[test]
    fn test_file_operations() { /* ... */ }
    
    #[test]
    fn test_error_handling() { /* ... */ }
}
```

**成果物**:
- [ ] 90%以上のコードカバレッジ
- [ ] 100個以上の単体テスト
- [ ] ユーザーマニュアル（実行例付き）
- [ ] API仕様書

## 🛠️ 実装詳細（具体的コード例）

### 基本的な評価器実装例
```rust
use std::collections::HashMap;

pub struct Environment {
    vars: HashMap<String, Value>,
}

impl Environment {
    pub fn eval(&mut self, expr: &SExp) -> Result<Value, EvalError> {
        match expr {
            SExp::Number(n) => Ok(Value::Number(*n)),
            SExp::String(s) => Ok(Value::String(s.clone())),
            SExp::Atom(name) => {
                self.vars.get(name)
                    .cloned()
                    .ok_or(EvalError::UndefinedVariable {
                        name: name.clone(),
                        position: 0,
                    })
            },
            SExp::List(exprs) => {
                if exprs.is_empty() {
                    return Ok(Value::List(vec![]));
                }
                
                match &exprs[0] {
                    SExp::Atom(op) if op == "+" => {
                        let args: Result<Vec<_>, _> = exprs[1..]
                            .iter()
                            .map(|e| self.eval(e))
                            .collect();
                        let args = args?;
                        
                        let sum = args.iter().try_fold(0i64, |acc, val| {
                            match val {
                                Value::Number(n) => Ok(acc + n),
                                _ => Err(EvalError::TypeError {
                                    expected: "Number".to_string(),
                                    found: format!("{:?}", val),
                                    position: 0,
                                }),
                            }
                        })?;
                        
                        Ok(Value::Number(sum))
                    },
                    _ => Err(EvalError::UndefinedVariable {
                        name: "unknown operator".to_string(),
                        position: 0,
                    }),
                }
            },
        }
    }
}
```

## 📊 性能目標（測定可能）

### Phase 0 完了時の性能基準
- **パース速度**: 1MB/秒以上
- **実行速度**: 1000 expressions/秒以上
- **メモリ使用**: 実行コードサイズの10倍以下
- **起動時間**: 100ms以下
- **エラー検出**: 99%の構文エラーを正確に特定

### 実際の測定方法
```rust
#[cfg(test)]
mod performance_tests {
    use std::time::Instant;
    
    #[test]
    fn benchmark_parsing() {
        let large_file = include_str!("../test_data/large_program.cognos");
        let start = Instant::now();
        let result = parse_program(large_file);
        let duration = start.elapsed();
        
        assert!(result.is_ok());
        assert!(duration.as_secs_f64() < 1.0); // 1秒以内
    }
}
```

## 🔄 継続的インテグレーション

### GitHub Actions設定
```yaml
name: Cognos CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
    - name: Run tests
      run: cargo test --verbose
    - name: Check formatting
      run: cargo fmt -- --check
    - name: Run clippy
      run: cargo clippy -- -D warnings
```

### 品質ゲート
- [ ] 全テスト通過（100%）
- [ ] コードカバレッジ90%以上
- [ ] Clippy警告ゼロ
- [ ] ドキュメントカバレッジ80%以上

## ⚠️ リスクと緩和策

### 技術的リスク
1. **パーサー性能不足**
   - **緩和**: プロファイリングツールで最適化
   - **代替**: tree-sitterなど既存パーサーの検討

2. **メモリ使用量過多**
   - **緩和**: Rustの所有権システム活用
   - **代替**: リファレンスカウンティング（Rc）の制限使用

3. **エラーハンドリング複雑化**
   - **緩和**: 段階的な機能追加
   - **代替**: シンプルなエラーメッセージから開始

### プロジェクト管理リスク
1. **開発遅延**
   - **緩和**: 週次進捗レビュー
   - **代替**: 機能削減による期限遵守

2. **品質低下**
   - **緩和**: 自動テスト強化
   - **代替**: マニュアルテスト追加

## 📋 完了基準（明確な定義）

Phase 0を「完了」と判断する基準：

### 機能要件
- [ ] 基本的なS式プログラムの実行
- [ ] ファイルからのプログラム読み込み
- [ ] REPL環境での対話的実行
- [ ] エラーメッセージの表示

### 品質要件
- [ ] 90%以上のテストカバレッジ
- [ ] メモリリークなし（valgrind検証）
- [ ] 1MBファイルの10秒以内処理
- [ ] 連続1000回実行でクラッシュなし

### ドキュメント要件
- [ ] インストール手順書
- [ ] 言語仕様書（BNF記法）
- [ ] API仕様書
- [ ] チュートリアル（実行例付き）

**この基準を全て満たした時点でPhase 0完了とみなし、Phase 1に進行する。**