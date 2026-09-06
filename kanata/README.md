
## Why not keyd here

The M1 (`BenM1Linux`) uses [keyd](../keyd/) instead — kanata has no
prebuilt aarch64 Linux binary for Asahi, and keyd packages cleanly on
Fedora. The desktop stays on kanata for its cross-platform config.

Never run both on the same machine: each grabs the input device
exclusively and they will fight over it.
