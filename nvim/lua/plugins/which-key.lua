return {
	"folke/which-key.nvim",
	event = "VeryLazy",

	opts = {
		preset = "modern",

		spec = {
			{ "<leader>r", group = "REPL" },
			{ "<leader>s", group = "Send code" },
			{ "<leader>h", group = "Harpoon" },
		},
	},
}
