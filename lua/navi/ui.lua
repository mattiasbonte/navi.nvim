local M = {}

local function getDapStatusIcon()
	local dapStatus = require("dap").status()

	if not dapStatus or dapStatus == "" then
		return ""
	end

	return "🩺"
end

local function getFileTypeIcon()
	local fname, ext = vim.fn.expand("%:t"), vim.fn.expand("%:e")
	local icon, iconhl = require("nvim-web-devicons").get_icon(fname, ext)

	if not icon then
		icon = ""
	end

	return icon
end

function M.updateStatusLineContext(activeContext)
	local fileTypeIcon = getFileTypeIcon()
	local dapStatus = getDapStatusIcon()
	local naviContext = activeContext or require("navi.context").getActiveContext()

	local statusline = {
		-- LEFT
		" ", -- icon
		naviContext,

		-- CENTER
		"%=", -- separator
		fileTypeIcon,
		" %<%f", -- full file path
		"%h%m%r", -- help, modified, readonly

		-- RIGHT
		"%=", -- separator
		dapStatus,
		" %l|%c", -- line and column number
		" %P", -- the percentage of lines from the top of the file
		" %Y", -- filetype uppercased
	}
	vim.o.statusline = table.concat(statusline, " ")

	-- make status line transparent
	vim.cmd([[hi StatusLine ctermbg=none guibg=none]])
end

return M
