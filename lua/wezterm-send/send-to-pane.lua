local SendToPane = {}
local Panes = require("wezterm-send.get_pane_id")

SendToPane.opts = {}
SendToPane.Panes = Panes

local function unzoom_pane()
	local unzoom_cmd = "wezterm cli zoom-pane --unzoom"
	vim.fn.jobstart(unzoom_cmd, {
		detach = true,
		on_exit = function(_, code, _)
			if code ~= 0 then
				vim.schedule(function()
					vim.notify(
						string.format("wezterm cli zoom-pane --unzoom failed (code: %d).", code),
						vim.log.levels.WARN -- Use WARN as it might not be critical
					)
				end)
			end
		end,
		on_stderr = function(_, data, _)
			if data and #data > 0 and data[1] ~= "" then
				vim.schedule(function()
					vim.notify(
						"wezterm cli zoom-pane --unzoom error: " .. table.concat(data, "\n"),
						vim.log.levels.WARN -- Use WARN as it might not be critical
					)
				end)
			end
		end,
	})
end

local function activate_pane(pane_id)
	local activate_pane_cmd = "wezterm cli activate-pane --pane-id " .. pane_id
	vim.fn.jobstart(activate_pane_cmd, {
		detach = true,
		on_exit = function(_, code, _)
			if code ~= 0 then
				vim.schedule(function()
					vim.notify(
						string.format("wezterm cli activate-pane --pane-id %d (code: %d).", pane_id, code),
						vim.log.levels.WARN -- Use WARN as it might not be critical
					)
				end)
			end
		end,
		on_stderr = function(_, data, _)
			if data and #data > 0 and data[1] ~= "" then
				vim.schedule(function()
					vim.notify(
						string.format("wezterm cli activate-pane --pane-id %d error: ", pane_id)
							.. table.concat(data, "\n"),
						vim.log.levels.WARN -- Use WARN as it might not be critical
					)
				end)
			end
		end,
	})
end

local function pane_set(panes)
	local set = {}
	if panes then
		for _, pane in ipairs(panes) do
			set[pane.pane_id] = true
		end
	end
	return set
end

--- Sends text/command to a specific Wezterm pane ID using `wezterm cli send-text`.
--- @param pane_id integer The target Wezterm pane ID.
--- @param text string The text or command to send.
--- @param execute boolean|nil If true, appends a newline to execute the command.
function SendToPane.send_text_to_pane_id(pane_id, text, execute)
	local wezterm = require("wezterm")

	-- Validate inputs
	if not pane_id or type(pane_id) ~= "number" or pane_id <= 0 then
		vim.notify("Error: Invalid pane_id provided for sending text: " .. vim.inspect(pane_id), vim.log.levels.ERROR)
		return
	end

	local panes = wezterm.list_panes()
	if panes then
		local panes_set = pane_set(panes)
		if not panes_set[pane_id] then
			vim.notify("Error: Pane doesn't exist: " .. vim.inspect(pane_id), vim.log.levels.ERROR)

			return
		end
	end

	if not text or text == "" then
		vim.notify("Error: No text provided to send to pane " .. pane_id, vim.log.levels.ERROR)
		return
	end

	-- Optionally unzoom the pane before sending text
	if SendToPane.opts.auto_unzoom then
		unzoom_pane()
	end

	if SendToPane.opts.auto_activate_pane then
		activate_pane(pane_id)
	end

	local cmd = nil
	local text_payload = text
	if execute then
		-- Use --no-paste to ensure the trailing newline from echo executes the command
		cmd = string.format(
			"echo %s | wezterm cli send-text --pane-id %d --no-paste",
			vim.fn.shellescape(text_payload),
			pane_id
		)
	else
		-- Send text without executing
		cmd = string.format("echo %s | wezterm cli send-text --pane-id %d", vim.fn.shellescape(text_payload), pane_id)
	end

	vim.notify("Sending to pane " .. pane_id .. " via send-text...", vim.log.levels.INFO)
	vim.fn.jobstart(cmd, {
		detach = true,
		-- Handle exit code from the wezterm cli command
		on_exit = function(_, code, _)
			if code ~= 0 then
				vim.schedule(function()
					vim.notify(string.format("wezterm cli send-text failed (code: %d).", code), vim.log.levels.ERROR)
				end)
			end
		end,
		-- Handle stderr output from the wezterm cli command
		on_stderr = function(_, data, _)
			if data and #data > 0 and data[1] ~= "" then -- Check if there's actual stderr output
				vim.schedule(function()
					vim.notify("wezterm cli send-text error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
				end)
			end
		end,
	})
end

--- Gets the toggle terminal pane ID for the current tab from its state file and sends text to it.
--- @param text string The text or command to send
--- @param execute boolean | nil If true, appends a newline to execute the command.
function SendToPane.send_to_toggle_term_via_json_file(text, execute)
	local state_file_path = SendToPane.Panes.get_nvim_toggle_state_file_path()
	if not state_file_path then
		return -- Error already notified by Panes.get_nvim_toggle_state_file_path
	end

	local target_pane_id = SendToPane.Panes.get_pane_id_from_json_file(state_file_path)

	if target_pane_id then
		SendToPane.send_text_to_pane_id(target_pane_id, text, execute)
	end
end

return SendToPane
