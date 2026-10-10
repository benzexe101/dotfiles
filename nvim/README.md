## Neovim Configuration

My personal Neovim configuration for Python, C/C++, Rust, Typst, and other development tasks.

### Features

- **Telescope:** Fuzzy finding for files, text, buffers, and help documentation.
- **nvim-dap:** Debugging support for Python, C, C++, and Rust.
- **Mason:** Management of development tools and language servers.
- **LSP:** Language server integration for diagnostics and code intelligence.
- **Custom keybindings:** Shortcuts defined in `lua/remap.lua`.

### Keybindings

| Shortcut | Action |
|---|---|
| `<leader>pv` | Open file explorer |
| `<leader>e` | Show diagnostic messages |
| `<leader>ff` | Find files |
| `<leader>fg` | Search text |
| `<leader>fb` | Search open buffers |
| `<leader>fh` | Search help |
| `<leader>db` | Toggle debugging breakpoint |
| `<leader>dc` | Start or continue debugging |
| `<leader>dr` | Toggle debugger REPL |

The leader key is `Space`.

### Configuration Structure

- `init.lua` — Main Neovim configuration
- `lua/remap.lua` — Custom keybindings
- `lua/plugins/telescope.lua` — Telescope configuration
- `lua/plugins/dap.lua` — Debugging configuration

### Notes

This configuration is a work in progress as I continue learning Lua, Neovim, and Linux development tools.
