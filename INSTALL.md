# インストールガイド

## 前提条件

### 必須パッケージ

```bash
sudo apt update
sudo apt install -y \
    mpd \
    sox \
    python3 \
    python3-tk \
    alsa-utils \
    git
```

### オプション

Bluetooth オーディオを使用する場合:
```bash
sudo apt install -y bluez-alsa-utils
```

## 自動インストール

```bash
git clone https://github.com/yourusername/sox-audio-processor.git
cd sox-audio-processor
chmod +x scripts/install.sh
./scripts/install.sh
```

## 手動インストール

### 1. ファイルの配置

```bash
# ソースファイルをコピー
mkdir -p ~/bin
cp src/sox_gui.py ~/bin/
cp src/run_sox_fifo.sh ~/bin/
cp src/mpd_watcher.sh ~/bin/
chmod +x ~/bin/*.sh ~/bin/sox_gui.py

# FIRフィルターをコピー
cp firs/*.txt ~/bin/
```

### 2. systemd サービスの設定

#### システムワイド (推奨)

```bash
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable run_sox_fifo.service mpd_watcher.service
sudo systemctl start run_sox_fifo.service mpd_watcher.service
```

#### ユーザーサービス

```bash
mkdir -p ~/.config/systemd/user
cp systemd/*.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable run_sox_fifo.service mpd_watcher.service
systemctl --user start run_sox_fifo.service mpd_watcher.service
```

### 3. MPD 設定

`/etc/mpd.conf` または `~/.config/mpd/mpd.conf` に以下を追加:

```
audio_output {
    type            "fifo"
    name            "SoX FIFO"
    path            "/tmp/mpd.fifo"
    format          "192000:32:2"
}
```

MPD を再起動:
```bash
sudo systemctl restart mpd
# または
systemctl --user restart mpd
```

### 4. デフォルト設定ファイル

```bash
cp config/default_config.json ~/.sox_gui_config.json
```

## 動作確認

### サービス状態の確認

```bash
systemctl --user status run_sox_fifo.service
systemctl --user status mpd_watcher.service
```

### FIFO パイプの確認

```bash
ls -l /tmp/mpd.fifo
# 出力例: prw-r--r-- 1 user user 0 Feb 11 17:00 /tmp/mpd.fifo
```

### オーディオ出力テスト

```bash
# MPD で音楽を再生
mpc play

# プロセス確認
ps aux | grep sox
ps aux | grep aplay
```

## パス設定の調整

`~/bin/run_sox_fifo.sh` 内の `FIR_BASE_PATH` を環境に合わせて変更:

```bash
# デフォルト
FIR_BASE_PATH="/home/tysbox/bin/"

# 必要に応じて変更
FIR_BASE_PATH="/home/youruser/bin/"
# または
FIR_BASE_PATH="/usr/local/share/sox-firs/"
```

## アンインストール

```bash
# サービス停止・無効化
sudo systemctl stop run_sox_fifo.service mpd_watcher.service
sudo systemctl disable run_sox_fifo.service mpd_watcher.service

# ファイル削除
sudo rm /etc/systemd/system/run_sox_fifo.service
sudo rm /etc/systemd/system/mpd_watcher.service
sudo systemctl daemon-reload

rm ~/bin/sox_gui.py
rm ~/bin/run_sox_fifo.sh
rm ~/bin/mpd_watcher.sh
rm ~/bin/{noise_fir_*.txt,harmonic_*.txt}
rm ~/.sox_gui_config.json
```

## トラブルシューティング

詳細は [docs/troubleshooting.md](docs/troubleshooting.md) を参照してください。
