--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Plugins module ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module handles the plugins. ]]

local PLUGINS = {
    Exists = false,
    LoadOnce = false
}

PLUGINS.Table = {}

PLUGINS.MenuExec = function()
	for _, v in pairs(PLUGINS.Table) do
		local fun = v["menu"]
		if type(fun) == "function" then
			fun()
		end
	end
end

PLUGINS.MapExec = function(ptr)
    for _, v in pairs(PLUGINS.Table) do
		local fun = v["map"]
        if type(fun) == "function" then
            fun(ptr)
        end
    end
end

PLUGINS.Load = function()
	local path = GetClawPath() .. "\\Plugins"
    if not PLUGINS.LoadOnce and DirExists(path) then
        for filename in lfs.dir(path) do
            if filename:sub(-4):upper() == ".LUA" then
                local pluginName = filename:sub(1,-5)
                PLUGINS.Table[pluginName] = require("Plugins."..pluginName)
            end
        end
        PLUGINS.LoadOnce = true
    end
end

return PLUGINS