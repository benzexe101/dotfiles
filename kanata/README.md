
## Why not keyd here

The M1 (`BenM1Linux`) uses [keyd](../keyd/) instead — kanata has no
prebuilt aarch64 Linux binary for Asahi, and keyd packages cleanly on
Fedora. The desktop stays on kanata for its cross-platform config.

Never run both on the same machine: each grabs the input device
exclusively and they will fight over it.
## Setup on a new machine

1. Install kanata (`paru -S kanata`).

2. Add the machine's keyboard to `linux-dev-names-include` in `kanata.kbd`.
   Get the exact name from `kanata --list`. No match means kanata starts
   fine and silently does nothing.

   - X1: `AT Translated Set 2 keyboard`
   - Desktop: `Telink Wireless Gaming Keyboard`

3. Two separate permissions are needed. `input` covers reading
   `/dev/input/event*`; `uinput` covers writing `/dev/uinput`. Arch
   creates neither the uinput group nor the udev rule.
