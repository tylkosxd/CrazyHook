--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Cheats module ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
-- mapping cheats

local DBGT = require'game_codes.debug_tools'
local CODES = require'game_codes.codes_list'

local minCrazyCheatID = 0x1000
local maxCrazyCheatID = 0x2FFF

local function CallIfFunction(fun)
	if type(fun) == "function" then
		fun()
	end
end

-- The list for cheats in a custom level, created with RegisterCheat function:
CODES.CustomList = {} -- cheat ID -> cheat name

CODES.MenuReset = function()
	-- remove the custom cheat from the cheats list:
	for id, name in ipairs(CODES.CustomList) do
		if CODES.CNEW[name] then
			CODES.CNEW[name] = nil
			CODES.CustomList[id] = nil
		end
	end
	-- reset new cheats:
	for _, params in pairs(CODES.CNEW) do
		CallIfFunction(params.MenuReset)
		if params.MenuReset == true then
			CallIfFunction(params.Disable)
		end
		params.Toggle = params.Toggle and 0 or nil
	end
	-- reset modified original cheats:
	for _, params in pairs(CODES.CORG) do
		params.Toggle = params.Toggle and 0 or nil
		CallIfFunction(params.MenuReset)
	end
end

CODES.TurnOnOff = function(params)
	-- Toggleable cheats:
	if params.Toggle then
		if params.Toggle == 0 then
			params.Toggle = 1
			CallIfFunction(params.Enable)
			if params.Text then
				TextOut(params.Text .. " On")
			end
			if params.InfosFlags then
				InfosDisplay[0][params.InfosFlags] = true
			end
		else
			params.Toggle = 0
			CallIfFunction(params.Disable)
			if params.Text then
				TextOut(params.Text .. " Off")
			end
			if params.InfosFlags then
				InfosDisplay[0][params.InfosFlags] = false
			end
		end
	-- One-time cheats:
	else
		CallIfFunction(params.Enable)
		if params.Text then
			TextOut(params.Text)
		end
	end
	-- Playing sound and setting the major cheat flag based on type:
	if params.Type == 0 then
		PlaySound"GAME_MAJORCHEAT"
	elseif params.Type == 1 then
		PlaySound"GAME_MINORCHEAT"
	elseif params.Type == 2 then
		if IsCustomLevel() then
			PlaySound"GAME_MINORCHEAT"
		else
			PlaySound"GAME_MAJORCHEAT"
			snRes(1,18,74) -- the major cheat flag (bool)
		end
	end
end

-- Turning on/off the modified original cheats:
CODES.TurnOnOffOrg = function(params)
	if params.Toggle == 0 then
		params.Toggle = 1
		CallIfFunction(params.Enable)
	else
		params.Toggle = 0
		CallIfFunction(params.Disable)
	end
end

CODES.Activation = function(id)
	for name, params in pairs(CODES.CORG) do
		if id == _message[name] then
			CODES.TurnOnOffOrg(params)
		end
	end

	if id > maxCrazyCheatID or id < minCrazyCheatID then return end

	for _, params in pairs(CODES.CNEW) do
		if params.ID == id then
			CODES.TurnOnOff(params)
		elseif id == _message.Teleport and params.Toggle == 1 then
			CallIfFunction(params.Teleport)
		elseif id == _message.ClawDeath and params.Toggle == 1 then
			CallIfFunction(params.ClawDeath)
		end
	end
end

CODES.RegisterSingleCheat = function(name, id, save)
	local cheatSeverity = save > 1 and 1 or save -- 0 - major, 1 - minor, 2 - minor for custom levels
	name = name:lower()
	mdl_exe._RegisterCheat(nRes(18), CODES.EncodeCode(name), id, cheatSeverity)
end

local function checkCustomCheatParams(params)
	local err = nil
	if type(params) ~= "table" then
		err = "RegisterCheat - argument must be a table."
	end
	if type(params.Name) ~= "string" then
		err = "RegisterCheat - 'Name' must be a string."
	end
	if params.Type and (type(params.Type) ~= "number" or params.Type < 0 or params.Type > 3) then
		err = "RegisterCheat - 'Type' must be an integer from 0 to 3."
	end
	if params.Enable and type(params.Enable) ~= "function" then
		err = "RegisterCheat - 'Enable' must be a function."
	end
	if params.Disable and type(params.Disable) ~= "function" then
		err = "RegisterCheat - 'Disable' must be a function."
	end
	if params.Text and type(params.Text) ~= "string" then
		err = "RegisterCheat - 'Text' must be a string."
	end
	if params.Gameplay and type(params.Gameplay) ~= "function" then
		err = "RegisterCheat - 'Gameplay' must be a function."
	end
	if params.Teleport and type(params.Teleport) ~= "function" then
		err = "RegisterCheat - 'Teleport' must be a function."
	end
	if params.ClawDeath and type(params.ClawDeath) ~= "function" then
		err = "RegisterCheat - 'ClawDeath' must be a function."
	end
	if params.Init and type(params.Init) ~= "function" then
		err = "RegisterCheat - 'Init' must be a function."
	end
	local name = params.Name:upper()
	if CODES.CNEW[name] then
		err = "RegisterCheat - Name '" .. name .. "' is already taken!"
	end
	return err
end

CODES.RegisterCustomCheat = function(params)
	local errorMessage = checkCustomCheatParams(params)
	local newID = #CODES.CustomList + 1
	params.ID = newID + 0x2000 -- custom cheats can occupy messages from 0x2001 to 0x2FFF
	if params.ID > maxCrazyCheatID then
		errorMessage = "RegisterCheat - exceeded the limit of custom cheats"
	end
	if errorMessage then
		MessageBox(errorMessage)
		return
	end
	params.Type = params.Type or 0
	params.Toggle = params.Toggle and 0 or nil
	CODES.RegisterSingleCheat(params.Name, params.ID, params.Type)
	CODES.CNEW[params.Name] = params
	CODES.CustomList[newID] = params.Name
	return params.ID
end

-- the built-in encoding:
CODES.EncodeCode = function(str)
	local encoding = {}
	for i = 1, #str do
		local letter = string.sub(str, i, i)
		local byte = string.byte(letter)
		table.insert(encoding, string.char(byte-15))
	end
	return table.concat(encoding)
end

CODES.Register = function()
	for _, params in pairs(CODES.CNEW) do
		CODES.RegisterSingleCheat(params.Name, params.ID, params.Type)
		CallIfFunction(params.LevelReset)
	end
end

CODES.Init = function()
	for _, params in pairs(CODES.CNEW) do
		CallIfFunction(params.Init)
	end
end

-- Fix: carry-over some original cheats to the next level if they are enabled:
CODES.CarryOver = function()
	for _, params in pairs(CODES.CORG) do
		if params.Toggle == 1 then
			CallIfFunction(params.CarryOver)
		end
	end
end

CODES.Gameplay = function()
	for _, params in pairs(CODES.CNEW) do
		if params.Toggle == 1 then
			CallIfFunction(params.Gameplay)
		end
	end
end

CODES.ClearGDI = DBGT.DeleteDrawingTools

CODES.Main = function(ptr)
	local cham = _chameleon[0]

	if cham == chamStates.LoadingStart then
		CODES.Register()
		CODES.RegisterSingleCheat("mparmor", 0x8072, 0) -- exists in exe, but needs to be registered here.
		DBGT.ScreenTileLayer = nil
	end
	if cham == chamStates.LoadingEnd then
		CODES.Init()
		DBGT.StopWatchStart = mdl_exe.RealTime[0] + 1500 -- 1500 ms came from testing - may not be 100% accurate
		CODES.CarryOver()
	end
	if cham == chamStates.OnPostMessage then
		local id = tonumber(ffi.cast("int", ptr))
		CODES.Activation(id)
	end
	if cham == chamStates.Gameplay then
		CODES.Gameplay()
		DBGT.Main(ptr)
	end
end

return CODES
