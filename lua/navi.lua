local naviConfig = require("navi.config")
local naviContext = require("navi.context")
local naviTrigger = require("navi.trigger")

local M = {}

-------------------
-- ACTIVE CONFIG --
-------------------
M.config = naviConfig

function M.getActiveConfig()
	return M.config
end

-----------
-- SETUP --
-----------
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", naviConfig, userConfig or {})

	local activeContext = naviContext.getActiveContext(M.config)
	naviContext.setActiveContext(activeContext, M.config)

	if M.config.enableTriggers then
		naviTrigger.bindTriggers(M.config)
	end
end

--------------------
-- SELECT CONTEXT --
--------------------
function M.select()
	local active = M.config.active
	local contexts = M.config.contexts

	-- list of items to show in the select menu
	local contextItems = {}
	for _, value in pairs(active) do
		if value ~= naviContext.getActiveContext(M.config) then
			if contexts[value] then
				table.insert(contextItems, value)
			else
				vim.notify("navi: context '" .. value .. "' not found in config.contexts")
			end
		end
	end

	local options = {
		prompt = "Context:",
	}

	vim.ui.select(contextItems, options, function(selectedContext)
		naviContext.setActiveContext(selectedContext, M.config)
	end)
end

return M
