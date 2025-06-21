#!/bin/bash

# 🚀 Cognos AI-Native Language & OS Development Team 環境構築
# AI最適化言語・OS開発のための専門家チーム環境

set -e  # エラー時に停止

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

echo "🤖 Cognos Development Team 環境構築"
echo "==========================================="
echo ""

# STEP 1: 既存セッションクリーンアップ
log_info "🧹 既存セッションクリーンアップ開始..."

tmux kill-session -t research-team 2>/dev/null && log_info "research-teamセッション削除完了" || log_info "research-teamセッションは存在しませんでした"
tmux kill-session -t president 2>/dev/null && log_info "presidentセッション削除完了" || log_info "presidentセッションは存在しませんでした"

# 作業ファイルクリア
mkdir -p ./tmp
rm -f ./tmp/*_done.txt 2>/dev/null && log_info "既存の完了ファイルをクリア" || log_info "完了ファイルは存在しませんでした"
rm -f ./tmp/*_report.txt 2>/dev/null && log_info "既存のレポートファイルをクリア" || log_info "レポートファイルは存在しませんでした"

log_success "✅ クリーンアップ完了"
echo ""

# STEP 2: research-teamセッション作成（4ペイン：boss + 3研究者）
log_info "📺 research-teamセッション作成開始 (4ペイン)..."

# 最初のペイン作成
tmux new-session -d -s research-team -n "experts"

# 2x2グリッド作成（合計4ペイン）
tmux split-window -h -t "research-team:0"      # 水平分割（左右）
tmux select-pane -t "research-team:0.0"
tmux split-window -v                            # 左側を垂直分割
tmux select-pane -t "research-team:0.2"
tmux split-window -v                            # 右側を垂直分割

# ペインタイトル設定
log_info "ペインタイトル設定中..."
PANE_TITLES=("boss" "ai-researcher" "os-researcher" "lang-researcher")
PANE_COLORS=("\033[1;31m" "\033[1;36m" "\033[1;33m" "\033[1;32m")  # 赤、シアン、黄、緑

for i in {0..3}; do
    tmux select-pane -t "research-team:0.$i" -T "${PANE_TITLES[$i]}"
    
    # 作業ディレクトリ設定（スクリプトの場所に移動）
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    tmux send-keys -t "research-team:0.$i" "cd $SCRIPT_DIR" C-m
    
    # カラープロンプト設定
    tmux send-keys -t "research-team:0.$i" "export PS1='(${PANE_COLORS[$i]}${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    
    # ウェルカムメッセージ
    case $i in
        0) tmux send-keys -t "research-team:0.$i" "echo '=== Boss - チーム統括マネージャー ==='" C-m
           tmux send-keys -t "research-team:0.$i" "echo '全研究者の議論を促進し、AI最適化の実現を導く'" C-m ;;
        1) tmux send-keys -t "research-team:0.$i" "echo '=== AI Researcher - 最先端AI研究者 ==='" C-m
           tmux send-keys -t "research-team:0.$i" "echo 'AI/ML技術とLLM最適化の専門家'" C-m ;;
        2) tmux send-keys -t "research-team:0.$i" "echo '=== OS Researcher - 最先端OS研究者 ==='" C-m
           tmux send-keys -t "research-team:0.$i" "echo 'カーネル設計とシステムアーキテクチャの専門家'" C-m ;;
        3) tmux send-keys -t "research-team:0.$i" "echo '=== Language Researcher - 最先端言語研究者 ==='" C-m
           tmux send-keys -t "research-team:0.$i" "echo 'プログラミング言語設計とコンパイラの専門家'" C-m ;;
    esac
done

log_success "✅ research-teamセッション作成完了"
echo ""

# STEP 3: presidentセッション作成（1ペイン）
log_info "👑 presidentセッション作成開始..."

tmux new-session -d -s president
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
tmux send-keys -t president "cd $SCRIPT_DIR" C-m
tmux send-keys -t president "export PS1='(\[\033[1;35m\]PRESIDENT\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
tmux send-keys -t president "echo '=== PRESIDENT - プロジェクト社長 ==='" C-m
tmux send-keys -t president "echo 'Cognos言語&OS全体方針の決定者'" C-m
tmux send-keys -t president "echo '================================'" C-m

log_success "✅ presidentセッション作成完了"
echo ""

# STEP 4: 環境確認・表示
log_info "🔍 環境確認中..."

echo ""
echo "📊 セットアップ結果:"
echo "==================="

# tmuxセッション確認
echo "📺 Tmux Sessions:"
tmux list-sessions
echo ""

# ペイン構成表示
echo "📋 ペイン構成:"
echo "  research-teamセッション（4ペイン）:"
echo "    Pane 0: boss            (チーム統括マネージャー)"
echo "    Pane 1: ai-researcher   (最先端AI研究者)"
echo "    Pane 2: os-researcher   (最先端OS研究者)"
echo "    Pane 3: lang-researcher (最先端言語研究者)"
echo ""
echo "  presidentセッション（1ペイン）:"
echo "    Pane 0: PRESIDENT (プロジェクト社長)"

echo ""
log_success "🎉 Cognos開発チーム環境セットアップ完了！"
echo ""
echo "📋 次のステップ:"
echo "  1. 🔗 セッションアタッチ:"
echo "     tmux attach-session -t research-team   # 研究チーム確認"
echo "     tmux attach-session -t president       # プレジデント確認"
echo ""
echo "  2. 🤖 Claude Code起動:"
echo "     # 手順1: President認証"
echo "     tmux send-keys -t president 'claude' C-m"
echo "     # 手順2: 認証後、research-team一括起動"
echo "     for i in {0..3}; do tmux send-keys -t research-team:0.\$i 'claude' C-m; done"
echo ""
echo "  3. 📜 指示書確認:"
echo "     PRESIDENT: instructions/president.md"
echo "     boss: instructions/boss.md"
echo "     ai-researcher: instructions/ai-researcher.md"
echo "     os-researcher: instructions/os-researcher.md"
echo "     lang-researcher: instructions/lang-researcher.md"
echo "     システム構造: CLAUDE.md"
echo ""
echo "  4. 🎯 開発開始: PRESIDENTに「あなたはpresidentです。指示書に従って」と入力" 