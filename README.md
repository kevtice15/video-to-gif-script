# Video to Slides GIF (macOS)

Convert videos into Google-Slides-friendly GIFs from:
- CLI (`video_to_slides_gif.sh`)
- Finder Quick Action (`video_to_slides_gif_finder.sh`)

## Features

- Good quality/size defaults for slides (`fps=10`, `width=800`, `colors=128`)
- Output next to source video by default (`clip.mp4 -> clip.gif`)
- Collision-safe naming (`clip_1.gif`, `clip_2.gif`, ...)
- Optional `gifsicle` optimization if installed
- Finder wrapper with larger default width for sharper presentation GIFs

## Requirements

- macOS
- `ffmpeg` (required)
- `gifsicle` (optional)

Install deps with Homebrew:

```bash
brew install ffmpeg
brew install gifsicle
```

## Install

From the project folder:

```bash
chmod +x ./install.sh ./uninstall.sh
./install.sh
```

Common install options:

```bash
./install.sh --width 1400
./install.sh --install-deps
./install.sh --prefix "$HOME/Tools/video-to-slides-gif"
```

Installer output:
- Copies scripts to `~/Scripts/video-to-slides-gif` (or your custom prefix)
- Makes scripts executable
- Creates `quick_action_run.zsh` for Automator

## CLI Usage

```bash
./video_to_slides_gif.sh [options] <input_video> [output.gif]
```

Examples:

```bash
./video_to_slides_gif.sh demo.mp4
./video_to_slides_gif.sh -s 00:00:03 -d 5 demo.mp4
./video_to_slides_gif.sh -w 1200 -f 12 -c 160 demo.mp4
./video_to_slides_gif.sh --overwrite demo.mp4 demo.gif
./video_to_slides_gif.sh --verbose demo.mp4
```

## Finder Quick Action Setup

After install, create an Automator Quick Action:
1. `Workflow receives current`: `movie files`
2. `In`: `Finder`
3. Add action: `Run Shell Script`
4. Set `Shell`: `/bin/zsh`
5. Set `Pass input`: `as arguments`
6. Paste:

```zsh
"$HOME/Scripts/video-to-slides-gif/quick_action_run.zsh" "$@"
```

7. Save as `Video to Slides GIF`

## Uninstall

```bash
./uninstall.sh
```

If you created the Quick Action, also delete:
- `~/Library/Services/Video to Slides GIF.workflow`

## Project Docs

- [VIDEO_TO_SLIDES_GUIDE.md](./VIDEO_TO_SLIDES_GUIDE.md): full option reference and troubleshooting
