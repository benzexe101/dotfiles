> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

# Typst Terminal Preview (timg + entr)

A quick reference for setting up an in-terminal Typst preview using `timg` and `entr` inside tmux, with Kitty's native graphics protocol for pixel-accurate rendering.

## Dependencies

```bash
sudo pacman -S timg entr
```

Both are in official/chaotic-aur repos — no AUR helper needed.

## Basic Usage (single page)

```bash
ls your_file.typ | entr sh -c 'typst compile your_file.typ /tmp/preview.png && timg /tmp/preview.png'
```

Save with `:w` in Neovim and the preview pane updates automatically.

## Multi-page Documents

Use Typst's `{p}` page number placeholder:

```bash
ls your_file.typ | entr sh -c 'typst compile your_file.typ /tmp/preview_{p}.png && timg /tmp/preview_*.png'
```

This outputs `preview_1.png`, `preview_2.png`, etc. and `timg` stacks them all in the pane.

## tmux Layout

Split your tmux window into two panes:

```
Ctrl+a %    → vertical split
Ctrl+a "    → horizontal split
Ctrl+a o    → switch between panes
```

Suggested layout:

```
┌─────────────────┬──────────────────┐
│                 │                  │
│   neovim        │   timg preview   │
│   (edit .typ)   │   (auto-updates) │
│                 │                  │
└─────────────────┴──────────────────┘
```

Left pane: `nvim your_file.typ`  
Right pane: the `entr` watch command above

## Notes

- Works best in **Kitty** — uses the kitty graphics protocol for pixel-accurate rendering
- `entr` watches the file for changes and re-runs the compile + display command on each `:w`
- `/tmp/preview.png` is just a temp path, change it to whatever you want
- `timg` will clear and re-render the image in place each time, keeping the pane clean
- For a quick resolution bump, add `--ppi 200` to the `typst compile` command:
  ```bash
  typst compile --ppi 200 your_file.typ /tmp/preview_{p}.png
  ```

## Why Not Firefox?

Typst's built-in `typst watch --open` uses a WebSocket-connected browser preview that pushes changes in real time with no manual refresh. That's objectively better for long writing sessions. This `timg` setup is a good lightweight alternative when you want everything in the terminal, but for multi-page documents with complex layouts, the Firefox preview is more reliable.
