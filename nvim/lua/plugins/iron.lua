return {
	"Vigemus/iron.nvim",

	config = function()
		local iron = require("iron.core")

		iron.setup({
			config = {
				scratch_repl = true,

				repl_definition = {
					python = {
						command = { "python3" },
						format = require("iron.fts.common").bracketed_paste_python,
						env = { PYTHON_BASIC_REPL = "1" },
					},
				},

				repl_open_cmd = require("iron.view").bottom(15),
			},

			keymaps = {
				toggle_repl = "<leader>rr",
				send_line = "<leader>sl",
				visual_send = "<leader>sc",
				send_file = "<leader>sf",
			},
		})
	end,
}
