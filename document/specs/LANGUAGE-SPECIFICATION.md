# Cognos言語仕様書 v0.1

## 1. 概要
Cognos言語は、AI協調プログラミングのために設計された、S式ベースの制約プログラミング言語です。

## 2. 字句構造

### 2.1 文字セット
- UTF-8エンコーディング
- 大文字小文字を区別

### 2.2 トークン
```
identifier  ::= [a-zA-Z][a-zA-Z0-9-_]*
number      ::= [0-9]+ | [0-9]*\.[0-9]+
string      ::= "([^"\\]|\\.)*"
symbol      ::= '[a-zA-Z][a-zA-Z0-9-_]*
```

### 2.3 コメント
```cognos
; 行コメント
#| ブロック
   コメント |#
```

## 3. 基本構文

### 3.1 S式
```cognos
expression ::= atom | list
atom       ::= identifier | number | string | symbol
list       ::= '(' expression* ')'
```

### 3.2 特殊形式

#### define
```cognos
(define name value)
(define (function-name param1 param2) body)
```

#### let
```cognos
(let ((var1 val1) (var2 val2)) body)
```

#### if
```cognos
(if condition then-expr else-expr)
```

#### cond
```cognos
(cond
  (test1 expr1)
  (test2 expr2)
  (else default-expr))
```

## 4. 型システム

### 4.1 基本型
- `integer`: 整数
- `number`: 実数
- `string`: 文字列
- `boolean`: 真偽値
- `symbol`: シンボル
- `list`: リスト
- `function`: 関数

### 4.2 型定義
```cognos
(type TypeName
  (base-type base)
  (constraints constraint-list))
```

### 4.3 制約
```cognos
(constraints
  (param1 type1)
  (param2 > 0)
  (param3 matches-regex "pattern"))
```

## 5. 関数定義

### 5.1 基本形式
```cognos
(define (function-name param1 param2)
  (constraints
    (param1 integer)
    (param2 string))
  body)
```

### 5.2 ラムダ式
```cognos
(lambda (x y) (+ x y))
```

### 5.3 高階関数
```cognos
(map function list)
(filter predicate list)
(reduce function initial list)
```

## 6. テンプレートシステム

### 6.1 テンプレート定義
```cognos
(template template-name
  (parameters (param1 type1) (param2 type2))
  (constraints constraint-list)
  (verified-properties property-list)
  (implementation body))
```

### 6.2 テンプレート使用
```cognos
(instantiate template-name
  (param1 value1)
  (param2 value2))
```

## 7. 自然言語統合

### 7.1 意図定義
```cognos
(define-intent "Natural language description"
  (parameters param-list)
  (constraints constraint-list)
  (implementation body))
```

### 7.2 AI支援
```cognos
(ai-complete
  "Partial implementation description"
  (context current-context))
```

## 8. 制約プログラミング

### 8.1 制約定義
```cognos
(constraint name
  (variables var-list)
  (formula logical-formula))
```

### 8.2 制約解決
```cognos
(solve
  (variables var-list)
  (constraints constraint-list)
  (objective optimization-goal))
```

## 9. エラー処理

### 9.1 例外
```cognos
(try
  expression
  (catch (error-type error-var)
    handler-expression))
```

### 9.2 アサーション
```cognos
(assert condition error-message)
```

## 10. モジュールシステム

### 10.1 モジュール定義
```cognos
(module module-name
  (export symbol-list)
  (import module-list)
  body)
```

### 10.2 インポート
```cognos
(import module-name)
(import (module-name :only (symbol1 symbol2)))
(import (module-name :as alias))
```

## 11. 標準ライブラリ

### 11.1 算術演算
- `+`, `-`, `*`, `/`: 基本演算
- `mod`, `abs`, `sqrt`: 数学関数
- `sin`, `cos`, `tan`: 三角関数

### 11.2 リスト操作
- `cons`, `car`, `cdr`: 基本操作
- `list`, `append`: リスト構築
- `length`, `reverse`: リスト関数

### 11.3 文字列操作
- `string-append`: 連結
- `string-length`: 長さ
- `substring`: 部分文字列

## 12. 実行モデル

### 12.1 評価戦略
- 正格評価（eager evaluation）
- 左から右への評価順序

### 12.2 スコープ規則
- レキシカルスコープ
- シャドーイング許可

## 13. 将来の拡張

### 13.1 並行処理
- async/await構文
- チャネルベース通信

### 13.2 メタプログラミング
- マクロシステム
- コード生成

### 13.3 型推論
- Hindley-Milner型推論
- 依存型の完全サポート

## 改訂履歴
- v0.1 (2024-01): 初版リリース