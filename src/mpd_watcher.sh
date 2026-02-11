#!/bin/bash
# MPD曲切り替え監視＆自動再起動スクリプト
# ログは /var/log/mpd_watcher.log へ出力

LOGFILE="/home/tysbox/mpd_watcher.log"

# ログファイルがなければ作成
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    chmod 666 "$LOGFILE"
fi

echo "[INFO] mpd_watcher started at $(date)" >> "$LOGFILE"

while true; do
    # 曲切り替えを監視
    mpc idle player
    echo "[INFO] Song change detected at $(date)" >> "$LOGFILE"
    # MPDを再起動
    systemctl restart mpd
    echo "[INFO] MPD restarted at $(date)" >> "$LOGFILE"
    # run_sox_fifoサービスも再起動
    systemctl restart run_sox_fifo.service
    echo "[INFO] run_sox_fifo.service restarted at $(date)" >> "$LOGFILE"
    # 再起動後、少し待つ（例: 2秒）
    sleep 2
    # 連続再起動防止のため、さらに短い待機（例: 1秒）
    sleep 1
    # ループ継続
    # （必要に応じて追加処理可）
done
