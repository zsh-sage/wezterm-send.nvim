local WeztermSend = require("wezterm-send")

vim.api.nvim_create_user_command("WeztermSendJson", function(opts)
	WeztermSend.send_to_toggle_term_via_json_file(opts.args, false)
end, { nargs = 1, desc = "[JSON] Send text to Wezterm toggle terminal" })

vim.api.nvim_create_user_command("WeztermExecJson", function(opts)
	WeztermSend.send_to_toggle_term_via_json_file(opts.args, true)
end, { nargs = 1, desc = "[JSON] Execute command in Wezterm toggle terminal", complete = "shellcmd" })

vim.api.nvim_create_user_command("WeztermSendPaneId", function(opts)
	-- Expects <pane_id> <text...>
	if not opts.fargs or #opts.fargs < 2 then
		vim.notify("Usage: WeztermSendPaneId <pane_id> <text to send>", vim.log.levels.ERROR)
		return
	end

	local pane_id = tonumber(opts.fargs[1])
	if not pane_id or pane_id <= 0 then
		vim.notify("Invalid Pane ID provided: " .. vim.inspect(opts.fargs[1]), vim.log.levels.ERROR)
		return
	end

	-- Join the rest of the arguments as the text
	local text_to_send = table.concat({ table.unpack(opts.fargs, 2) }, " ")

	WeztermSend.send_text_to_pane_id(pane_id, text_to_send, false) -- execute = false
end, {
	nargs = "+", -- One or more arguments
	desc = "Send text to specific Wezterm Pane ID",
})

vim.api.nvim_create_user_command("WeztermExecPaneId", function(opts)
	-- Expects <pane_id> <command...>
	if not opts.fargs or #opts.fargs < 2 then
		vim.notify("Usage: WeztermExecPaneId <pane_id> <command to execute>", vim.log.levels.ERROR)
		return
	end

	local pane_id = tonumber(opts.fargs[1])
	if not pane_id or pane_id <= 0 then
		vim.notify("Invalid Pane ID provided: " .. vim.inspect(opts.fargs[1]), vim.log.levels.ERROR)
		return
	end

	-- Join the rest of the arguments as the command
	local command_to_exec = table.concat({ table.unpack(opts.fargs, 2) }, " ")

	WeztermSend.send_text_to_pane_id(pane_id, command_to_exec, true) -- execute = true
end, {
	nargs = "+", -- One or more arguments
	desc = "Execute command in specific Wezterm Pane ID",
	-- The 'complete' key and its function have been removed from this table
})
