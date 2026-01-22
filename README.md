# SaMpeg Suite

**SaMpeg** is an all‑in‑one FFmpeg-powered video processing suite that works both as a **GUI application** (via Zenity) and a **CLI tool**. It provides NLE‑style timeline rendering, professional video/audio transforms, VFX utilities, social media exports, and hardware‑accelerated encoding when available.

---

## Features

### Core Capabilities

* Automatic **hardware acceleration detection** (NVIDIA NVENC when available, fallback to libx264)
* Unified FFmpeg engine for consistent results across GUI and CLI
* Loss‑aware defaults tuned for high quality

### Video Transforms

* Trim (time-based)
* Crop
* Scale & pad (aspect‑ratio safe)
* Speed change (audio + video)
* Reverse playback

### VFX & Pro Lab

* AI‑quality 4K upscale (Lanczos + sharpening)
* Chroma key (green screen)
* Picture‑in‑Picture (PIP)
* LUT (.cube) color grading
* Watermark overlay
* Burn‑in subtitles (SRT)
* Text overlay

### Audio & Repair

* Broadcast‑safe loudness normalization (EBU R128 style)
* Video stabilization (vid.stab)
* Container repair / stream copy recovery
* Audio waveform visualizer
* Audio extraction

### Export & Automation

* Social media exports (16:9, 9:16, 1:1)
* GIF generation (palette‑optimized)
* Metadata stripping
* Screen recording (X11)

### Project / Timeline Mode

* Lightweight NLE timeline
* Add clips sequentially
* Render concatenated projects at chosen resolution

---

## Requirements

* **bash**
* **ffmpeg** (with libx264; NVENC optional)
* **zenity** (for GUI mode)
* **vid.stab** FFmpeg filters (for stabilization)
* **bc** - Simple calculating tools
* **X11 Utils** - X11 utils
* X-based Linux desktop (X11 required for screen recording.)

---

## Installation

```bash
chmod +x sampeg.sh
sudo mv sampeg.sh /usr/local/bin/sampeg
```

Ensure dependencies are installed:

```bash
sudo apt update && sudo apt install -y ffmpeg zenity bc x11-utils libvidstab-dev
```

---

## Usage

### GUI Mode (Default)

```bash
sampeg
# or
sampeg --gui
```

Launches the full graphical suite with categorized tools.

---

### CLI Mode

General syntax:

```bash
sampeg <command> <input> <output> [options]
```

#### Examples

Trim a clip:

```bash
sampeg trim input.mp4 output.mp4 00:00:10 00:00:30
```

Scale to 1080p:

```bash
sampeg scale input.mp4 output.mp4 1920:1080
```

Normalize audio:

```bash
sampeg normalize input.mp4 output.mp4
```

Create social media exports:

```bash
sampeg social-export input.mp4 myvideo
```

Record screen:

```bash
sampeg record-screen output.mp4
```

---

## CLI Commands

| Command       | Description             |
| ------------- | ----------------------- |
| trim          | Cut by start/end time   |
| crop          | Crop video (W:H:X:Y)    |
| scale         | Resize with padding     |
| speed         | Change playback speed   |
| reverse       | Reverse audio & video   |
| upscale       | High‑quality 4K upscale |
| normalize     | Loudness normalization  |
| stabilize     | Video stabilization     |
| pip           | Picture‑in‑Picture      |
| chroma        | Green screen key        |
| watermark     | Overlay watermark       |
| text          | Draw centered text      |
| burn-subs     | Burn subtitles          |
| lut           | Apply LUT grade         |
| viz           | Audio waveform image    |
| repair        | Fix broken container    |
| extract-audio | Export audio track      |
| social-export | Social media formats    |
| gif           | Create animated GIF     |
| strip         | Remove metadata         |
| record-screen | X11 screen capture      |

---

## Hardware Acceleration

SaMpeg automatically uses **NVIDIA NVENC** when:

* FFmpeg reports NVENC/CUDA encoders
* `/dev/nvidia0` is present

Otherwise, it safely falls back to **libx264**.

---

## Philosophy

SaMpeg is designed as:

* A **power‑user Swiss Army knife** for FFmpeg
* A **lightweight NLE alternative** for fast jobs
* A **scriptable media engine** suitable for automation

No proprietary formats. No lock‑in. Just FFmpeg — done right.

---

## License

MIT‑style usage. FFmpeg licensing applies to binaries and codecs.

---

## Author

SaMpeg Suite — built for creators who prefer control, speed, and quality.
