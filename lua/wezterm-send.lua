-- main module file
local WeztermSend = require("wezterm-send.send-to-pane")

---@class Config
---@field auto_unzoom boolean Automatically unzoom the pane if it's zoomed (default: true)
---@field auto_activate_pane boolean Automatically activate the pane after sending text (default: false)
---@field wezterm_config_dir string Path to the Wezterm configuration directory (default: "~/.config/wezterm/")
local config = {
	auto_unzoom = true,
	auto_activate_pane = false,
	wezterm_config_dir = "~/.config/wezterm/",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
	M.config = vim.tbl_deep_extend("force", M.config, args or {})

	local expanded_config_dir = vim.fn.expand(M.config.wezterm_config_dir)

	WeztermSend.opts = {
		auto_unzoom = M.config.auto_unzoom,
		auto_activate_pane = M.config.auto_activate_pane,
		wezterm_config_dir = expanded_config_dir,
	}
	WeztermSend.Panes.opts = {
		wezterm_config_dir = WeztermSend.opts.wezterm_config_dir,
	}
end

-- Set initial opts reference (optional, setup will overwrite)
local expanded_config_dir = vim.fn.expand(M.config.wezterm_config_dir)

WeztermSend.opts = {
	auto_unzoom = M.config.auto_unzoom,
	auto_activate_pane = M.config.auto_activate_pane,
	wezterm_config_dir = expanded_config_dir,
}
WeztermSend.Panes.opts = {
	wezterm_config_dir = WeztermSend.opts.wezterm_config_dir,
}

M.send_text_to_pane_id = function(pane_id, text, execute)
	return WeztermSend.send_text_to_pane_id(pane_id, text, execute)
end

M.send_to_toggle_term_via_json_file = function(text, execute)
	return WeztermSend.send_to_toggle_term_via_json_file(text, execute)
end

return M
