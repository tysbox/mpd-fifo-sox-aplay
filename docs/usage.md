# 使用方法

## GUI の起動

```bash
python3 ~/bin/sox_gui.py
```

## GUI インターフェース

### メインタブ

#### Music Type (音楽タイプ)
音楽ジャンルに応じた入力イコライザーを選択:

- **jazz**: 80Hz/300Hz/1.5kHz/3kHz/7kHz の調整
- **classical**: クラシック音楽向けの繊細なEQ
- **electronic**: 低域強調、電子音楽向け
- **vocal**: ボーカル帯域 (2.5kHz) を強調
- **none**: イコライザーなし (デフォルトゲイン -3dB)

#### Effects Type (環境エフェクト)
空間シミュレーション:

- **Viena-Symphony-Hall**: 大ホールの豊かな残響
- **Suntory-Music-Hall**: 中規模ホールの暖かい音響
- **NewMorning-JazzClub**: ジャズクラブの親密な空間
- **Wembley-Studium**: スタジアムの広大なエコー
- **AbbeyRoad-Studio**: スタジオの正確な音響
- **vinyl**: アナログレコードの質感
- **none**: エフェクトなし

#### EQ Output Type (出力デバイス別EQ)
再生デバイスの特性に応じた補正:

- **studio-monitors**: スタジオモニター向け
- **JBL-Speakers**: JBL スピーカー向け
- **planar-magnetic**: 平面磁界型ヘッドフォン向け
- **bt-earphones**: Bluetooth イヤホン向け
- **med-harmonics**: 中程度の倍音強調
- **high-harmonics**: EQなし (倍音FIRのみ)
- **none**: 出力EQなし

### Gain/Output タブ

#### Gain (ゲイン調整)
-20dB ~ +20dB の範囲で調整可能。

**重要**: FIRフィルター適用時は自動的に +5dB 補正されます。
- 例: Gain=0, FIR適用 → 実際のゲイン=+5dB

#### Output Device (出力デバイス)
オーディオ出力先を選択:

- **BlueALSA**: Bluetooth オーディオデバイス
- **hw:0, hw:1, hw:2, hw:3**: ALSA ハードウェアデバイス
  - hw:0: 通常オンボードオーディオ (Analog/HDMI)
  - hw:1-3: 追加のオーディオカード
- **USB-DAC**: USB DACを自動検出
- **PC Speakers (hw:0)**: PCスピーカー (Intel HDA)

#### Output Method
- **aplay**: ALSA経由で再生 (推奨)
- **soxplay**: SoX の play コマンド使用

### FIR Filters タブ

#### Noise FIR Type (ノイズ除去フィルター)
デジタルノイズ除去の強度:

- **light**: 軽度のノイズ除去
- **medium**: 中程度のノイズ除去
- **strong**: 強力なノイズ除去
- **default**: 標準設定
- **off**: フィルターなし

#### Harmonic FIR Type (倍音補正フィルター)
倍音成分の調整:

- **dead**: デッドな空間、倍音抑制
- **base**: ベース倍音補正
- **med**: 中程度の倍音強調
- **high**: 高次倍音強調
- **dynamic**: ダイナミックな倍音処理
- **off**: フィルターなし

## CLI からの制御

### サービス管理

```bash
# 状態確認
systemctl --user status run_sox_fifo.service

# 起動
systemctl --user start run_sox_fifo.service

# 停止
systemctl --user stop run_sox_fifo.service

# 再起動
systemctl --user restart run_sox_fifo.service

# ログ表示
journalctl --user -u run_sox_fifo.service -f
```

### MPD 操作

```bash
# 再生
mpc play

# 停止
mpc stop

# 次の曲
mpc next

# 前の曲
mpc prev

# 音量調整 (MPD側)
mpc volume 80
```

### 設定ファイルの直接編集

`~/.sox_gui_config.json`:

```json
{
  "music_type": "jazz",
  "effects_type": "NewMorning-JazzClub",
  "eq_output_type": "studio-monitors",
  "gain": "0",
  "noise_fir_type": "medium",
  "harmonic_fir_type": "med",
  "output_method": "aplay",
  "output_device": "BlueALSA",
  "fade_ms": "150"
}
```

編集後、サービス再起動:
```bash
systemctl --user restart run_sox_fifo.service
```

## 設定のベストプラクティス

### ジャズ / アコースティック

```
Music Type: jazz
Effects Type: NewMorning-JazzClub
EQ Output: studio-monitors
Noise FIR: medium
Harmonic FIR: med
Gain: 0
```

### クラシック / オーケストラ

```
Music Type: classical
Effects Type: Viena-Symphony-Hall
EQ Output: planar-magnetic
Noise FIR: light
Harmonic FIR: base
Gain: +3
```

### エレクトロニック / EDM

```
Music Type: electronic
Effects Type: Wembley-Studium
EQ Output: bt-earphones
Noise FIR: strong
Harmonic FIR: dynamic
Gain: -3
```

### ボーカル / ポップス

```
Music Type: vocal
Effects Type: AbbeyRoad-Studio
EQ Output: studio-monitors
Noise FIR: medium
Harmonic FIR: med
Gain: 0
```

### アナログ風サウンド

```
Music Type: none
Effects Type: vinyl
EQ Output: JBL-Speakers
Noise FIR: off
Harmonic FIR: high
Gain: +2
```

## トラブルシューティング

### GUI が起動しない

```bash
# Python Tkinter の確認
python3 -c "import tkinter"

# エラーログ確認
python3 ~/bin/sox_gui.py 2>&1 | tee sox_gui.log
```

### 設定が反映されない

1. GUI で「Apply」ボタンをクリック
2. サービスを再起動:
   ```bash
   systemctl --user restart run_sox_fifo.service
   ```

### 音が出ない

[troubleshooting.md](troubleshooting.md) を参照してください。

## ログとデバッグ

### GUI ログ

```bash
tail -f ~/.sox_gui.log
```

### サービスログ

```bash
journalctl --user -u run_sox_fifo.service -n 100
journalctl --user -u mpd_watcher.service -n 100
```

### SoX コマンド確認

`run_sox_fifo.sh` はコマンドラインを出力します:

```bash
journalctl --user -u run_sox_fifo.service | grep "Executing Sox chain"
```

### プロセス監視

```bash
watch -n 1 'ps aux | grep -E "(sox|aplay|mpd)"'
```

## パフォーマンスモニタリング

### CPU 使用率

```bash
top -p $(pgrep -d',' sox)
```

### メモリ使用量

```bash
ps aux | grep sox | awk '{print $6}'
```

### オーディオバッファ状態

```bash
# ALSA バッファ情報
cat /proc/asound/card0/pcm0p/sub0/hw_params
```

## 高度な設定

### カスタム FIR フィルター

1. SoX FIR 形式のフィルターファイルを作成
2. `~/bin/` に配置
3. `run_sox_fifo.sh` を編集してケースを追加
4. GUI にオプション追加 (sox_gui.py)

### エフェクトチェーンのカスタマイズ

`run_sox_fifo.sh` の `EFFECT_CHAIN` 構築部分を編集:

```bash
EFFECT_CHAIN="${NOISE_FIR_FILTER} ${EQ_INPUT} ${HARMONIC_FIR_FILTER} ..."
```

### 複数出力デバイスへの同時出力

`run_sox_fifo.sh` で複数の aplay プロセスを起動:

```bash
sox ... - | tee >(aplay -D bluealsa ...) | aplay -D hw:0 ...
```
