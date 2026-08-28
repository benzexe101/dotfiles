return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "markdown" },
		opts = {
			heading = { position = "inline" },
			code = { width = "block", right_pad = 2 },
		},
	},
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		build = "cd app && npm install",
		config = function()
			vim.g.mkdp_auto_close = 0
			vim.keymap.set("n", "<leader>m", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown preview (browser)" })
		end,
	},
}
