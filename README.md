# 🤖 Cognos Development Team - AI最適化議論システム

Cognos言語・OSを真のAI最適化システムにするための専門家チーム議論環境

## 🎯 システム概要

PRESIDENT（社長）がBOSS（マネージャー）を通じて、AI・OS・言語の各専門研究者に議論を促し、真のAI最適化実装案を策定します

### 👥 エージェント構成

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト社長（全体方針決定者）

📊 research-team セッション (4ペイン)  
├── boss: チーム統括マネージャー（議論促進者）
├── ai-researcher: 最先端AI研究者（AI/ML専門家）
├── os-researcher: 最先端OS研究者（カーネル専門家）
└── lang-researcher: 最先端言語研究者（言語設計専門家）
```

## 🚀 クイックスタート

### 0. リポジトリのクローン

```bash
git clone https://github.com/Rih0z/Cognos.git
cd Cognos
cd Claude-Code-Communication
```

### 1. tmux環境構築

⚠️ **注意**: 既存の `research-team` と `president` セッションがある場合は自動的に削除されます。

```bash
./setup.sh
```

### 2. セッションアタッチ

```bash
# 研究チーム確認
tmux attach-session -t research-team

# プレジデント確認（別ターミナルで）
tmux attach-session -t president
```

### 3. Claude Code起動

**手順1: President認証**
```bash
# まずPRESIDENTで認証を実施
tmux send-keys -t president 'claude' C-m
```
認証プロンプトに従って許可を与えてください。

**手順2: Research-team一括起動**
```bash
# 認証完了後、research-teamセッションを一括起動
for i in {0..3}; do tmux send-keys -t research-team:0.$i 'claude' C-m; done
```

### 4. デモ実行

PRESIDENTセッションで直接入力：
```
あなたはpresidentです。指示書に従って
```

## 📜 指示書について

各エージェントの役割別指示書：
- **PRESIDENT**: `instructions/president.md` - プロジェクト社長
- **boss**: `instructions/boss.md` - 議論統括マネージャー
- **ai-researcher**: `instructions/ai-researcher.md` - AI/ML専門家
- **os-researcher**: `instructions/os-researcher.md` - OS/カーネル専門家
- **lang-researcher**: `instructions/lang-researcher.md` - 言語設計専門家

**Claude Code参照**: `CLAUDE.md` でシステム構造を確認

**議論の流れ:**
1. **PRESIDENT**: 「Cognos真のAI最適化議論」をbossに指示
2. **boss**: 各研究者に専門分野からの提案を要求
3. **研究者たち**: 初期提案 → 相互フィードバック → 統合案作成
4. **boss**: 総合レポートをPRESIDENTに提出
5. **PRESIDENT**: 最終実装方針を決定

## 🎬 期待される議論フロー

```
1. PRESIDENT → boss: "Cognos真のAI最適化について総合議論を開始せよ"
2. boss → 各研究者: "あなたは[役割]です。AI最適化の具体案を提出せよ"  
3. 各研究者 → boss: 専門分野からの詳細提案
4. boss → 各研究者: 他研究者の提案を共有し統合案を要求
5. 各研究者 → boss: 統合された実装提案
6. boss → PRESIDENT: "総合レポート：[実装可能な具体案]"
7. PRESIDENT: 最終決定と実装指示
```

## 🔧 手動操作

### agent-send.shを使った送信

```bash
# 基本送信
./agent-send.sh [エージェント名] [メッセージ]

# 例
./agent-send.sh boss "議論を開始してください"
./agent-send.sh ai-researcher "AI観点からの提案です"
./agent-send.sh president "最終決定を行います"

# エージェント一覧確認
./agent-send.sh --list
```

## 🧪 確認・デバッグ

### ログ確認

```bash
# 送信ログ確認
cat logs/send_log.txt

# 特定エージェントのログ
grep "boss1" logs/send_log.txt

# レポートファイル確認
ls -la ./tmp/*_report.txt
```

### セッション状態確認

```bash
# セッション一覧
tmux list-sessions

# ペイン一覧
tmux list-panes -t research-team
tmux list-panes -t president
```

## 🔄 環境リセット

```bash
# セッション削除
tmux kill-session -t research-team
tmux kill-session -t president

# 作業ファイル削除
rm -f ./tmp/*_done.txt
rm -f ./tmp/*_report.txt

# 再構築（自動クリア付き）
./setup.sh
```

---

## 📄 ライセンス

このプロジェクトは[MIT License](LICENSE)の下で公開されています。

## 🤝 コントリビューション

プルリクエストやIssueでのコントリビューションを歓迎いたします！

---

🚀 **Cognos AI最適化の未来を創造してください！** 🤖✨ 