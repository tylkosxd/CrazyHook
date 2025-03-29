--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Logics module ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Built-in logics (functions):
ffi.cdef"typedef int (*Logic)(struct ObjectA*);"

-- Add directory names as prefix for a custom logics. Colon ":" is used as a separator.
local function formatAndPrefix(str)
    str = str:match"LOGICS\\(.*)"
    if str then
        return str:gsub("\\", ":")..":"
    end
	return ""
end

local LL = {
	Environment = {}, -- name -> function
	CustomLogics = {}, -- name -> local logic
	GlobalLogics = {} -- name -> global logic
}

-- Loads logics from a folder and its subfolders:
LL.LoadFolderRecursive = function(path)
	if not DirExists(path) then return end
	LL.LoadFolder(path)
	for filename in lfs.dir(path) do
		if filename:sub(1,1) ~= "." then
			LL.LoadFolderRecursive(path.."\\"..filename)
		end
	end
end

-- Loads main.lua:
LL.LoadCustomMain = function(logicspath)
    local menv, err = loadfile(logicspath.."\\main.lua")
    assert(menv, err)
	local temp = setmetatable({}, {__index = _G})
    setfenv(menv, temp)
    menv()
	-- ensure the logics are not overwritten:
	for k, v in pairs(temp) do
		if not LL.Environment[k] then
			LL.Environment[k] = v
		else
			MessageBox('Error loading value from Main.lua - ' .. k .. "' already exists in the custom level's environment!")
		end
	end
end

-- Loads logics from a single folder:
LL.LoadFolder = function(path, global)
    local mainLuaScript = false
	for filename in lfs.dir(path) do repeat
		if #filename <= 4 then break end
		local logicName = filename:match"(.*)%.[Ll][Uu][Aa]$"
		if not logicName then break end
		local prefix = formatAndPrefix(path)
		logicName = prefix .. logicName
        mainLuaScript = logicName:lower() == "main" or mainLuaScript -- main.lua should be loaded last.
		filename = path .. "\\" .. filename
		local chunk, err = loadfile(filename)
		assert(chunk, err)
		local temp = setmetatable({}, {__index = _G})
		setfenv(chunk, temp)
		chunk()
		if not temp["main"] then break end
		if global then
			LL.GlobalLogics[logicName] = temp["main"]
		else
			LL.CustomLogics[logicName] = temp["main"]
		end
		LL.Environment[logicName.."Hit"] = temp["hit"]
		LL.Environment[logicName.."Attack"] = temp["attack"]
		LL.Environment[logicName.."Init"] = temp["init"]
		LL.Environment[logicName.."Destroy"] = temp["destroy"]
	until true end
    -- main.lua should be loaded last:
    if mainLuaScript then
        LL.LoadCustomMain(path)
    end
end

LL.LogicMain = function(object) -- custom logic's "main" function
	local logicName  = _GetLogicName(object)
	local fun = LL.GlobalLogics[logicName] or LL.CustomLogics[logicName]
	if type(fun) == "function" then
		fun(object)
	else
		MessageBox("No logic named '" .. logicName .. "'")
		object:Destroy()
	end
end

LL.LogicFunction = function(object, name) -- custom logic's "init", "hit", "attack", "destroy" functions
	local logicName  = _GetLogicName(object)
	local fun = LL.Environment[logicName..name]
	if type(fun) == "function" then
		fun(object)
	end
end

LL.CustomFunction = function(name, arg) -- functions from "main.lua" script
	local fun = LL.Environment[name]
	if IsCustomLevel() and type(fun) == "function" then
		fun(arg)
	end
end

LL.GetBuiltInLogic = function(name)
	local asset = ffi.new("void*[1]")
	mdl_exe._LoadAsset(Game(5)+16, name, asset)
	if asset[0] == nil then return end
	return ffi.cast("Logic*", ffi.cast("int",asset[0])+16)[0]
end

return LL