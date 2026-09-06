# keyd

Software keyboard remapping via [keyd](https://github.com/rvaiya/keyd),
a system daemon that intercepts at the evdev layer — below X11/Wayland,
so it works identically under KDE Plasma and Hyprland.

Caps lock becomes dual-role: tap for Escape, hold for a vim-style
navigation layer.

## Layout

| Hold caps + | Result        |
|-------------|---------------|
| `h j k l`   | arrows        |
| `u` / `d`   | page up/down  |
| `y` / `e`   | home / end    |
| `w` / `b`   | word fwd/back |

## Per-host configs

Configs are named by hostname; `install.sh` picks the right one:

    ./install.sh

| Host         | Machine                                           |
|--------------|---------------------------------------------------|
| `BenM1Linux` | MacBook Pro 13" (M1, 2020), Fedora Asahi Remix 44 |

## Device matching

    [ids]
    05ac:0341:89b7fedc

Apple's SPI controller exposes both the internal keyboard and the
trackpad under the same `vendor:product` pair (`05ac:0341`), so a
two-part ID is ambiguous. keyd's third field disambiguates. Get it
from `sudo keyd monitor`.

Fallback if that identifier ever changes: `[ids] *` — safe here, since
keyd only grabs keyboard-class devices.

## Notes

Installed by copy rather than symlink: keyd is a root daemon reading
from `/etc`, and SELinux objects to it following a link into `/home`.
Re-run `install.sh` after editing. It restarts the daemon rather than
calling `keyd reload` — on keyd 2.6.0 (aarch64) an in-place reload
re-parsed the config cleanly, then segfaulted in `process_event` on the
next keypress. The packaged unit ships no `Restart=` policy, so a crash
leaves you with no remap until you notice; see
`/etc/systemd/system/keyd.service.d/override.conf`.
