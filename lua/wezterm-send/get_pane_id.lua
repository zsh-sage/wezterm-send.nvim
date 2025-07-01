local M = {}

M.opts = {}

-- Get the tab_id of the current Neovim pane within WezTerm.
function M.get_current_tab_id()
	local wezterm = require("wezterm")

	local pane_list = wezterm.list_panes()
	local current_pane_id = wezterm.get_current_pane()
	local tab_id = nil

	if current_pane_id then
		if pane_list then
			for _, pane_info in ipairs(pane_list) do
				if pane_info.pane_id == current_pane_id then
					tab_id = pane_info.tab_id
					break
				end
			end
			if not tab_id then
				vim.notify("Could not find current pane ID in WezTerm pane list", vim.log.levels.WARN)
			end
		else
			vim.notify("Cannot get WezTerm pane list", vim.log.levels.ERROR)
		end
	else
		vim.notify("Cannot get current WezTerm pane ID", vim.log.levels.ERROR)
	end

	return tab_id
end

-- Get the expected path for the JSON file storing the toggle terminal's pane ID for a specific tab.
function M.get_nvim_toggle_state_file_path()
	local current_tab_id = M.get_current_tab_id()
	if not current_tab_id then
		-- Error already notified by get_current_tab_id
		vim.notify("Cannot determine state file path due to missing tab ID", vim.log.levels.WARN)
		return nil
	end

	-- State file is per-tab, located within a 'tmp' subdirectory of the WezTerm config directory.
	return M.opts.wezterm_config_dir .. "tmp/wezterm_toggle_pane_tab_" .. current_tab_id .. ".json"
end

--- Reads the JSON state file and extracts the pane ID.
--- @param file_path string The full path to the JSON state file.
--- @return integer? target_pane_id The extracted pane ID, or nil if not found/invalid.
function M.get_pane_id_from_json_file(file_path)
	if vim.fn.filereadable(file_path) == 0 then
		-- This is often expected if the toggle terminal isn't open in the target tab
		vim.notify("Toggle terminal state file not found: " .. file_path, vim.log.levels.INFO)
		return nil
	end

	local json_lines = vim.fn.readfile(file_path)
	if not json_lines or #json_lines == 0 then
		vim.notify("Toggle terminal state file is empty: " .. file_path, vim.log.levels.WARN)
		return nil
	end
	local json_string = table.concat(json_lines)

	local ok, decoded_state = pcall(vim.json.decode, json_string)

	if not ok or decoded_state == vim.NIL then
		vim.notify(
			"Failed to decode JSON from state file: "
				.. file_path
				.. "\nContent snippet: "
				.. string.sub(json_string, 1, 100),
			vim.log.levels.ERROR
		)
		return nil
	end

	-- Ensure the state file indicates an active terminal with a valid pane_id
	if
		type(decoded_state) ~= "table"
		or decoded_state.active ~= true -- Check specifically for true
		or not decoded_state.state_table.pane_id
	then
		vim.notify(
			"Invalid or inactive state found in JSON file: " .. file_path .. "\nState: " .. vim.inspect(decoded_state),
			vim.log.levels.WARN
		)
		return nil
	end

	local target_pane_id = tonumber(decoded_state.state_table.pane_id)

	-- check if pane is valid
	if not target_pane_id or target_pane_id <= 0 then
		vim.notify(
			"Invalid Pane ID found in JSON state file: "
				.. file_path
				.. "\nID Value: "
				.. vim.inspect(decoded_state.pane_id),
			vim.log.levels.ERROR
		)
		return nil
	end

	return target_pane_id
end

return M
