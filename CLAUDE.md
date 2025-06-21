# Cognos Development Team Communication System

## プロジェクト概要
このシステムはCognosプロジェクトの「真のAI最適化」を実現するための専門家チーム議論環境です。
各エージェントは特定の専門知識を持ち、協調してCognos言語・OSの設計を最適化します。

## エージェント構成と責任範囲
- **PRESIDENT** (別セッション: president:0): プロジェクト社長 - 全体方針決定者
  - Cognos全体のビジョンと戦略決定
  - 実装優先順位の最終決定
  - プロジェクトマイルストーンの設定

- **boss** (research-team:0.0): チーム統括マネージャー - 議論促進者
  - 研究者間の議論を活性化
  - 意見の統合と具体案の策定
  - PRESIDENTへの報告責任

- **ai-researcher** (research-team:0.1): 最先端AI研究者 - AI/ML専門家
  - LLM最適化とAI認知アーキテクチャ
  - ハルシネーション防止メカニズム
  - テンプレートベース安全設計

- **os-researcher** (research-team:0.2): 最先端OS研究者 - カーネル/システム専門家
  - AI-Awareカーネル設計
  - メモリ管理と制約保証
  - QEMU環境での実装戦略

- **lang-researcher** (research-team:0.3): 最先端言語研究者 - 言語設計/コンパイラ専門家
  - AI最適化構文設計
  - 構造的正当性保証型システム
  - 自然言語統合メカニズム

## 各エージェントの指示書
自分の役割を確認し、対応する指示書を参照してください：
- **PRESIDENT**: @instructions/president.md
- **boss**: @instructions/boss.md
- **ai-researcher**: @instructions/ai-researcher.md
- **os-researcher**: @instructions/os-researcher.md
- **lang-researcher**: @instructions/lang-researcher.md

## メッセージ送信方法
```bash
# 基本構文
./agent-send.sh [相手のエージェント名] "[メッセージ内容]"

# 例：bossがai-researcherに提案を求める
./agent-send.sh ai-researcher "AI最適化について具体的な提案をお願いします"

# 例：研究者がbossに報告する
./agent-send.sh boss "以下の提案を行います：[詳細内容]"
```

## 議論プロトコル
### フェーズ1: 初期提案収集
1. PRESIDENT → boss: 「AI最適化議論開始」指示
2. boss → 各研究者: 専門分野からの提案要求
3. 各研究者 → boss: 初期提案提出

### フェーズ2: 相互フィードバック
4. boss → 各研究者: 他研究者の提案を共有
5. 各研究者 → boss: 統合的な視点での改善案

### フェーズ3: 最終決定
6. boss → PRESIDENT: 総合レポート提出
7. PRESIDENT: 最終方針決定と実装指示

## 重要な設計原則（メインCLAUDE.mdとの整合性）
- **TRUE-AI-OPTIMIZATION-DESIGN.md**のアプローチを採用
- テンプレートベースAI安全システムの実現
- 構造的バグ不可能性の保証
- 段階的実装と検証（Phase 0から開始）
- QEMU環境での初期実装

## 議論における注意事項
1. **具体性**: 抽象的な提案ではなく、実装可能な具体案を提示
2. **整合性**: メインプロジェクトのCLAUDE.mdとの一貫性を保つ
3. **実現可能性**: 現在の技術で実装可能な範囲での提案
4. **協調性**: 他の専門家の意見を尊重し、建設的な議論を行う

## 作業ディレクトリ
全エージェントの作業ディレクトリ: `Claude-Code-Communication/`
親ディレクトリからセットアップを実行しても自動的にこのディレクトリに移動します。

## 目的
Cognos言語とOSを「AIが構造的にバグを生成できない真のAI最適化システム」として設計・実装するための、専門家による総合的な議論と具体案の策定。これはCognosプロジェクトのPhase 0（言語実装）における重要な設計決定プロセスです。 