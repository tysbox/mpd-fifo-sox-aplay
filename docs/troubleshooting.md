# トラブルシューティング

## 音が出ない

### 1. FIFO パイプの確認

```bash
ls -l /tmp/mpd.fifo
```

期待される出力:
```
prw-r--r-- 1 user user 0 Feb 11 17:00 /tmp/mpd.fifo
```

FIFO が存在しない場合:
```bash
mkfifo /tmp/mpd.fifo
systemctl --user restart run_sox_fifo.service
```

### 2. MPD の状態確認

```bash
systemctl status mpd
# または
systemctl --user status mpd

# MPD ログ
journalctl -u mpd -n 50
```

MPD が FIFO に出力しているか確認:
```bash
mpc play
lsof /tmp/mpd.fifo
```

期待される出力に `mpd` プロセスが含まれること。

### 3. SoX プロセスの確認

```bash
ps aux | grep sox
```

プロセスが実行されていない場合:
```bash
systemctl --user status run_sox_fifo.service
journalctl --user -u run_sox_fifo.service -n 50
```

### 4. aplay プロセスの確認

```bash
ps aux | grep aplay
```

aplay が実行されていない場合、SoX から aplay へのパイプが失敗している可能性があります。

### 5. オーディオデバイスの確認

```bash
aplay -l
```

選択したデバイスが存在するか確認。

BlueALSA の場合:
```bash
systemctl status bluealsa
aplay -L | grep -i blue
```

### 6. ALSA デバイステスト

```bash
speaker-test -D plug:bluealsa -c 2 -t wav
# または
speaker-test -D plughw:CARD=PCH,DEV=0 -c 2 -t wav
```

## 音が途切れる / ノイズが入る

### 1. バッファサイズの調整

`~/bin/run_sox_fifo.sh` を編集:

```bash
# バッファを大きくする
aplay ... --buffer-time=800000 --period-time=80000
```

### 2. CPU 優先度の調整

systemd サービスファイル (`/etc/systemd/system/run_sox_fifo.service`) を編集:

```ini
[Service]
Nice=-10
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=50
```

リロード・再起動:
```bash
sudo systemctl daemon-reload
sudo systemctl restart run_sox_fifo.service
```

### 3. CPU 使用率の確認

```bash
top -p $(pgrep -d',' -f "sox|aplay")
```

CPU が 100% に達している場合:
- FIR フィルターを軽くする（off にする）
- リサンプリングレートを下げる (192kHz → 96kHz)
- エフェクトを減らす

### 4. システムログの確認

```bash
dmesg | grep -i xrun
journalctl -k | grep -i audio
```

ALSA xrun (バッファアンダーラン) が発生している場合はバッファ調整が必要。

## GUI が起動しない

### 1. Python Tkinter の確認

```bash
python3 -c "import tkinter; tkinter.Tk()"
```

エラーが出る場合:
```bash
sudo apt install -y python3-tk
```

### 2. 依存パッケージの確認

```bash
python3 ~/bin/sox_gui.py
```

エラーメッセージを確認し、不足しているモジュールをインストール。

### 3. ログファイルの確認

```bash
tail -f ~/.sox_gui.log
```

### 4. 設定ファイルの破損

```bash
# 設定ファイルのバックアップ
mv ~/.sox_gui_config.json ~/.sox_gui_config.json.bak

# デフォルト設定で起動
python3 ~/bin/sox_gui.py
```

## 設定が保存されない

### 1. ファイルパーミッションの確認

```bash
ls -l ~/.sox_gui_config.json
ls -l ~/bin/run_sox_fifo.sh
```

書き込み権限がない場合:
```bash
chmod 644 ~/.sox_gui_config.json
chmod 755 ~/bin/run_sox_fifo.sh
```

### 2. ディスク容量の確認

```bash
df -h ~
```

### 3. GUI ログの確認

```bash
grep -i error ~/.sox_gui.log
```

## サービスが起動しない

### 1. サービス状態の確認

```bash
systemctl --user status run_sox_fifo.service
journalctl --user -u run_sox_fifo.service -n 100
```

### 2. スクリプトの構文チェック

```bash
bash -n ~/bin/run_sox_fifo.sh
```

エラーがある場合、オリジナルから復元:
```bash
cp ~/bin/run_sox_fifo.sh.original ~/bin/run_sox_fifo.sh
```

### 3. サービスファイルの確認

```bash
systemctl --user cat run_sox_fifo.service
```

パスが正しいか確認。

### 4. 依存関係の確認

```bash
systemctl --user list-dependencies run_sox_fifo.service
```

## Bluetooth (BlueALSA) 接続の問題

### 1. bluealsa サービスの確認

```bash
systemctl status bluealsa
```

実行されていない場合:
```bash
sudo systemctl start bluealsa
sudo systemctl enable bluealsa
```

### 2. Bluetooth デバイスの接続確認

```bash
bluetoothctl
[bluetooth]# show
[bluetooth]# devices
[bluetooth]# info XX:XX:XX:XX:XX:XX
```

### 3. BlueALSA デバイスの確認

```bash
aplay -L | grep -i blue
bluealsa-aplay -L
```

### 4. 手動接続テスト

```bash
bluealsa-aplay XX:XX:XX:XX:XX:XX
```

### 5. ペアリングのやり直し

```bash
bluetoothctl
[bluetooth]# remove XX:XX:XX:XX:XX:XX
[bluetooth]# scan on
[bluetooth]# pair XX:XX:XX:XX:XX:XX
[bluetooth]# trust XX:XX:XX:XX:XX:XX
[bluetooth]# connect XX:XX:XX:XX:XX:XX
```

## FIR フィルターが効かない

### 1. フィルターファイルの存在確認

```bash
ls -l ~/bin/noise_fir_*.txt
ls -l ~/bin/harmonic_*.txt
```

### 2. パス設定の確認

`~/bin/run_sox_fifo.sh` の `FIR_BASE_PATH` を確認:

```bash
grep FIR_BASE_PATH ~/bin/run_sox_fifo.sh
```

正しいパスに設定されているか確認。

### 3. フィルター選択の確認

```bash
journalctl --user -u run_sox_fifo.service | grep "Executing Sox chain"
```

出力されたコマンドに `fir /path/to/filter.txt` が含まれているか確認。

### 4. SoX FIR 形式の確認

フィルターファイルを開いて形式を確認:

```bash
head ~/bin/noise_fir_default.txt
```

SoX FIR 形式:
```
0.001
0.002
0.003
...
```

## 音質の問題

### 1. サンプルレート不一致

MPD 設定と SoX 設定のサンプルレートを確認:

MPD (`/etc/mpd.conf`):
```
format "192000:32:2"
```

SoX (`run_sox_fifo.sh`):
```bash
INPUT_OPTS="-t raw -r 192000 -e signed -b 32 -c 2"
```

### 2. ビット深度の確認

32bit が正しく処理されているか確認。

### 3. ディザーの調整

`run_sox_fifo.sh` のディザー設定:

```bash
# 高品質ディザー
dither -S

# ディザーなし (テスト用)
# dither コマンドを削除
```

### 4. リサンプリング品質

```bash
# 最高品質
rate -v -s -M 192k

# 高速 (品質低下)
rate -v -L 192k
```

## パフォーマンスの問題

### 1. CPU 使用率が高い

```bash
top -p $(pgrep -d',' -f sox)
```

対策:
- FIR フィルターを軽量化または無効化
- エフェクトを減らす
- リサンプリングを無効化（入力と出力が同じレートの場合）

### 2. メモリ使用量が多い

```bash
ps aux | grep sox | awk '{print $6 " KB"}'
```

大きなバッファを使用している場合、サイズを調整。

### 3. ディスク I/O

```bash
iostat -x 1
```

ログファイルへの書き込みが多い場合、ログレベルを下げる。

## ログ収集 (サポート依頼時)

問題報告時に以下の情報を収集:

```bash
# システム情報
uname -a
lsb_release -a

# パッケージバージョン
dpkg -l | grep -E "mpd|sox|alsa"

# デバイス情報
aplay -l
aplay -L

# サービス状態
systemctl --user status run_sox_fifo.service
systemctl --user status mpd_watcher.service

# ログ
journalctl --user -u run_sox_fifo.service -n 100 > /tmp/sox_service.log
tail -100 ~/.sox_gui.log > /tmp/sox_gui.log

# 設定
cat ~/.sox_gui_config.json > /tmp/sox_config.json
grep -A 10 "audio_output" /etc/mpd.conf > /tmp/mpd_config.txt

# プロセス情報
ps aux | grep -E "(sox|aplay|mpd)" > /tmp/processes.txt
```

## よくある質問

### Q: FIR を変更しても音質が変わらない

A: サービスの再起動が必要です:
```bash
systemctl --user restart run_sox_fifo.service
```

### Q: ゲインを上げると音が歪む

A: クリッピングが発生しています。ゲインを下げるか、入力音量を下げてください。

### Q: 複数のオーディオデバイスに同時出力したい

A: `run_sox_fifo.sh` で `tee` を使用:
```bash
sox ... - | tee >(aplay -D device1) | aplay -D device2
```

### Q: MPD を使わずに使用できるか

A: 可能です。任意のアプリケーションの出力を `/tmp/mpd.fifo` にリダイレクトしてください。

### Q: Windows/Mac でも使えるか

A: 現在 Linux 専用です。WSL2 (Windows) や Docker で動作する可能性があります。
