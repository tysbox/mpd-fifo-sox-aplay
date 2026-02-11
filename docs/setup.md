# セットアップガイド

## システム構成

```
MPD (Music Player Daemon)
  ↓ FIFO (/tmp/mpd.fifo)
  ↓ 192kHz/32bit/Stereo
run_sox_fifo.sh (SoX処理)
  ├─ FIRフィルター (ノイズ除去・倍音補正)
  ├─ イコライザー (音楽タイプ別・出力デバイス別)
  ├─ 環境エフェクト (リバーブ、コンプレッサー等)
  └─ ゲイン調整
  ↓
aplay (ALSA)
  ↓
オーディオデバイス (BlueALSA/HDMI/USB-DAC/PC Speaker)
```

## MPD 設定

### FIFO 出力の設定

`/etc/mpd.conf` または `~/.config/mpd/mpd.conf` を編集:

```
audio_output {
    type            "fifo"
    name            "SoX FIFO"
    path            "/tmp/mpd.fifo"
    format          "192000:32:2"
    enabled         "yes"
}
```

### ビットパーフェクト再生の設定

```
# リサンプリング無効化
audio_output_format         "192000:32:2"
samplerate_converter        "internal"

# オーディオバッファ調整
audio_buffer_size           "4096"
buffer_before_play          "20%"
```

### MPD再起動

```bash
sudo systemctl restart mpd
# または
systemctl --user restart mpd
```

## ALSA 設定

### デバイス確認

```bash
aplay -l
```

出力例:
```
card 0: PCH [HDA Intel PCH]
  device 0: ALC269VC Analog [ALC269VC Analog]
  device 3: HDMI 0 [HDMI 0]
card 1: USB [USB Audio Device]
  device 0: USB Audio [USB Audio]
```

### BlueALSA 設定

Bluetooth オーディオデバイスを使用する場合:

```bash
# bluez-alsa サービスの起動
sudo systemctl start bluealsa

# デバイスのペアリング
bluetoothctl
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# scan on
# デバイスが表示されたら
[bluetooth]# pair XX:XX:XX:XX:XX:XX
[bluetooth]# trust XX:XX:XX:XX:XX:XX
[bluetooth]# connect XX:XX:XX:XX:XX:XX
```

### USB DAC 設定

USB DAC は自動検出されます。`run_sox_fifo.sh` が `aplay -l` の出力から USB デバイスを検出します。

優先順位を変更する場合は `/etc/asound.conf`:

```
defaults.pcm.card 1
defaults.ctl.card 1
```

## systemd サービス設定

### サービスファイルの配置

システムワイド:
```bash
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
```

ユーザーサービス:
```bash
mkdir -p ~/.config/systemd/user
cp systemd/*.service ~/.config/systemd/user/
systemctl --user daemon-reload
```

### サービスの有効化

```bash
# システムワイド
sudo systemctl enable run_sox_fifo.service mpd_watcher.service
sudo systemctl start run_sox_fifo.service mpd_watcher.service

# ユーザーサービス
systemctl --user enable run_sox_fifo.service mpd_watcher.service
systemctl --user start run_sox_fifo.service mpd_watcher.service
```

### サービスの自動起動

ユーザーサービスをログイン前から有効化:

```bash
sudo loginctl enable-linger $USER
```

## FIRフィルター

### フィルターファイルの配置

FIRフィルターファイルは `~/bin/` に配置:

```bash
cp firs/*.txt ~/bin/
```

### カスタムフィルターの追加

1. SoX FIR 形式のテキストファイルを作成
2. `~/bin/` に配置
3. `run_sox_fifo.sh` の該当セクションを編集

例:
```bash
case $NOISE_FIR_TYPE in
    light)   NOISE_FIR_FILTER="fir ${FIR_BASE_PATH}noise_fir_light.txt" ;;
    custom)  NOISE_FIR_FILTER="fir ${FIR_BASE_PATH}my_custom_fir.txt" ;;
    ...
esac
```

## パフォーマンス最適化

### CPU ピン留め

高優先度プロセスとして特定CPUコアに固定:

`run_sox_fifo.sh` 内で taskset を有効化:

```bash
PLAY_CMD="| taskset -c 2,3 aplay -D $PLAY_DEVICE ..."
```

### バッファサイズ調整

レイテンシとアンダーラン防止のバランス:

```bash
# run_sox_fifo.sh
aplay ... --buffer-time=600000 --period-time=60000
```

- `buffer-time`: 大きいほど安定、レイテンシ増
- `period-time`: 小さいほど応答性向上、CPU負荷増

### リアルタイム優先度

systemd サービスで RT 優先度を設定:

```ini
[Service]
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=50
LimitRTPRIO=98
LimitMEMLOCK=infinity
```

## GUI 設定

### デスクトップエントリ

`~/.local/share/applications/sox-gui.desktop`:

```ini
[Desktop Entry]
Name=SoX Audio Processor
Comment=高品質オーディオ処理 GUI
Exec=python3 /home/YOUR_USER/bin/sox_gui.py
Icon=audio-card
Terminal=false
Type=Application
Categories=AudioVideo;Audio;
```

### 自動起動

`~/.config/autostart/sox-gui.desktop` にシンボリックリンク:

```bash
mkdir -p ~/.config/autostart
ln -s ~/.local/share/applications/sox-gui.desktop ~/.config/autostart/
```

## 動作確認

### プロセス確認

```bash
ps aux | grep -E "(sox|aplay|mpd)"
```

### FIFO 確認

```bash
ls -l /tmp/mpd.fifo
# 出力: prw-r--r-- 1 user user 0 ...
```

### ログ確認

```bash
# サービスログ
journalctl -u run_sox_fifo.service -f
journalctl -u mpd_watcher.service -f

# ユーザーサービス
journalctl --user -u run_sox_fifo.service -f
```

### オーディオフロー確認

```bash
# MPD 再生
mpc play

# SoXプロセス確認
pgrep -a sox

# aplayプロセス確認
pgrep -a aplay
```

## トラブルシューティング

詳細は [troubleshooting.md](troubleshooting.md) を参照してください。
