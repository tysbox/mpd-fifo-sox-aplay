# SoX Audio Processor

高品質オーディオ処理システム - MPD + SoX + FIRフィルター + GUI

## 概要

このシステムは、Music Player Daemon (MPD) の出力を SoX (Sound eXchange) でリアルタイム処理し、高品質なオーディオ再生を実現します。

### 主な機能

- **FIRフィルター処理**: ノイズ除去と倍音補正のための複数のFIRフィルター
- **イコライザー**: 音楽ジャンル別・再生デバイス別のEQ設定
- **環境エフェクト**: コンサートホール、スタジオ、ジャズクラブなどの空間シミュレーション
- **出力デバイス切り替え**: BlueALSA、HDMI、USB-DAC、PC スピーカーなど
- **ゲイン調整**: FIR適用時の自動+5dBゲイン補正
- **GUI制御**: Python/Tkinter による直感的な設定インターフェース
- **systemd統合**: サービスとして自動起動・管理

## システム要件

- Linux (Debian/Ubuntu系推奨)
- MPD (Music Player Daemon)
- SoX (Sound eXchange)
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

### サービス制御

```bash
# 起動
systemctl --user start run_sox_fifo.service
systemctl --user start mpd_watcher.service

# 停止
systemctl --user stop run_sox_fifo.service
systemctl --user stop mpd_watcher.service

# 自動起動有効化
systemctl --user enable run_sox_fifo.service
systemctl --user enable mpd_watcher.service
```

## 設定

設定は `~/.sox_gui_config.json` に保存されます。

### FIRフィルター

- **ノイズ除去**: light, medium, strong, default
- **倍音補正**: dead, base, med, high, dynamic

### 音楽タイプ

jazz, classical, electronic, vocal, none

### 環境エフェクト

- Viena-Symphony-Hall
- Suntory-Music-Hall
- NewMorning-JazzClub
- Wembley-Studium
- AbbeyRoad-Studio
- vinyl

### 出力デバイス

- BlueALSA (Bluetooth)
- hw:0, hw:1, hw:2, hw:3 (HDMI/アナログ)
- USB-DAC (自動検出)
- PC Speakers (hw:0)

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
