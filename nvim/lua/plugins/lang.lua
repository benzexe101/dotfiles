return {
	-- ── Syntax highlighting ──────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"c",
					"cpp",
					"cmake",
					"make",
					"python",
					"toml",
					"javascript",
					"typescript",
					"tsx",
					"html",
					"css",
					"json",
					"jsonc",
					"rust",
					"ron",
					"typst",
					"lua",
					"vim",
					"vimdoc",
					"bash",
					"fish",
					"markdown",
					"markdown_inline",
				},
				highlight = {
					enable = true,
					disable = function(_, buf)
						return vim.bo[buf].buftype ~= ""
					end,
				},
				indent = { enable = true },
			})
		end,
	},

	-- ── Completion ───────────────────────────────────────────────────
	{
		"saghen/blink.cmp",
		version = "*",
		event = "InsertEnter",
		opts = {
			keymap = { preset = "default" },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			signature = { enabled = true },
		},
	},

	-- ── LSP ──────────────────────────────────────────────────────────
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})

			vim.lsp.config("clangd", {
				cmd = {
					"/usr/bin/clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
				},
			})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
						telemetry = { enable = false },
					},
				},
			})

			-- rust_analyzer omitted on purpose: rustaceanvim owns it.
			vim.lsp.enable({
				"clangd",
				"cmake",
				"pyright",
				"ruff",
				"ts_ls",
				"jsonls",
				"cssls",
				"html",
				"eslint",
				"lua_ls",
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local map = function(k, fn, desc)
						vim.keymap.set("n", k, fn, { buffer = ev.buf, desc = desc })
					end
					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("gr", vim.lsp.buf.references, "References")
					map("gi", vim.lsp.buf.implementation, "Implementation")
					map("K", vim.lsp.buf.hover, "Hover docs")
					map("<leader>rn", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("[d", function()
						vim.diagnostic.jump({ count = -1 })
					end, "Prev diagnostic")
					map("]d", function()
						vim.diagnostic.jump({ count = 1 })
					end, "Next diagnostic")
				end,
			})

			vim.diagnostic.config({ virtual_text = true, severity_sort = true })
		end,
	},

	-- ── Rust ─────────────────────────────────────────────────────────
	{ "mrcjkb/rustaceanvim", version = "^6", lazy = false },
	{ "saecki/crates.nvim", event = "BufRead Cargo.toml", opts = {} },

	-- ── Formatting ───────────────────────────────────────────────────
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		opts = {
			formatters_by_ft = {
				c = { "clang_format" },
				cpp = { "clang_format" },
				python = { "ruff_format" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				rust = { "rustfmt" },
				lua = { "stylua" },
			},
			format_on_save = { timeout_ms = 2000, lsp_format = "fallback" },
		},
	},
}
