return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue / start",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step over",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step into",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Step out",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle DAP UI",
			},
			{
				"<leader>dh",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Inspect value",
				mode = { "n", "v" },
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()
			require("nvim-dap-virtual-text").setup({})

			-- open/close the UI automatically
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- ── lldb-dap: C, C++, Rust ──────────────────────────────────
			dap.adapters.lldb = {
				type = "executable",
				command = "/usr/bin/lldb-dap",
				name = "lldb",
			}

			dap.configurations.cpp = {
				{
					name = "Launch",
					type = "lldb",
					request = "launch",
					program = function()
						local guess = vim.fn.getcwd() .. "/build/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
						return vim.fn.input("Executable: ", guess, "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
				},
			}
			dap.configurations.c = dap.configurations.cpp
			dap.configurations.rust = dap.configurations.cpp

			-- ── debugpy: Python ─────────────────────────────────────────
			dap.adapters.python = {
				type = "executable",
				command = vim.fn.expand("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"),
				args = { "-m", "debugpy.adapter" },
			}

			dap.configurations.python = {
				{
					name = "Launch file (integratedTerminal)",
					type = "python",
					request = "launch",
					program = "${file}",
					console = "integratedTerminal",
					justMyCode = true,
					cwd = "${workspaceFolder}",
					pythonPath = function()
						local venv = vim.fn.getcwd() .. "/.venv/bin/python"
						if vim.fn.executable(venv) == 1 then
							return venv
						end
						return "python3"
					end,
				},
			}

			-- breakpoint icons
			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })
		end,
	},
}
