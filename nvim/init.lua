-- ── Leader must be set before ANY keymap or lazy.setup ────────────
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.guicursor = ""
vim.opt.dictionary = "/usr/share/dict/words"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ── bootstrap lazy.nvim ───────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── plugins ───────────────────────────────────────────────────────
require("lazy").setup({
  { "mason-org/mason.nvim", config = true },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "tinymist", "jsonls", "cssls", "html", "eslint" },
      })
      vim.lsp.config("tinymist", {
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/tinymist") },
      })
      vim.lsp.enable("tinymist")
    end,
  },

  { import = "plugins" },
})

-- ── Typst preview: buffer-local, only where tinymist attaches ─────
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == "tinymist" then
      vim.keymap.set("n", "<leader>p", function()
        client:exec_cmd({ command = "tinymist.startDefaultPreview" }, { bufnr = ev.buf })
      end, { buffer = ev.buf, desc = "Typst preview" })
    end
  end,
})
