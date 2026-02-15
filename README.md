# SoX Audio Processor

高品質オーディオ処理システム - MPD + SoX + FIRフィルター + GUI

## 概要

このシステムは、Music Player Daemon (MPD) の出力を SoX (Sound eXchange) でリアルタイム処理し、高品質なオーディオ再生を実現します。

### 主な機能

- **FIRフィルター処理**: ノイズ除去と倍音補正のための複数のFIRフィルター
- **ダイナミック・ゲイン補正**: FIRフィルタ適用状況に応じた自動音量補正 (+4dB / +8dB)
- **クロスフィード処理**: bs2b によるヘッドホンリスニングの自然化 (ecasound 統合)
- **イコライザー**: 音楽ジャンル別・再生デバイス別の詳細設定 (`Tube-Warmth`, `Crystal-Clarity` など)
- **環境エフェクト**: コンサートホール、スタジオ、ジャズクラブなどの空間シミュレーション
- **出力デバイス切り替え**: BlueALSA、HDMI、USB-DAC、PC スピーカーなど
- **GUI制御**: Python/Tkinter による直感的な設定インターフェース
- **systemd統合**: サービスとして自動起動・管理

## システム要件

- Linux (Debian/Ubuntu系推奨)
- MPD (Music Player Daemon)
- SoX (Sound eXchange)
- ecasound (クロスフィード処理用)
- bs2b-ladspa (クロスフィード用プラグイン)
- Python 3.6+
- ALSA
- systemd

## インストール

詳細は [INSTALL.md](INSTALL.md) を参照してください。

```bash
git clone https://github.com/yourusername/sox-audio-processor.git
cd sox-audio-processor
chmod +x scripts/install.sh
./scripts/install.sh
```

## 使用方法

### GUI起動

```bash
python3 ~/bin/sox_gui.py
```

GUI から以下を設定できます：
- **出力デバイス** (Output Device)
- **FIRフィルター** (ノイズ除去・倍音補正)
- **イコライザー設定** (音楽ジャンル別)
- **環境エフェクト** (ホール・スタジオシミュレーション)
- **ゲイン調整** (マスター音量)

### 出力デバイスの選択

GUIで以下のデバイスを切り替え可能です：

- **Bluetooth (BlueALSA)**: `bluealsa` - LDAC コーデック対応
- **PC スピーカー**: `hw:1,0` など (ALSA hw: 指定)
- **HDMI**: `hw:0,0` など
- **USB-DAC**: `USB-DAC` (自動検出)
- **汎用**: `plug:default` (フォーマット自動変換)

> **注**: GUI で出力デバイスを変更すると、`run_sox_fifo.service` が自動的に再起動して新しいデバイスで再生を開始します。

### サービス制御

```bash
# 起動
sudo systemctl start run_sox_fifo.service
sudo systemctl start mpd_watcher.service

# 停止
sudo systemctl stop run_sox_fifo.service
sudo systemctl stop mpd_watcher.service

# 自動起動有効化
sudo systemctl enable run_sox_fifo.service
sudo systemctl enable mpd_watcher.service

# ステータス確認
sudo systemctl status run_sox_fifo.service
sudo systemctl status mpd_watcher.service
```

## 設定

設定は `~/.sox_gui_config.json` に保存されます。

### FIRフィルター

- **ノイズ除去**: light, medium, strong, default
- **倍音補正**: dead, base, med, high, dynamic
  - **ダイナミック・ゲイン補正機能**:
    - Noise/Harmonic どちらか片方のFIR適用時: **+4dB**
    - 両方のFIR適用時: **+8dB**
    - これにより、FIRフィルタによる減衰を自動的に補正し、SNRを最適化します。

### 音楽タイプ

jazz, classical, electronic, vocal, none

### 出力 EQ プロファイル

- **Tube-Warmth**: 真空管アンプのような温かみと艶を付加 (Overdrive処理)
- **Crystal-Clarity**: 高域の透明感と解像度を強調
- **Monitor-Sim**: スタジオモニターのようなフラットで明瞭なサウンド
- その他: studio-monitors, JBL-Speakers, planar-magnetic, bt-earphones

### クロスフィード (bs2b)

ヘッドホンでの長時間リスニング時の疲労を軽減する、自然な音の広がりを実現します。
- `default`, `cmoy`, `jmeier` のプリセットを選択可能。

### 出力デバイス

システムで利用可能なデバイスを自動検出し、以下に対応しています：

| デバイスタイプ | 設定値 | 説明 |
|---|---|---|
| **Bluetooth** | `bluealsa` | BlueALSA を経由したワイヤレス出力 (LDAC対応) |
| **ALSA hw** | `hw:0,0`, `hw:1,0` など | ダイレクト ALSA デバイス指定 |
| **ALSA plug** | `plug:bluealsa`, `plug:default` | フォーマット自動変換ラッパー |
| **USB-DAC** | `USB-DAC` | USB DAC の自動検出と設定 |

**注意**: 
- Bluetooth は接続を確立してから選択してください
- USB-DAC は `USB-DAC` を選択すると自動検出します
- デバイスが存在しない場合は自動的に `plug:default` にフォールバック

## ドキュメント

- [セットアップガイド](docs/setup.md)
- [使用方法](docs/usage.md)
- [トラブルシューティング](docs/troubleshooting.md)

## ライセンス

MIT License

## 作者

tysbox

## 貢献

プルリクエストを歓迎します。大きな変更の場合は、まずissueを開いて変更内容を議論してください。
