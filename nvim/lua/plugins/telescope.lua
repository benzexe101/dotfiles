return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.0",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},

		keys = {
			{
				"<leader>ff",
				"<cmd>Telescope find_files<CR>",
				desc = "Find files",
			},
			{
				"<leader>fg",
				"<cmd>Telescope live_grep<CR>",
				desc = "Search text",
			},
			{
				"<leader>fb",
				"<cmd>Telescope buffers<CR>",
				desc = "Find open buffers",
			},
			{
				"<leader>fh",
				"<cmd>Telescope help_tags<CR>",
				desc = "Search help",
			},
		},

		config = function()
			require("telescope").setup({})
		end,
	},
}
