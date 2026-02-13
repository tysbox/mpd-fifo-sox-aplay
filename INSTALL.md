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

> **重要**: `mpd.service` の `ExecStartPost` フックは削除してください。以前の設定で `mpd.service.d/runsox-post.conf` が存在する場合は削除します：
> ```bash
> sudo rm -rf /etc/systemd/system/mpd.service.d/runsox-post.conf
> sudo systemctl daemon-reload
> ```
> このファイルがあると、systemd のタイムアウトによって mpd が起動に失敗する可能性があります。

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

### 出力デバイス確認

```bash
# ALSA デバイス一覧
aplay -l
aplay -L

# 現在の設定確認
grep output_device ~/.sox_gui_config.json

# または GUI から確認
python3 ~/bin/sox_gui.py
```

### トラブルシューティング

#### Bluetooth (BlueALSA) で音が出ない

1. Bluetooth デバイスが接続されているか確認:
   ```bash
   bluetoothctl info
   ```

2. BlueALSA が実行中か確認:
   ```bash
   systemctl status bluealsa
   ```

3. BlueALSA PCM が利用可能か確認:
   ```bash
   aplay -L | grep -i blue
   ```

#### 音飛び (Underrun) が発生する

このシステムは以下の対策を既に実装しています：

- **aplay バッファ最適化**: `--buffer-size=65536 --period-size=8192`
- **プロセス優先度**: `nice -n -5` (SoX), `nice -n -10` (aplay)
- **I/O 最適化**: `ionice -c1` (realtime スケジューリング)
- **パイプバッファ**: `ulimit -p 262144` (256KB)

さらに改善する場合：

1. **CPU パフォーマンス確認**:
   ```bash
   watch -n 1 'ps aux | grep -E "(sox|aplay)" | head -2'
   ```

2. **ALSA バッファ設定の確認**:
   ```bash
   cat ~/.asoundrc | grep -E "(period|buffer)"
   ```

3. **Bluetooth レイテンシ確認** (BlueALSA 使用時):
   ```bash
   aplay -D plug:bluealsa --dump-hw-params /dev/zero | grep Period
   ```

4. **BlueALSA デーモンの再起動** (A2DP 品質最適化):
   ```bash
   sudo systemctl restart bluealsa
   ```

#### 指定したデバイスが見つからない

- リポジトリは存在しないデバイスを自動的に `plug:default` にフォールバック
- 実際に利用可能なデバイスを確認してから設定してください

#### 音が歪む・小さい

- FIRフィルタが適用されている場合、自動的に +5dB が加算されます
- GUI でゲイン値を調整して音量を最適化してください

## パス設定の調整

### FIR フィルターパス

`~/bin/run_sox_fifo.sh` 内の `FIR_BASE_PATH` を環境に合わせて変更:

```bash
# デフォルト
FIR_BASE_PATH="/home/tysbox/bin/"

# 必要に応じて変更
FIR_BASE_PATH="/home/youruser/bin/"
# または
FIR_BASE_PATH="/usr/local/share/sox-firs/"
```

> **注**: FIRフィルタが適用されている場合、自動的に +5dB (FIR補正) がゲインに加算されます。

### 出力デバイスの初期設定

`~/.sox_gui_config.json` に `output_device` を設定してください：

```json
{
  "output_device": "hw:1,0",
  ...
}
```

利用可能な値：
- `bluealsa` - Bluetooth (BlueALSA)
- `hw:1,0`, `hw:0,0` など - ALSA ハードウェアデバイス
- `plug:bluealsa` - BlueALSA (プラグイン経由、フォーマット変換有)
- `USB-DAC` - USB DAC (自動検出)
- `plug:default` - デフォルト (フォーマット自動変換)

> **デバイス確認**:
> ```bash
> aplay -l          # 利用可能なデバイス一覧
> aplay -L          # PCM デバイス一覧
> bluetoothctl devices  # ペアリング済み Bluetooth デバイス
> ```

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
