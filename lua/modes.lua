local utils = require('modes.utils')

local M = {}
local config = {}
local default_config = {
	colors = {},
	line_opacity = {
		copy = 0.15,
		delete = 0.15,
		insert = 0.15,
		visual = 0.15,
	},
	set_highlight_yank = {highlight = false , timeout = 050},
	set_cursor = true,
	set_cursorline = true,
	set_number = true,
	ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
}
local winhighlight = {
	default = {
		CursorLine = 'CursorLine',
		CursorLineNr = 'CursorLineNr',
		CursorLineSign = 'CursorLineSign',
		CursorLineFold = 'CursorLineFold',
		Visual = 'Visual',
		statusline = 'statusline',
	},
	copy = {
		CursorLine = 'ModesCopyCursorLine',
		CursorLineNr = 'ModesCopyCursorLineNr',
		CursorLineSign = 'ModesCopyCursorLineSign',
		CursorLineFold = 'ModesCopyCursorLineFold',
		statusline = 'ModesCopystatusline',
	},
	insert = {
		CursorLine = 'ModesInsertCursorLine',
		CursorLineNr = 'ModesInsertCursorLineNr',
		CursorLineSign = 'ModesInsertCursorLineSign',
		CursorLineFold = 'ModesInsertCursorLineFold',
		statusline = 'ModesInsertstatusline',
	},
	delete = {
		CursorLine = 'ModesDeleteCursorLine',
		CursorLineNr = 'ModesDeleteCursorLineNr',
		CursorLineSign = 'ModesDeleteCursorLineSign',
		CursorLineFold = 'ModesDeleteCursorLineFold',
		statusline = 'ModesDeletestatusline',
	},
	visual = {
		CursorLine = 'ModesVisualCursorLine',
		CursorLineNr = 'ModesVisualCursorLineNr',
		CursorLineSign = 'ModesVisualCursorLineSign',
		CursorLineFold = 'ModesVisualCursorLineFold',
		Visual = 'ModesVisualVisual',
		statusline = 'ModesVisualstatusline',
	},
}
local colors = {}
local blended_colors = {}
local operator_started = false

M.reset = function()
	M.highlight('default')
	operator_started = false
end

---Update highlights
---@param scene 'default'|'insert'|'visual'|'copy'|'delete'|
M.highlight = function(scene)
	local winhl_map = {}
	local prev_value = vim.api.nvim_win_get_option(0, 'winhighlight')

	-- mapping the old value of 'winhighlight'
	if prev_value ~= '' then
		for _, winhl in ipairs(vim.split(prev_value, ',')) do
			local pair = vim.split(winhl, ':')
			winhl_map[pair[1]] = pair[2]
		end
	end

	-- overrides 'builtin':'hl' if the current scene has a mapping for it
	for builtin, hl in pairs(winhighlight[scene]) do
		winhl_map[builtin] = hl
	end

	local new_value = {}
	for builtin, hl in pairs(winhl_map) do
		table.insert(new_value, ('%s:%s'):format(builtin, hl))
	end
	vim.api.nvim_win_set_option(0, 'winhighlight', table.concat(new_value, ','))

	if vim.api.nvim_get_option('showmode') then
		if scene == 'visual' then
			utils.set_hl('ModeMsg', { link = 'ModesVisualModeMsg' })
		elseif scene == 'insert' then
			utils.set_hl('ModeMsg', { link = 'ModesInsertModeMsg' })
		end
	end

	if config.set_cursor then
		if scene == 'delete' then
			utils.set_hl('ModesOperator', { link = 'ModesDelete' })
		elseif scene == 'copy' then
			utils.set_hl('ModesOperator', { link = 'ModesCopy' })
		end
	end
end

M.define = function()
	local normal_bg = utils.get_bg('Normal', 'Normal')
	colors = {
		copy = config.colors.copy or utils.get_bg('ModesCopy', '#f5c359'),
		delete = config.colors.delete or utils.get_bg('ModesDelete', '#c75c6a'),
		insert = config.colors.insert or utils.get_bg('ModesInsert', '#78ccc5'),
		visual = config.colors.visual or utils.get_bg('ModesVisual', '#9745be'),
	}
	blended_colors = {
		copy = utils.blend(colors.copy, normal_bg, config.line_opacity.copy),
		delete = utils.blend(
			colors.delete,
			normal_bg,
			config.line_opacity.delete
		),
		insert = utils.blend(
			colors.insert,
			normal_bg,
			config.line_opacity.insert
		),
		visual = utils.blend(
			colors.visual,
			normal_bg,
			config.line_opacity.visual
		),
	}

	---Create highlight groups
	vim.cmd('hi ModesCopy guibg=' .. colors.copy)
	vim.cmd('hi ModesDelete guibg=' .. colors.delete)
	vim.cmd('hi ModesInsert guibg=' .. colors.insert)
	vim.cmd('hi ModesVisual guibg=' .. colors.visual)

	for _, mode in ipairs({ 'Copy', 'Delete', 'Insert', 'Visual' }) do
		local def = { bg = blended_colors[mode:lower()] }
		utils.set_hl(('Modes%sCursorLine'):format(mode), def)
		utils.set_hl(('Modes%sCursorLineNr'):format(mode), def)
		utils.set_hl(('Modes%sCursorLineSign'):format(mode), def)
		utils.set_hl(('Modes%sCursorLineFold'):format(mode), def)
		utils.set_hl(('Modes%sstatusline'):format(mode), def)
	end

	utils.set_hl('ModesInsertModeMsg', { fg = colors.insert })
	utils.set_hl('ModesVisualModeMsg', { fg = colors.visual })
	utils.set_hl('ModesVisualVisual', { bg = blended_colors.visual })
end

M.enable_managed_ui = function()
	if config.set_cursor then
		vim.opt.guicursor:append('v-sm:block-ModesVisual')
		vim.opt.guicursor:append('i-ci-ve:ver25-ModesInsert')
		vim.opt.guicursor:append('r-cr-o:hor20-ModesOperator')
	end

	if config.set_cursorline then
		vim.opt.cursorline = true
	end
end

M.disable_managed_ui = function()
	if config.set_cursor then
		vim.opt.guicursor:remove('v-sm:block-ModesVisual')
		vim.opt.guicursor:remove('i-ci-ve:ver25-ModesInsert')
		vim.opt.guicursor:remove('r-cr-o:hor20-ModesOperator')
	end

	if config.set_cursorline then
		vim.opt.cursorline = false
	end
end

M.setup = function(opts)
	opts = opts or default_config
	if opts.focus_only then
		print(
			'modes.nvim – `focus_only` has been removed and is now the default behaviour'
		)
	end

	config = vim.tbl_deep_extend('force', default_config, opts)

	if type(config.line_opacity) == 'number' then
		config.line_opacity = {
			copy = config.line_opacity,
			delete = config.line_opacity,
			insert = config.line_opacity,
			visual = config.line_opacity*1.5,
		}
	end

	M.define()

	vim.on_key(function(key)
		local ok, current_mode = pcall(vim.fn.mode)
		if not ok then
			M.reset()
			return
		end

		if current_mode == 'n' then
			-- reset if coming back from operator pending mode
			if operator_started then
				M.reset()
				return
			end

			if key == 'y' then
				M.highlight('copy')
				operator_started = true
				return
			end

			if key == 'd' then
				M.highlight('delete')
				operator_started = true
				return
			end
		end

		if key == utils.replace_termcodes('<esc>') then
			M.reset()
			return
		end
	end)

	---Set highlights when colorscheme changes
	vim.api.nvim_create_autocmd('ColorScheme', {
		pattern = '*',
		callback = M.define,
	})

	---Set insert highlight
	vim.api.nvim_create_autocmd('InsertEnter', {
		pattern = '*',
		callback = function()
			M.highlight('insert')
		end,
	})

	---Set visual highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:[vV\x16]',
		callback = function()
			M.highlight('visual')
		end,
	})

	---Reset visual highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '[vV\x16]:n',
		callback = M.reset,
	})

	---Reset highlights
	vim.api.nvim_create_autocmd(
		{ 'CmdlineLeave', 'InsertLeave', 'TextYankPost', 'WinLeave' },
		{
			pattern = '*',
			callback = M.reset,
		}
	)

	---Enable managed UI initially
	M.enable_managed_ui()

	---Enable managed UI for current window
	vim.api.nvim_create_autocmd('WinEnter', {
		pattern = '*',
		callback = M.enable_managed_ui,
	})

	---Disable managed UI for unfocused windows
	vim.api.nvim_create_autocmd('WinLeave', {
		pattern = '*',
		callback = M.disable_managed_ui,
	})

	---Disable managed UI for ignored filetypes
	vim.api.nvim_create_autocmd('FileType', {
		pattern = config.ignore_filetypes,
		callback = M.disable_managed_ui,
	})

	-- highlight yanked text with the same color as visually selected text
	if config.set_highlight_yank.highlight then
		vim.api.nvim_create_autocmd("TextYankPost", {
			callback = function()
				vim.highlight.on_yank({ higroup = "ModesCopyCursorLine", timeout = config.set_highlight_yank.timeout })
			end,
		})
	end
	
end

return M
