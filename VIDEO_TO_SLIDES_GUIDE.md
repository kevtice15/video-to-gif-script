# Video to Slides GIF Script Guide

This folder includes `video_to_slides_gif.sh`, a script that converts video into an optimized GIF for Google Slides.
It also includes `video_to_slides_gif_finder.sh`, a Finder-friendly wrapper for Quick Actions.

## 1. Prerequisites

Install `ffmpeg` (required):

```bash
brew install ffmpeg
```

Optional: install `gifsicle` for extra GIF size optimization:

```bash
brew install gifsicle
```

## 2. Run from this directory

```bash
cd /path/to/video-to-gif-script
./video_to_slides_gif.sh input.mp4
```

Default behavior:
- Output is written next to the input file
- Output name matches input basename with `.gif`
- Example: `input.mp4` -> `input.gif`

## 3. Usage

```bash
./video_to_slides_gif.sh [options] <input_video> [output.gif]
```

Options:
- `-s, --start TIME` start time (example: `00:00:02.5`)
- `-d, --duration TIME` duration (example: `5` or `00:00:05`)
- `-f, --fps FPS` frames per second (default: `10`)
- `-w, --width PX` output width in pixels (default: `800`)
- `-c, --colors N` max colors (default: `128`)
- `--no-dither` disable dithering (smaller file, lower quality)
- `--loop N` loop count (default: `0`, infinite loop)
- `--overwrite` overwrite output if it already exists (skip `_1`, `_2`, ... fallback)
- `--verbose` print ffmpeg logs and conversion settings
- `-o, --output PATH` output file or output directory
- `-h, --help` show help

## 4. Common examples

Basic conversion:

```bash
./video_to_slides_gif.sh demo.mp4
```

Write to a specific file:

```bash
./video_to_slides_gif.sh demo.mp4 /tmp/demo.gif
```

Write to a specific directory:

```bash
./video_to_slides_gif.sh -o /tmp demo.mp4
```

Convert only a 5-second segment starting at 3 seconds:

```bash
./video_to_slides_gif.sh -s 00:00:03 -d 5 demo.mp4
```

Higher quality / larger output:

```bash
./video_to_slides_gif.sh -f 12 -w 900 -c 160 demo.mp4
```

Smaller file size:

```bash
./video_to_slides_gif.sh -f 8 -w 700 -c 96 --no-dither demo.mp4
```

## 5. Troubleshooting

`Error: 'ffmpeg' not found.`
- Install with `brew install ffmpeg`
- If this appears only in Finder Quick Action, update to the latest
  `video_to_slides_gif.sh` in this project. It now
  adds Homebrew paths automatically for Automator/Finder runs.

Permission denied when running script:

```bash
chmod +x ./video_to_slides_gif.sh
```

Input file not found:
- Confirm the path and filename are correct
- Use an absolute path if needed

See built-in help anytime:

```bash
./video_to_slides_gif.sh --help
```

## 6. Finder Quick Action (macOS)

This setup lets you right-click a video in Finder and generate a GIF:
- In the same folder as the video
- With the same basename as the video (`clip.mp4` -> `clip.gif`)
- With automatic fallback naming on conflict (`clip_1.gif`, `clip_2.gif`, ...)
- With higher resolution than default CLI runs (Finder wrapper uses `-w 1200`)

Steps:

1. Open `Automator` and create a new `Quick Action`.
2. Set:
   - `Workflow receives current`: `movie files`
   - `in`: `Finder`
3. Add action: `Run Shell Script`
4. Set:
   - `Shell`: `/bin/zsh`
   - `Pass input`: `as arguments`
5. Use this script:

```zsh
"$HOME/Scripts/video-to-slides-gif/quick_action_run.zsh" "$@"
```

6. Save as: `Video to Slides GIF`

To change Quick Action GIF resolution later, edit:
- run installer again with a new width:

```bash
./install.sh --width 1400
```

Use it in Finder:
- Select one or more videos
- Right-click -> `Quick Actions` -> `Video to Slides GIF`
