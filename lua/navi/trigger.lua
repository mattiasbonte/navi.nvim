local M = {}

function M.bindTriggers(config)
	local triggers = config.triggers

	for triggerKey, contextName in pairs(triggers) do
		local prevAction = config.contexts[contextName].prev
		local nextAction = config.contexts[contextName].next

		if prevAction then
			vim.keymap.set("n", "[" .. triggerKey, function()
				prevAction()
				require("navi.context").setActiveContext(contextName, config)
			end, { desc = "prev " .. contextName, noremap = true })
		end
		if nextAction then
			vim.keymap.set("n", "]" .. triggerKey, function()
				nextAction()
				require("navi.context").setActiveContext(contextName, config)
			end, { desc = "next " .. contextName, noremap = true })
		end
	end
end

return M
