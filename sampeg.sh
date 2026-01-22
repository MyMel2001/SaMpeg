#!/bin/bash

# SaMpeg version
SAMPEG_VER="1.2026j"
TIMELINE_FILE="/tmp/sampeg_timeline.txt"

# --- COLORS & UI ---
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

# --- CORE HARDWARE ACCELERATION ---
get_enc() {
    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -qE "(nvenc|cuda)" && [ -e "/dev/nvidia0" ]; then
        echo "-c:v h264_nvenc -rc vbr -cq 22 -preset p6"
    else
        echo "-c:v libx264 -preset slow -crf 21"
    fi
}

# --- UNIFIED FEATURE FUNCTIONS (The Engine) ---
fn_trim() { ffmpeg -i "$1" -ss "$3" -to "$4" $(get_enc) -c:a copy "$2"; }
fn_crop() { ffmpeg -i "$1" -vf "crop=$3" $(get_enc) -c:a copy "$2"; }
fn_scale() { ffmpeg -i "$1" -vf "scale=$3:force_original_aspect_ratio=decrease,pad=$3:(ow-iw)/2:(oh-ih)/2" $(get_enc) "$2"; }
fn_speed() { ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/$3*PTS[v];[0:a]atempo=$3[a]" -map "[v]" -map "[a]" $(get_enc) "$2"; }
fn_reverse() { ffmpeg -i "$1" -vf reverse -af areverse $(get_enc) "$2"; }
fn_upscale() { ffmpeg -i "$1" -vf "scale=${3:-3840:2160}:flags=lanczos+accurate_rnd,unsharp=3:3:1.5:3:3:0.5" $(get_enc) -c:a copy "$2"; }
fn_normalize() { ffmpeg -i "$1" -af "loudnorm=I=-16:TP=-1.5:LRA=11" $(get_enc) "$2"; }
fn_stabilize() { ffmpeg -i "$1" -vf vidstabdetect -f null -; ffmpeg -i "$1" -vf vidstabtransform $(get_enc) "$2"; }
fn_pip() { ffmpeg -i "$1" -i "$2" -filter_complex "[1:v]scale=$4:$5 [pip]; [0:v][pip]overlay=$6:$7" $(get_enc) -c:a aac "$3"; }
fn_chroma() { ffmpeg -i "$1" -i "$3" -filter_complex "[0:v]colorkey=0x00FF00:0.1:0.1[ckout];[1:v][ckout]overlay" $(get_enc) "$2"; }
fn_watermark() { ffmpeg -i "$1" -i "$3" -filter_complex "[1:v]scale=iw*0.15:-1[wm];[0:v][wm]overlay=main_w-overlay_w-10:10" $(get_enc) -c:a copy "$2"; }
fn_text() { ffmpeg -i "$1" -vf "drawtext=text='$3':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2:borderw=2:bordercolor=black" $(get_enc) -c:a copy "$2"; }
fn_social() {
    ffmpeg -i "$1" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" $(get_enc) "${2}_16-9.mp4"
    ffmpeg -i "$1" -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920" $(get_enc) "${2}_9-16.mp4"
    ffmpeg -i "$1" -vf "scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080" $(get_enc) "${2}_1-1.mp4"
}
fn_gif() { ffmpeg -i "$1" -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$2"; }
fn_strip() { ffmpeg -i "$1" -map_metadata -1 -c:v copy -c:a copy "$2"; }

# --- GUI MODE ---
gui_mode() {
    while true; do
        CAT=$(zenity --list --title="SaMpeg Suite v$SAMPEG_VER" --width=600 --height=600 --column="Category" --column="Description" \
            "PROJECT" "NLE Timeline & Recording" "TRANSFORMS" "Trim, Crop, Scale, Speed, Reverse" \
            "VFX" "Upscale, Chroma, PIP, Watermark, Text" "AUDIO/COLOR" "Normalize, Stabilize, Silence, Color" \
            "EXPORT" "Social Media, GIF, Metadata" "EXIT" "Quit")
        [[ -z "$CAT" || "$CAT" == "EXIT" ]] && exit 0

        case "$CAT" in
            "TRANSFORMS")
                ACT=$(zenity --list --column="Action" "Trim" "Crop" "Scale" "Speed" "Reverse")
                IN=$(zenity --file-selection); OUT=$(zenity --file-selection --save)
                [[ "$ACT" == "Trim" ]] && fn_trim "$IN" "$OUT" $(zenity --entry --text="Start") $(zenity --entry --text="End")
                [[ "$ACT" == "Crop" ]] && fn_crop "$IN" "$OUT" $(zenity --entry --text="W:H:X:Y")
                [[ "$ACT" == "Scale" ]] && fn_scale "$IN" "$OUT" $(zenity --entry --text="Res" --entry-text="1920:1080")
                [[ "$ACT" == "Speed" ]] && fn_speed "$IN" "$OUT" $(zenity --entry --text="Mult" --entry-text="2.0")
                [[ "$ACT" == "Reverse" ]] && fn_reverse "$IN" "$OUT"
                ;;
            "VFX")
                ACT=$(zenity --list --column="Action" "Upscale" "Chroma" "PIP" "Watermark" "Text")
                IN=$(zenity --file-selection); OUT=$(zenity --file-selection --save)
                [[ "$ACT" == "Upscale" ]] && fn_upscale "$IN" "$OUT"
                [[ "$ACT" == "Chroma" ]] && fn_chroma "$IN" "$OUT" $(zenity --file-selection --title="BG")
                [[ "$ACT" == "PIP" ]] && fn_pip "$IN" $(zenity --file-selection --title="Overlay") "$OUT" 480 270 10 10
                [[ "$ACT" == "Watermark" ]] && fn_watermark "$IN" "$OUT" $(zenity --file-selection --title="Logo")
                [[ "$ACT" == "Text" ]] && fn_text "$IN" "$OUT" "$(zenity --entry --text="Text")"
                ;;
            "AUDIO/COLOR")
                ACT=$(zenity --list --column="Action" "Normalize" "Stabilize" "Grayscale")
                IN=$(zenity --file-selection); OUT=$(zenity --file-selection --save)
                [[ "$ACT" == "Normalize" ]] && fn_normalize "$IN" "$OUT"
                [[ "$ACT" == "Stabilize" ]] && fn_stabilize "$IN" "$OUT"
                [[ "$ACT" == "Grayscale" ]] && ffmpeg -i "$IN" -vf format=gray $(get_enc) "$OUT"
                ;;
            "EXPORT")
                ACT=$(zenity --list --column="Action" "Social" "GIF" "Strip")
                IN=$(zenity --file-selection)
                [[ "$ACT" == "Social" ]] && fn_social "$IN" "$(zenity --entry --text="Base Name")"
                [[ "$ACT" == "GIF" ]] && fn_gif "$IN" "$(zenity --file-selection --save)"
                [[ "$ACT" == "Strip" ]] && fn_strip "$IN" "$(zenity --file-selection --save)"
                ;;
            "PROJECT")
                ACT=$(zenity --list --column="Action" "New Timeline" "Add Clip" "Render" "Record")
                [[ "$ACT" == "New Timeline" ]] && > "$TIMELINE_FILE"
                [[ "$ACT" == "Add Clip" ]] && echo "$(zenity --file-selection)" >> "$TIMELINE_FILE"
                [[ "$ACT" == "Record" ]] && ffmpeg -f x11grab -video_size 1920x1080 -i :0.0 $(get_enc) "$(zenity --file-selection --save)"
                [[ "$ACT" == "Render" ]] && { 
                    RES=$(zenity --entry --text="Res" --entry-text="1920:1080")
                    OUT=$(zenity --file-selection --save)
                    TEMP_DIR=$(mktemp -d); i=0
                    while read -r line; do i=$((i+1)); ffmpeg -i "$line" -vf "scale=$RES:force_original_aspect_ratio=decrease,pad=$RES:(ow-iw)/2:(oh-ih)/2" -f mpegts "$TEMP_DIR/$i.ts" -y; done < "$TIMELINE_FILE"
                    ffmpeg -i "concat:$(ls -1 "$TEMP_DIR"/*.ts | paste -sd "|" -)" -c copy "$OUT" -y
                }
                ;;
        esac
    done
}

# --- CLI ROUTING ---
if [[ $# -eq 0 ]] || [[ "$1" == "--gui" ]]; then
    gui_mode
else
    cmd="$1"; shift
    case "$cmd" in
        trim) fn_trim "$@" ;;
        crop) fn_crop "$@" ;;
        scale) fn_scale "$@" ;;
        speed) fn_speed "$@" ;;
        reverse) fn_reverse "$@" ;;
        upscale) fn_upscale "$@" ;;
        normalize) fn_normalize "$@" ;;
        stabilize) fn_stabilize "$@" ;;
        pip) fn_pip "$@" ;;
        chroma) fn_chroma "$@" ;;
        watermark) fn_watermark "$@" ;;
        text) fn_text "$@" ;;
        social-export) fn_social "$@" ;;
        gif) fn_gif "$@" ;;
        strip) fn_strip "$@" ;;
        record-screen) ffmpeg -f x11grab -video_size 1920x1080 -i :0.0 $(get_enc) "$1" ;;
        help|--help) 
            echo "Commands: trim, crop, scale, speed, reverse, upscale, normalize, stabilize, pip, chroma, watermark, text, social-export, gif, strip, record-screen" ;;
        *) echo "Unknown command: $cmd"; exit 1 ;;
    esac
fi
