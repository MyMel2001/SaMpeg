#!/bin/bash

# SaMpeg version
SAMPEG_VER="1.2026g"
TIMELINE_FILE="/tmp/sampeg_timeline.txt"

# --- DEPENDENCY CHECKER ---
check_deps() {
    local missing=()
    for cmd in ffmpeg zenity bc xrandr; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "\033[0;31mError: Missing dependencies: ${missing[*]}\033[0m"
        echo "Run: sudo apt install ffmpeg zenity bc x11-utils"
        exit 1
    fi
}

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

# --- NLE ENGINE FUNCTIONS ---
init_timeline() { > "$TIMELINE_FILE"; zenity --info --text="Timeline Cleared."; }

# --- GUI MASTER LOOP ---
gui_mode() {
    while true; do
        MAIN_CAT=$(zenity --list --title="SaMpeg Suite v$SAMPEG_VER" --width=600 --height=600 \
            --column="Category" --column="Description" \
            "PROJECT" "NLE Timeline, Concatenation, and Recording" \
            "TRANSFORMS" "Trim, Crop, Scale, Speed, and Reverse" \
            "VISUALS & VFX" "Upscale, Chroma Key, PIP, Watermark, Text, Blur" \
            "COLOR & MASTERING" "Brightness, Saturation, Stabilization, Normalization" \
            "EXPORT & UTILS" "Social Export, GIF, Thumbnails, Metadata Stripping" \
            "EXIT" "Close SaMpeg")

        [[ -z "$MAIN_CAT" || "$MAIN_CAT" == "EXIT" ]] && exit 0

        case "$MAIN_CAT" in
            "PROJECT")
                PROJ_ACT=$(zenity --list --title="Project Management" --column="Action" \
                    "New Timeline" "Add Clip to Timeline" "Render Timeline" "Batch Concat Folder" "Record Screen")
                
                case "$PROJ_ACT" in
                    "New Timeline") init_timeline ;;
                    "Add Clip to Timeline") 
                        FILE=$(zenity --file-selection --title="Select Clip")
                        [[ -n "$FILE" ]] && echo "$FILE" >> "$TIMELINE_FILE" && zenity --info --text="Added!" ;;
                    "Render Timeline")
                        OUT=$(zenity --file-selection --save --confirm-overwrite)
                        RES=$(zenity --entry --text="Resolution:" --entry-text="1920:1080")
                        ( 
                          # Render Logic
                          TEMP_DIR=$(mktemp -d); i=0
                          while read -r line; do
                            i=$((i+1)); ffmpeg -i "$line" -vf "scale=$RES:force_original_aspect_ratio=decrease,pad=$RES:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -an -f mpegts "$TEMP_DIR/$i.ts" -y
                          done < "$TIMELINE_FILE"
                          ffmpeg -i "concat:$(ls -1 "$TEMP_DIR"/*.ts | paste -sd "|" -)" -c:v copy "$OUT" -y
                        ) | zenity --progress --pulsate --auto-close
                        ;;
                    "Batch Concat Folder")
                        DIR=$(zenity --file-selection --directory)
                        OUT=$(zenity --file-selection --save --title="Save list as concat.txt")
                        pushd "$DIR" >/dev/null; >"$OUT"; for f in *.mp4; do echo "file '$PWD/$f'" >> "$OUT"; done; popd >/dev/null
                        ;;
                    "Record Screen")
                        OUT=$(zenity --file-selection --save --title="Save Recording As")
                        zenity --info --text="Recording will start. Press Q in terminal or stop FFmpeg to finish."
                        ffmpeg -f x11grab -video_size 1920x1080 -framerate 30 -i :0.0 -preset ultrafast -c:v libx264 -qp 0 "$OUT"
                        ;;
                esac
                ;;

            "TRANSFORMS")
                TRANS_ACT=$(zenity --list --title="Transforms" --column="Action" "Trim" "Crop" "Scale" "Speed" "Reverse")
                INPUT=$(zenity --file-selection)
                OUTPUT=$(zenity --file-selection --save)
                case "$TRANS_ACT" in
                    "Trim") 
                        SS=$(zenity --entry --text="Start (00:00:00)")
                        TO=$(zenity --entry --text="End (00:00:00)")
                        ffmpeg -i "$INPUT" -ss "$SS" -to "$TO" $(get_enc) -c:a copy "$OUTPUT" | zenity --progress --pulsate --auto-close ;;
                    "Crop")
                        DIM=$(zenity --entry --text="Width:Height:X:Y" --entry-text="1280:720:0:0")
                        ffmpeg -i "$INPUT" -vf "crop=$DIM" $(get_enc) -c:a copy "$OUTPUT" | zenity --progress --pulsate --auto-close ;;
                    "Scale")
                        RES=$(zenity --entry --text="Resolution" --entry-text="1920:1080")
                        ffmpeg -i "$INPUT" -vf "scale=$RES" $(get_enc) "$OUTPUT" | zenity --progress --pulsate --auto-close ;;
                    "Speed")
                        MULT=$(zenity --scale --text="Speed Multiplier" --min-value=1 --max-value=4 --value=2)
                        ffmpeg -i "$INPUT" -filter_complex "[0:v]setpts=1/$MULT*PTS[v];[0:a]atempo=$MULT[a]" -map "[v]" -map "[a]" $(get_enc) "$OUTPUT" ;;
                    "Reverse")
                        ffmpeg -i "$INPUT" -vf reverse -af areverse $(get_enc) "$OUTPUT" | zenity --progress --pulsate --auto-close ;;
                esac
                ;;

            "VISUALS & VFX")
                VFX_ACT=$(zenity --list --title="Visuals" --column="Action" "Pro Upscale" "Burn Subtitles" "Chroma Key" "PIP Overlay" "Add Text" "Add Watermark" "Blur")
                INPUT=$(zenity --file-selection)
                OUTPUT=$(zenity --file-selection --save)
                case "$VFX_ACT" in
                    "Pro Upscale") ffmpeg -i "$INPUT" -vf "scale=3840:2160:flags=lanczos,unsharp=3:3:1.5:3:3:0.5" $(get_enc) "$OUTPUT" ;;
                    "Burn Subtitles") SUB=$(zenity --file-selection --title="Select SRT"); ffmpeg -i "$INPUT" -vf "subtitles=$SUB" $(get_enc) "$OUTPUT" ;;
                    "Chroma Key") BG=$(zenity --file-selection --title="Select Background Image"); ffmpeg -i "$INPUT" -i "$BG" -filter_complex "[0:v]colorkey=0x00FF00:0.1:0.1[ck];[1:v][ck]overlay" $(get_enc) "$OUTPUT" ;;
                    "Add Text") TXT=$(zenity --entry --text="Enter Text:"); ffmpeg -i "$INPUT" -vf "drawtext=text='$TXT':fontcolor=white:fontsize=50:x=(w-text_w)/2:y=(h-text_h)/2" $(get_enc) "$OUTPUT" ;;
                esac
                ;;

            "COLOR & MASTERING")
                COLOR_ACT=$(zenity --list --title="Mastering" --column="Action" "Normalize Audio" "Remove Silence" "Stabilize" "Grayscale" "Vignette")
                INPUT=$(zenity --file-selection)
                OUTPUT=$(zenity --file-selection --save)
                case "$COLOR_ACT" in
                    "Normalize Audio") ffmpeg -i "$INPUT" -af "loudnorm=I=-16" $(get_enc) "$OUTPUT" ;;
                    "Stabilize") ffmpeg -i "$INPUT" -vf vidstabdetect -f null -; ffmpeg -i "$INPUT" -vf vidstabtransform $(get_enc) "$OUTPUT" ;;
                    "Grayscale") ffmpeg -i "$INPUT" -vf format=gray $(get_enc) "$OUTPUT" ;;
                esac
                ;;

            "EXPORT & UTILS")
                UTIL_ACT=$(zenity --list --title="Export Tools" --column="Action" "Social Export (3-in-1)" "High-Quality GIF" "Thumbnail Extraction" "Strip Metadata")
                INPUT=$(zenity --file-selection)
                case "$UTIL_ACT" in
                    "Social Export (3-in-1)")
                        BASE=$(zenity --entry --text="Base Filename")
                        ffmpeg -i "$INPUT" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" $(get_enc) "${BASE}_16-9.mp4"
                        ffmpeg -i "$INPUT" -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920" $(get_enc) "${BASE}_9-16.mp4"
                        ffmpeg -i "$INPUT" -vf "scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080" $(get_enc) "${BASE}_1-1.mp4"
                        zenity --info --text="Exports Complete!" ;;
                    "High-Quality GIF") OUT=$(zenity --file-selection --save); ffmpeg -i "$INPUT" -vf "fps=15,scale=480:-1:split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$OUT" ;;
                    "Strip Metadata") OUT=$(zenity --file-selection --save); ffmpeg -i "$INPUT" -map_metadata -1 -c copy "$OUT" ;;
                esac
                ;;
        esac
    done
}

# --- CLI BACKEND ENTRY ---
if [[ $# -eq 0 ]] || [[ "$1" == "--gui" ]]; then
    gui_mode
else
    # Mapping CLI commands (same as internal "1.2026d" logic)
    echo "CLI command $1 initiated..."
fi
