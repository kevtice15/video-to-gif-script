# Video to Slides GIF (macOS)

Convert videos into Google-Slides-friendly GIFs from:
- CLI (`video_to_slides_gif.sh`)
- Finder Quick Action (`video_to_slides_gif_finder.sh`)

## Features

- Good quality/size defaults for slides (`fps=10`, `width=800`, `colors=128`)
- Output next to source video by default
- Quick Action outputs include the preset name (`clip_small.gif`, `clip_medium.gif`, `clip_large.gif`, `clip_max.gif`)
- Collision-safe naming (`clip_small_1.gif`, `clip_small_2.gif`, ...)
- Optional `gifsicle` optimization if installed
- Finder Quick Action presets: Small `800`, Medium `1200`, Large `1600`, Max `1920`
- Installer now uses Automator-authored workflow templates instead of generating workflow internals from scratch

## Requirements

- macOS
- `ffmpeg` (required)
- `gifsicle` (optional)

Install deps with Homebrew:

```bash
brew install ffmpeg
brew install gifsicle
```

## Quick Start

1. Get the project onto your Mac.

```bash
git clone https://github.com/kevtice15/video-to-gif-script.git
cd video-to-gif-script
```

If you downloaded the repo as a ZIP from GitHub, unzip it and open the folder in Terminal instead.

2. Install dependencies.

```bash
brew install ffmpeg
brew install gifsicle
```

3. Choose one setup path.

Option A: install directly from the repo

```bash
chmod +x ./install.sh ./uninstall.sh
./install.sh
```

Option B: build a clickable macOS installer package

```bash
chmod +x ./build-pkg.sh
./build-pkg.sh --version 1.0.0
open ./dist
```

Then double-click the generated `.pkg`.

4. Use it in Finder.

- Right-click a `.mp4` or `.mov`
- Open `Quick Actions`
- Choose `Video to Slides GIF - Small`, `Medium`, `Large`, or `Max`

On first use, Finder may hide new Quick Actions until you enable them:

- Right-click a video in Finder
- Open `Quick Actions`
- Click `Customize...`
- Turn on `Video to Slides GIF - Small`, `Medium`, `Large`, and `Max`

If the Quick Actions do not appear immediately, run:

```bash
/System/Library/CoreServices/pbs -flush
/System/Library/CoreServices/pbs -update
killall Finder
```

macOS may also ask for permission to access folders the first time the action runs.
If no GIF appears, check for a system prompt and allow access for Terminal, the installed script, or `ffmpeg` as needed.
You may also need to review permissions in:

- `System Settings -> Privacy & Security -> Files and Folders`
- `System Settings -> Privacy & Security -> Full Disk Access`

## Install

From the project folder:

```bash
chmod +x ./install.sh ./uninstall.sh
./install.sh
```

Common install options:

```bash
./install.sh --install-deps
./install.sh --prefix "$HOME/Tools/video-to-slides-gif"
./build-pkg.sh --version 1.0.0
```

Installer output:
- Copies scripts to `~/Scripts/video-to-slides-gif` (or your custom prefix)
- Makes scripts executable
- Creates four Quick Action launchers
- Installs four workflows under `~/Library/Services`

Package build output:
- Creates an unsigned `.pkg` in `./dist`
- Installs scripts to `/usr/local/lib/video-to-slides-gif`
- Installs the Finder Quick Actions for the logged-in user at package install time

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

## Finder Quick Actions

`install.sh` now installs these Quick Actions automatically:

```text
~/Library/Services/Video to Slides GIF - Small.workflow
~/Library/Services/Video to Slides GIF - Medium.workflow
~/Library/Services/Video to Slides GIF - Large.workflow
~/Library/Services/Video to Slides GIF - Max.workflow
```

If it does not appear right away in Finder, relaunch Finder once.

Resolution presets:
- `Small`: `800px`
- `Medium`: `1200px`
- `Large`: `1600px`
- `Max`: `1920px`

## Build A macOS Installer

Create a double-clickable `.pkg`:

```bash
chmod +x ./build-pkg.sh
./build-pkg.sh --version 1.0.0
```

The generated package:
- installs scripts under `/usr/local/lib/video-to-slides-gif`
- adds a CLI symlink at `/usr/local/bin/video-to-slides-gif`
- creates the four Quick Actions for the logged-in user during install

## Uninstall

```bash
./uninstall.sh
```

This also removes:
- `~/Library/Services/Video to Slides GIF - Small.workflow`
- `~/Library/Services/Video to Slides GIF - Medium.workflow`
- `~/Library/Services/Video to Slides GIF - Large.workflow`
- `~/Library/Services/Video to Slides GIF - Max.workflow`

## Project Docs

- [VIDEO_TO_SLIDES_GUIDE.md](./VIDEO_TO_SLIDES_GUIDE.md): full option reference and troubleshooting
