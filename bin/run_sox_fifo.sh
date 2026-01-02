#!/bin/bash

FIFO_PATH="/tmp/mpd.fifo"
CTL_PATH="/tmp/sox.ctl"

# FIRフィルターのベースパス (実際のパスに合わせてください)
# 実際のフィルターファイルが配置されているディレクトリのパスを正確に設定してください。
# 例: /home/tysbox/bin/noise/noise_fir_default.txt が存在する場合 -> FIR_BASE_PATH="/home/tysbox/bin/"
# 例: /home/tysbox/fir_bank/noise/noise_fir_default.txt が存在する場合 -> FIR_BASE_PATH="/home/tysbox/fir_bank/"
# パスの最後に "/" を付けてください。
FIR_BASE_PATH="/home/tysbox/bin/"

# --- 設定値 (GUIから書き換えられる部分) ---
MUSIC_TYPE="none"
EFFECTS_TYPE="Suntory-Music-Hall"
EQ_OUTPUT_TYPE="none"
GAIN="-3"
NOISE_FIR_TYPE="default"
HARMONIC_FIR_TYPE="dynamic"
OUTPUT_METHOD="aplay"
# SAMPLE_RATE="192000" # 現在は192k固定でリサンプル。将来的に可変にする場合のため (GUIから設定可能にする必要あり)
# --- 設定値ここまで ---

# FIFOファイルが存在するか確認し、存在しない場合は作成
if [ ! -p "$FIFO_PATH" ]; then
    mkfifo "$FIFO_PATH"
fi

# コントロールファイルが存在しなければ作成
if [ ! -f "$CTL_PATH" ]; then
    touch "$CTL_PATH"
    chmod 666 "$CTL_PATH"
fi

# --- FIRフィルターファイルの選択 ---
# ノイズ除去FIR (FIR_BASE_PATHからの相対パスを指定)
NOISE_FIR_FILTER="" # 初期化
case $NOISE_FIR_TYPE in
    light)   NOISE_FIR_FILTER="fir ${FIR_BASE_PATH}noise_fir_light.txt" ;;
    medium)  NOISE_FIR_FILTER="fir ${FIR_BASE_PATH}noise_fir_medium.txt" ;;
    strong)  NOISE_FIR_FILTER="fir ${FIR_BASE_PATH}noise_fir_strong.txt" ;;
    # デフォルトノイズフィルターを明示的に指定
    default) NOISE_FIR_FILTER="fir ${FIR_BASE_PATH}noise_fir_default.txt" ;;
    off)     NOISE_FIR_FILTER="" ;; # オフの場合は空
    *)       NOISE_FIR_FILTER="" ;; # 未知のタイプはオフとする
esac

# 倍音FIR (FIR_BASE_PATHからの相対パスを指定)
HARMONIC_FIR_FILTER="" # 初期化
case $HARMONIC_FIR_TYPE in
    dead)    HARMONIC_FIR_FILTER="fir ${FIR_BASE_PATH}harmonic_dead.txt" ;;
    base)    HARMONIC_FIR_FILTER="fir ${FIR_BASE_PATH}harmonic_base.txt" ;;
    med)     HARMONIC_FIR_FILTER="fir ${FIR_BASE_PATH}harmonic_med.txt" ;;
    high)    HARMONIC_FIR_FILTER="fir ${FIR_BASE_PATH}harmonic_high.txt" ;; # 変数名を修正済み
    dynamic) HARMONIC_FIR_FILTER="fir ${FIR_BASE_PATH}harmonic_dynamic.txt" ;;
    off)     HARMONIC_FIR_FILTER="" ;; # 'off' オプションを追加
    *)       HARMONIC_FIR_FILTER="" ;; # 未知のタイプはオフとする
esac

# --- 音楽タイプ別のイコライザー設定 ---
# (元のスクリプトに含まれていたゲイン設定を維持)
case $MUSIC_TYPE in
    jazz)        EQ_INPUT="gain -5 equalizer 80 0.9q +2.5 equalizer 300 1.0q +1.0 equalizer 1500 1.1q +0.5 equalizer 3000 1.0q +1.0 equalizer 7000 0.8q +0.7" ;;
    classical)   EQ_INPUT="gain -5 equalizer 60 0.7q +1.0 equalizer 400 0.9q -0.5 equalizer 1800 1.0q +0.3 equalizer 4000 1.1q +0.7 equalizer 8000 0.8q +1.0" ;;
    electronic) EQ_INPUT="gain -5 equalizer 40 0.8q +3.0 equalizer 120 1.0q +2.0 equalizer 800 1.1q -0.5 equalizer 2500 1.0q +1.0 equalizer 8000 0.9q +1.5" ;;
    vocal)       EQ_INPUT="gain -5 equalizer 70 1.0q -0.8 equalizer 250 1.5q +1.0 equalizer 2500 1.2q +2.0 equalizer 5000 0.8q +1.0 equalizer 12000 0.7q +0.5" ;;
    none)        EQ_INPUT="gain -3" ;; # 元のスクリプトに合わせて gain -3 を維持
    *)           EQ_INPUT="" ;;
esac

# --- 環境エフェクト設定 ---
# (元のスクリプトに含まれていたゲイン設定を維持)
case $EFFECTS_TYPE in
    Viena-Symphony-Hall) EFFECTS="reverb 50 30 100 100 1 0 bass +2 treble -2 delay 0.3 0.3 gain 2" ;;
    Suntory-Music-Hall)  EFFECTS="reverb 25 20 70 50 1 0 bass +3 treble -2 delay 0.05 0.05 gain 2" ;;
    NewMorning-JazzClub) EFFECTS="reverb 20 20 30 10 2 1 compand 0.2,1 6:-70,-60,-30 -1 -90 0.2 gain -7" ;;
    Wembley-Studium)     EFFECTS="reverb 50 50 100 80 0.6 4 compand 0.3,1 6:-70,-50,-20 -1 -90 0.2 echo 0.7 0.5 20 0.3 chorus 0.7 0.9 55 0.4 0.25 2 -t" ;;
    AbbeyRoad-Studio)    EFFECTS="highpass 30 reverb 30 20 50 30 0 -2 compand 0.03,1 6:-70,-50,-30 -5 -80 0.2 chorus 0.9 0.8 20 0.2 0.15 2 -t" ;;
    vinyl)               EFFECTS="overdrive 1.2 8 bass +2 treble -2 delay 0.05 0.05 reverb 20 20 25 20 0.4 -1 compand 0.3,1 6:-70,-55,-40,-40,-25,-20,-15,-10,-5,-5,0,0 2 gain -5" ;;
    none)                EFFECTS="gain 3" ;; # 元のスクリプトに合わせて gain 3 を維持
    *)                   EFFECTS="" ;;
esac

# --- 再生デバイス別のイコライザー設定 ---
# (元のスクリプトに含まれていたFIRやゲイン設定は、それぞれのフィルター選択や最終ゲインで扱うためここからは削除)
case $EQ_OUTPUT_TYPE in
    studio-monitors) EQ_OUTPUT="equalizer 80 0.8q +3 equalizer 2500 1.0q -0.8 equalizer 20000 1.0q +3" ;;
    JBL-Speakers)    EQ_OUTPUT="equalizer 70 0.7q +3 equalizer 1200 1.0q -2 equalizer 13000 0.8q +5" ;;
    planar-magnetic) EQ_OUTPUT="equalizer 30 0.7q 1 equalizer 180 0.9q -1 equalizer 15000 0.8q +1.0" ;;
    bt-earphones)    EQ_OUTPUT="equalizer 60 1.0q +1 equalizer 3000 1.0q -0.5 equalizer 18000 1.0q 3" ;;
    med-harmonics)   EQ_OUTPUT="equalizer 50 1.8q +2 equalizer 200 1.1q +1 equalizer 17000 1.0q +2" ;;
    high-harmonics)  EQ_OUTPUT="" ;; # EQなし
    none)            EQ_OUTPUT="" ;;
    *)               EQ_OUTPUT="" ;;
esac

# --- ゲイン調整 (GUIからの値を独立して適用) ---
FINAL_GAIN_CMD=""
# GAIN 変数が空でなく、かつ "-0" (文字列としてのゼロ) でない場合のみ gain コマンドを生成
if [ -n "$GAIN" ] && [ "$GAIN" != "-0" ]; then
    FINAL_GAIN_CMD="gain ${GAIN}"
# GAIN が "-0" の場合は、コマンドを生成しないことで 0dB ゲイン（無処理）とする
# GAIN が空の場合は、コマンドは生成されない
fi

# --- リサンプル設定 ---
# サンプルレートは192k固定とします
RESAMPLE_CMD="rate -v -s -M 192k" # 音が出るスクリプトではレート指定が欠けていたが、ここでは明示的に指定

# --- SoX コマンドと再生コマンドの構築 ---
# 入力設定 (MPD FIFOの標準的な形式に合わせる: S32_LE)
INPUT_OPTS="-t raw -r 192000 -e signed -b 32 -c 2"

# エフェクトチェイン (変数が空の場合は展開されないように注意)
# 順序: ノイズ除去FIR -> 入力EQ -> 倍音FIR -> 出力EQ -> 環境エフェクト -> リサンプル -> 最終ゲイン -> ディザー
# 注意: エフェクトは sox [入力] [出力] [エフェクト] の順で指定する必要があるため、
# エフェクトチェーンの文字列自体はエフェクト部分のみで構成します。
EFFECT_CHAIN="${NOISE_FIR_FILTER}${NOISE_FIR_FILTER:+" "}${EQ_INPUT}${EQ_INPUT:+" "}${HARMONIC_FIR_FILTER}${HARMONIC_FIR_FILTER:+" "}${EQ_OUTPUT}${EQ_OUTPUT:+" "}${EFFECTS}${EFFECTS:+" "}${RESAMPLE_CMD}${RESAMPLE_CMD:+" "}${FINAL_GAIN_CMD}${FINAL_GAIN_CMD:+" "}dither -S"


# 出力方法に応じたコマンド構築
if [ "$OUTPUT_METHOD" == "soxplay" ]; then
    # play コマンドとして実行
    # play [入力オプション] [入力ファイル] [エフェクト]
    SOX_FULL_COMMAND="play ${INPUT_OPTS} \"$FIFO_PATH\" ${EFFECT_CHAIN}"
    PLAY_CMD="" # play コマンド自体が出力を行うためパイプ不要

elif [ "$OUTPUT_METHOD" == "aplay" ]; then
    # aplay にパイプ (S32_LE 形式で出力)
    # sox [入力オプション] <入力ファイル> [出力オプション] <出力ファイル> [エフェクト] の順にする (オリジナルスクリプトの順序)
    # 出力オプションとして標準出力への raw S32_LE を指定
    OUTPUT_OPTS="-t raw -e signed -b 32 -"
    SOX_FULL_COMMAND="sox ${INPUT_OPTS} \"$FIFO_PATH\" ${OUTPUT_OPTS} ${EFFECT_CHAIN}" # オリジナルスクリプトの順序に修正
    # aplay コマンド (標準入力から S32_LE を読む)
    PLAY_CMD="| aplay -D default -f S32_LE -r 192000 -c 2" # レートはSoXのリサンプル出力に合わせる

else
    echo "不明な OUTPUT_METHOD: $OUTPUT_METHOD"
    exit 1
fi

# 最終的なコマンド実行
echo "Executing Sox chain:"
echo "$SOX_FULL_COMMAND $PLAY_CMD" # デバッグ用にコマンドを表示
# shellcheck disable=SC2086 # eval is needed here for the pipe to aplay
eval "$SOX_FULL_COMMAND $PLAY_CMD"

echo "Sox process finished."
