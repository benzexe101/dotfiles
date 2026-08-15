# Neovim Development Environment — Reference

Garuda Linux · Neovim 0.11+ · fish · lazy.nvim
Set up 2026-08-07

---

## Daily workflow

```fish
newcpp myproject          # create a new C++ project (once per project)
cd ~/dev/cpp/myproject
nvim main.cpp             # edit, :w saves + auto-formats, :q
run                       # build and execute
```

That's it. `newcpp` only runs once per project; after that it's just `nvim` and `run`.

For quick experiments, reuse the scratch project instead of making new ones:

```fish
cd ~/dev/cpp/scratch
nvim main.cpp
run
```

---

## Keymaps

Leader is **space**.

### LSP (code intelligence)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gr` | Find references (opens quickfix list) |
| `gi` | Go to implementation |
| `K` | Hover docs |
| `<space>rn` | Rename symbol |
| `<space>ca` | Code action |
| `[d` / `]d` | Previous / next diagnostic |
| `<C-o>` | Jump back (after `gd`) |

### Completion

| Key | Action |
|---|---|
| `<C-n>` | Next item |
| `<C-p>` | Previous item |
| `<C-y>` | **Accept** |
| `<C-e>` | Dismiss menu |
| `<C-space>` | Force menu open |
| `<C-k>` | Toggle signature help |

Tab does *not* accept by default. To switch to Tab-accepts, set `keymap = { preset = "super-tab" }` in `lang.lua`.

### Debugger

| Key | Action |
|---|---|
| `<space>db` | Toggle breakpoint |
| `<space>dc` | Start / continue |
| `<space>do` | Step over |
| `<space>di` | Step into |
| `<space>dO` | Step out |
| `<space>dh` | Inspect value under cursor |
| `<space>du` | Toggle DAP UI |
| `<space>dt` | Terminate |

### Typst

`<space>p` — start preview (only active in Typst buffers)

---

## Config file layout

```
~/.config/nvim/
├── init.lua                    leader key, editor options, lazy bootstrap,
│                               mason setup, { import = "plugins" }, Typst keymap
├── lazy-lock.json              pinned plugin commits
└── lua/plugins/
    ├── lang.lua                treesitter, blink.cmp, LSP + keymaps,
    │                           rustaceanvim, conform (formatting)
    └── dap.lua                 nvim-dap, dap-ui, virtual-text, lldb adapter
```

**Adding plugins later:** drop a new `.lua` file in `lua/plugins/` returning a table of specs. The `{ import = "plugins" }` line in `init.lua` picks it up automatically — no further wiring.

The directory must be exactly `lua/plugins/`. It resolves through Lua's module path, and `~/.config/nvim` is on the runtimepath with `lua/` as the module root.

---

## What's installed

| Language | LSP | Formatter | Source |
|---|---|---|---|
| C / C++ | clangd | clang-format | pacman |
| Python | pyright + ruff | ruff | pacman |
| Rust | rust-analyzer (via rustaceanvim) | rustfmt | rustup component |
| JS / TS / TSX | ts_ls + eslint | prettier | pacman + Mason |
| HTML / CSS / JSON | html, cssls, jsonls | prettier | Mason |
| Lua | lua_ls (Neovim-aware) | stylua | pacman |
| Typst | tinymist | — | Mason |

23 treesitter parsers compiled for syntax highlighting.

**Why the split between pacman and Mason:** pacman for native binaries — especially clangd, which must be built against the same libstdc++ headers the system compiler uses, or it reports phantom errors on standard includes. rustup for rust-analyzer, which has to version-match rustc. Mason for npm-only servers Arch dropped from its repos.

---

## Helper scripts

### `~/bin/newcpp`

Creates a CMake project with debug symbols and `compile_commands.json`.

```fish
#!/usr/bin/env fish
# usage: newcpp projectname
set name $argv[1]
mkdir -p ~/dev/cpp/$name
cd ~/dev/cpp/$name

echo '#include <iostream>

int main() {
    std::cout << "hello\n";
    return 0;
}' > main.cpp

echo "cmake_minimum_required(VERSION 3.20)
project($name)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_executable($name main.cpp)" > CMakeLists.txt

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug >/dev/null
ln -sf build/compile_commands.json .
echo "ready: ~/dev/cpp/$name"
```

### `run` (fish function)

Lives in `~/.config/fish/functions/run.fish`.

```fish
function run --description "build and run current cmake project"
    set -l name (basename $PWD)
    cmake --build build; and ./build/$name
end
```

Note: this has to be a function, not an alias — fish forbids command substitution in the command position, so `./build/(basename $PWD)` is invalid. Assign to a variable first.

---

## C++ project requirements

**`compile_commands.json` is mandatory.** Without it clangd guesses compiler flags and red-squiggles standard headers like `#include <iostream>`. This is the single most common "my C++ LSP is broken" report and it isn't a config bug.

CMake projects — add to `CMakeLists.txt`:
```cmake
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```
then symlink `build/compile_commands.json` to the project root. `newcpp` does both.

Makefile projects (most CTF source drops) — use `bear`:
```fish
bear -- make
```

**Debug symbols** require `-DCMAKE_BUILD_TYPE=Debug` at configure time. Without them the debugger can't map machine instructions back to source lines. `newcpp` sets this; for an existing project:
```fish
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
```

Adding more source files: add them to the `add_executable(...)` line, then re-run `cmake -B build -G Ninja`.

---

## Troubleshooting patterns

### Completion shows nothing, or shows nonsense

**Check the error count in the statusline first.** `E:1` or higher means clangd's parse is already broken, and everything downstream of a parse error is a fallback guess.

Completion answers *"what is valid at this exact cursor position?"* — it is not a lookup of a variable name. Two things to verify:

1. **Is the cursor inside the braces where the variable was declared?** Typing `v.` after the closing `}` of `main` legitimately has no `v` in scope, so clangd offers file-scope names instead (`std`, `size_t`, `FILE`).
2. **Does the surrounding code parse?** An incomplete statement above the cursor breaks everything below it.

Fix the syntax, then completions come back.

### Navigating to a line

Don't count line numbers — they shift as you edit. Search instead:

```
/std::cout
```

Then `A` to append at end of line, or `o` to open a line below.

### Debugger opens and closes immediately

**A session with no breakpoints is identical to just running the program.** Set the breakpoint first (`<space>db`, confirm the red ● appears in the gutter), *then* `<space>dc`.

### Plugin errors after an update

Lazy changes git remotes in place rather than re-cloning, so a repo that moved orgs can end up with files from two different generations. Symptom: `attempt to index field 'X' (a nil value)` deep inside a plugin.

Fix — remove the plugin directory and drop its lockfile pin:
```fish
rm -rf ~/.local/share/nvim/lazy/PLUGIN_NAME
```
Then edit `lazy-lock.json` to remove the entry, restart, and `:Lazy sync`.

Note: Mason's *installed servers* live in `~/.local/share/nvim/mason/` — a different directory from the plugin code at `~/.local/share/nvim/lazy/mason.nvim`. Removing the plugin doesn't remove the servers.

### "loop or previous error loading module"

That is not the original error. Lua cached an earlier failure and you're seeing the echo. Run `:messages` and look for the first error above it.

### Treesitter errors in hover popups

nvim-treesitter bundles its own queries for languages Neovim 0.11 also ships (`c`, `lua`, `vim`, `vimdoc`, `markdown`, `markdown_inline`), and its copies win on runtimepath order. When a plugin query calls a core API that has since changed, you get errors in LSP floats.

Diagnostic: `:checkhealth vim.treesitter` and look for duplicate query paths — two entries for the same lang/kind pair means runtimepath order is silently deciding which runs.

Current mitigation in `lang.lua` disables treesitter where `buftype ~= ""` (i.e. in floats and popups).

### pacman: one missing package kills the whole line

pacman aborts the **entire transaction** if any target is missing. A single dropped package takes down every other package on the same command line.

For long lists, install one at a time:
```fish
for p in pkg1 pkg2 pkg3
    sudo pacman -S --needed --noconfirm $p
end
```

### "Freshly installed" ≠ "current"

`lazy-lock.json` pins commits, and lazy installs the *pinned* commit, not `HEAD`. A clean install can pull in months-old plugin versions. Check the Update tab (`U`) in `:Lazy` after any fresh setup.

---

## Useful commands

```
:Lazy                    plugin manager (U = update, S = sync, X = clean)
:Mason                   browse/install language servers
:checkhealth vim.lsp     which servers are attached
:checkhealth vim.treesitter
:LspRestart              re-attach servers (needed after changing LSP settings)
:TSInstallInfo           which parsers are installed
:messages                full error history
```

Rust uses `:RustLsp` commands rather than plain LSP ones, since rustaceanvim wraps rust-analyzer:
```
:RustLsp runnables
:RustLsp expandMacro
:RustLsp openCargo
```

---

## Next steps

- **C++ practice** — Stroustrup, *Programming: Principles and Practice*, one `newcpp` project per chapter. Exercism's C++ track for problems with test suites.
- **Registers pane** — in a debug session, expand `General Purpose Registers` under DAP Scopes. That's the view that matters for reverse engineering.
- **DAP Console** — bottom right pane takes raw lldb commands (`p langs.size()`, `register read rip`).
- **Rust** — works with the same DAP setup and keymaps; `cargo build` emits debug symbols by default.
