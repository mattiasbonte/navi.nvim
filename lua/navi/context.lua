local Path = require("plenary.path")

local M = {}

--------------------
-- CACHED CONTEXT --
--------------------
local cache_name = "navi_cache.json"
local navi_cache_path = string.format("%s/" .. cache_name, vim.fn.stdpath("data"))

function M.getCachePath()
	return navi_cache_path
end

function M.readCache(cache_path)
	return vim.json.decode(Path:new(cache_path):read())
end

function M.getCache()
	local success, cache = pcall(M.readCache, navi_cache_path)

	if success then
		return cache
	else
		return {}
	end
end

function M.writeCache(newCache)
	local oldCache = M.getCache()

	if not oldCache then
		Path:new(navi_cache_path):write(vim.fn.json_encode(newCache), "w")
	else
		local mergedCache = vim.tbl_extend("force", oldCache, newCache)
		Path:new(navi_cache_path):write(vim.fn.json_encode(mergedCache), "w")
	end
end

function M.getCachedContext(config)
	local cache = M.getCache()

	if cache and cache.activeContext ~= nil then
		return cache.activeContext
	else
		local firstContext = config.active[1]
		Path:new(navi_cache_path):write(
			vim.fn.json_encode({
				activeContext = firstContext,
			}),
			"w"
		)
		return firstContext
	end
end

--------------------
-- ACTIVE CONTEXT --
--------------------
local activeContext

function M.getActiveContext(config)
	if activeContext then
		return activeContext
	end

	if config.persistContext then
		return M.getCachedContext(config)
	else
		return config.active[1]
	end
end

function M.setActiveContext(context, config)
	if not context or context == activeContext then
		return
	else
		M.handleContextChange(context, config)
	end

	activeContext = context

	if config.persistContext then
		M.writeCache({
			activeContext = context,
		})
	end
end

function M.handleContextChange(context, config)
	local maps = config.mappings
	local contexts = config.contexts

	if context == nil or not contexts[context] then
		return
	end

	for key, value in pairs(contexts[context]) do
		if contexts[context][key] and maps[key] then
			vim.keymap.set("n", maps[key], value, { desc = context .. " " .. key, noremap = true })
		else
			pcall(vim.keymap.del, "n", maps[key])
		end
	end

	require("navi.ui").updateStatusLineContext(context)
end

return M
