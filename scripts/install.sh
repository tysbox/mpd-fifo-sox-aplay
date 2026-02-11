#!/bin/bash

set -e

echo "=================================="
echo "SoX Audio Processor インストーラー"
echo "=================================="
echo

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

info "プロジェクトルート: $PROJECT_ROOT"

# 依存パッケージのチェック
info "依存パッケージを確認中..."

REQUIRED_PKGS="mpd sox python3 alsa-utils"
MISSING_PKGS=""

for pkg in $REQUIRED_PKGS; do
    if ! command -v "$pkg" &> /dev/null && ! dpkg -l | grep -q "^ii  $pkg "; then
        MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
done

if [ -n "$MISSING_PKGS" ]; then
    error "以下のパッケージがインストールされていません:$MISSING_PKGS"
    echo
    echo "以下のコマンドでインストールしてください:"
    echo "  sudo apt install -y$MISSING_PKGS"
    exit 1
fi

info "✓ すべての必須パッケージがインストールされています"

# Python Tkinter のチェック
if ! python3 -c "import tkinter" 2>/dev/null; then
    warn "python3-tk がインストールされていません"
    echo "以下のコマンドでインストールしてください:"
    echo "  sudo apt install -y python3-tk"
    exit 1
fi

info "✓ Python Tkinter が利用可能です"

# インストール先ディレクトリの作成
BIN_DIR="$HOME/bin"
info "インストール先: $BIN_DIR"

mkdir -p "$BIN_DIR"

# ソースファイルのコピー
info "ソースファイルをコピー中..."
cp -v "$PROJECT_ROOT/src/sox_gui.py" "$BIN_DIR/"
cp -v "$PROJECT_ROOT/src/run_sox_fifo.sh" "$BIN_DIR/"
cp -v "$PROJECT_ROOT/src/mpd_watcher.sh" "$BIN_DIR/"

# 実行権限の付与
chmod +x "$BIN_DIR/sox_gui.py"
chmod +x "$BIN_DIR/run_sox_fifo.sh"
chmod +x "$BIN_DIR/mpd_watcher.sh"

info "✓ ソースファイルのコピー完了"

# FIRフィルターのコピー
info "FIRフィルターをコピー中..."
cp -v "$PROJECT_ROOT/firs"/*.txt "$BIN_DIR/"

info "✓ FIRフィルターのコピー完了"

# run_sox_fifo.sh 内のパスを更新
info "FIR_BASE_PATH を更新中..."
sed -i "s|FIR_BASE_PATH=\"/home/tysbox/bin/\"|FIR_BASE_PATH=\"$BIN_DIR/\"|g" "$BIN_DIR/run_sox_fifo.sh"

info "✓ パス設定を更新しました"

# デフォルト設定ファイルのコピー
CONFIG_FILE="$HOME/.sox_gui_config.json"
if [ -f "$CONFIG_FILE" ]; then
    warn "設定ファイルが既に存在します: $CONFIG_FILE"
    echo "バックアップを作成しますか? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
        info "✓ バックアップを作成しました"
    fi
else
    info "デフォルト設定ファイルをコピー中..."
    cp -v "$PROJECT_ROOT/config/default_config.json" "$CONFIG_FILE"
    info "✓ 設定ファイルを作成しました"
fi

# systemd サービスのインストール
echo
echo "systemd サービスをインストールしますか?"
echo "1) システムワイド (/etc/systemd/system/) - 推奨"
echo "2) ユーザーサービス (~/.config/systemd/user/)"
echo "3) スキップ"
read -p "選択 [1-3]: " service_choice

case $service_choice in
    1)
        info "システムワイドサービスとしてインストール中..."
        sudo cp -v "$PROJECT_ROOT/systemd"/*.service /etc/systemd/system/
        
        # サービスファイル内のユーザー名を更新
        sudo sed -i "s|/home/tysbox/|$HOME/|g" /etc/systemd/system/run_sox_fifo.service
        sudo sed -i "s|/home/tysbox/|$HOME/|g" /etc/systemd/system/mpd_watcher.service
        
        sudo systemctl daemon-reload
        
        echo "サービスを有効化して起動しますか? [y/N]"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            sudo systemctl enable run_sox_fifo.service mpd_watcher.service
            sudo systemctl start run_sox_fifo.service mpd_watcher.service
            info "✓ サービスを有効化・起動しました"
        fi
        ;;
    2)
        info "ユーザーサービスとしてインストール中..."
        mkdir -p "$HOME/.config/systemd/user"
        cp -v "$PROJECT_ROOT/systemd"/*.service "$HOME/.config/systemd/user/"
        
        # サービスファイル内のパスを更新
        sed -i "s|/home/tysbox/|$HOME/|g" "$HOME/.config/systemd/user/run_sox_fifo.service"
        sed -i "s|/home/tysbox/|$HOME/|g" "$HOME/.config/systemd/user/mpd_watcher.service"
        
        systemctl --user daemon-reload
        
        echo "サービスを有効化して起動しますか? [y/N]"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            systemctl --user enable run_sox_fifo.service mpd_watcher.service
            systemctl --user start run_sox_fifo.service mpd_watcher.service
            info "✓ サービスを有効化・起動しました"
        fi
        ;;
    *)
        info "サービスのインストールをスキップしました"
        ;;
esac

# MPD 設定の確認
echo
info "MPD 設定を確認してください:"
echo
echo "以下の設定が /etc/mpd.conf または ~/.config/mpd/mpd.conf に必要です:"
echo
echo "audio_output {"
echo "    type            \"fifo\""
echo "    name            \"SoX FIFO\""
echo "    path            \"/tmp/mpd.fifo\""
echo "    format          \"192000:32:2\""
echo "}"
echo

# インストール完了
echo
echo "========================================="
info "✓ インストールが完了しました!"
echo "========================================="
echo
echo "次のステップ:"
echo "1. MPD の設定を確認・更新"
echo "2. MPD を再起動: sudo systemctl restart mpd"
echo "3. GUI を起動: python3 ~/bin/sox_gui.py"
echo
echo "サービス状態の確認:"
if [ "$service_choice" = "1" ]; then
    echo "  sudo systemctl status run_sox_fifo.service"
    echo "  sudo systemctl status mpd_watcher.service"
elif [ "$service_choice" = "2" ]; then
    echo "  systemctl --user status run_sox_fifo.service"
    echo "  systemctl --user status mpd_watcher.service"
fi
echo
