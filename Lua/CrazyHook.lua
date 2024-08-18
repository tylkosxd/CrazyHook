--------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------[[ CRAZY HOOK 1.4 UPDATE ]]------------------------------------------------------
--------------------------------------------------- CREATED BY KUBUS_PL AND ZAX37 ----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- REVISED BY TSXD -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
version = 1450

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Extension modules ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
ffi             = require 'ffi'
bit             = require 'bit'
local lfs       = require 'lfs'

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ C types ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
dofile 'Assets\\GAME\\MODULES\\chCdecl.lua'

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Enumerations ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
dofile 'Assets\\GAME\\MODULES\\chEnums.lua'

--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------- [[ "CrazyHook" modules ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
mdls_path 				= 'Assets.GAME.MODULES.'

mdl_exe          		= require (mdls_path .. 'chExeImports')
local mdl_codes         = require (mdls_path .. 'chCodes')
local mdl_dbg_tools     = require (mdls_path .. 'chDbgTools')
local mdl_cmd           = require (mdls_path .. 'chCommandLine')
local mdl_clwnd         = require (mdls_path .. 'chCustomLevelWindow')
local mdl_objs			= require (mdls_path .. 'chObjects')
local mdl_pals          = require (mdls_path .. 'chPalettes')
local mdl_tiles			= require (mdls_path .. 'chTiles')
local mdl_lclock        = require (mdls_path .. 'chRealTimeStopwatch')
local mdl_cmap      	= require (mdls_path .. 'chCustomMap')
local mdl_cust_save     = require (mdls_path .. 'chCustomSaves')

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Global variables ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
_nResult            = mdl_exe.nResult
_mResult            = mdl_exe.mResult
_hwnd               = mdl_exe.Hwnd
LevelBasedData      = mdl_exe.LevelBasedData
InfosDisplay        = mdl_exe.InfosDisplay
MultiMessage        = mdl_exe.MultiMessage
_chameleon          = mdl_exe.Chameleon
PlayAreaRect        = mdl_exe.PlayAreaRect
-- these should stay for the compatibility with previous version(-s):
_CurrentPowerup     = mdl_exe.CurrentPowerup
_PowerupTime        = mdl_exe.PowerupTime
_TeleportX          = mdl_exe.TeleportX
_TeleportY          = mdl_exe.TeleportY

--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Assembly part ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
dofile 'Assets\\GAME\\MODULES\\CrazyPatches.lua'

-- Private casting and private copy casting - use below functions to modify game's binary code for your custom level's sake.
-- Any change made will be automatically reversed in the main menu or on the start of a next level.

local private_cast_table = {}

function PrivateCast(setval, ctype, addr, index) -- (number, string, number[, number])
    if not index then index = 0 end
	-- set many:
	if type(setval) == "table" then
		for i, v in ipairs(setval) do
			PrivateCast(v, ctype, addr, i+index)
		end
	end
	-- set single:
    if type(addr) == "number" and addr >= 0x401000 and addr < 0x5AF000 then
        assert(type(ctype) == "string", "PrivateCast failed, C type must be a string!")
        if ctype:sub(1,4) ~= "void" and ctype:sub(-1) == "*" and ctype:sub(-2) ~= "**" then
            local temp = ffi.new(ctype:sub(1,-2).."[1]")
            temp[0] = setval
            local size = ffi.sizeof(temp)
            addr = addr + size*index
            for i = 0, size-1 do
                if not private_cast_table[addr+i] then
                    private_cast_table[addr+i] = ffi.cast("char*", addr)[i]
                end
            end
            ffi.cast(ctype, addr)[0] = setval
        else
            error("PrivateCast - wrong pointer type")
        end
    else
        error("PrivateCast - wrong address")
    end
end

function PrivateCopyCast(str, addr, force) -- (string, number, bool)
    str = tostring(str)
    if type(addr) == "number" and addr >= 0x401000 and addr < 0x5AF000 then
        local cstr = ffi.cast("char*", addr)
        for n = 0, #str do
            if not private_cast_table[addr+n] then
                private_cast_table[addr+n] = cstr[n]
            end
            if not force and n > #ffi.string(cstr) then
                if cstr[n] ~= 0 then
                    error("PrivateCopyCast - string ".. str .. " has too many characters!")
                    do return end
                end
            end
        end
        ffi.copy(cstr, str)
    else
        error("PrivateCopyCast - wrong address")
    end
end

local function _RestoreGamesCode()
    for a, v in pairs(private_cast_table) do
        ffi.cast("char*", a)[0] = v
    end
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[[[ CrazyHook core ]]]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Logics vars/tables:
_env             = setmetatable({}, {__index = _G})
_menv            = nil -- "main.lua" environment
_maplogics       = {} -- name -> local logic
_globallogics    = {} -- name -> global logic

-- Objects tables:
_objects         = {} -- ID -> object
_objects_data    = {} -- object's address -> custom data table 
_objects_names   = {} -- object's address -> object name (ones from CreateObject)

-- Debug text table:
debug_text       = {}

-- Get command-line arguments:
local cl_argv       = mdl_cmd.Get()

-- Gameplay objects pointers:
local CScreenPos = nil

-- Map-related strings:
_fullmapname    = ""
_mapname        = ""
_mappath        = ""

-- Bit module functions:
OR  = bit.bor
AND = bit.band
NOT = bit.bnot
XOR = bit.bxor
HEX = bit.tohex

-- LFS functions:
function _DirExists(filepath)
	return lfs.attributes(filepath, "mode") == "directory"
end

function _FileExists(filepath)
	return lfs.attributes(filepath, "mode") == "file" and lfs.attributes(filepath, "mode") ~= "directory"
end

function _GetFileSize(filepath)
    return lfs.attributes(filepath, "size")
end

-- Custom table function, returns true if the given table contains the given value, otherwise nil:
function table.contain(tab, val)
    for _,v in pairs(tab) do
        if v == val then
            return true
        end
    end
    return nil
end

-- Custom table function, returns key such that table[key] == value:
function table.key(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

-- Custom math function:
function math.round(n)
	n = tonumber(n)
	if n and n ~= 0 then
		local sign = n == math.abs(n)
		if sign then sign = 1 else sign = -1 end
		n = math.abs(n)
		local total = math.floor(n)
		if n - total < 0.5 then
			return sign*total
		else
			return sign*(total+1)
		end
	end
	return 0
end

-- clears table:
local function _ClearTable(t)
    for k,_ in pairs(t) do
        t[k] = nil
    end
end

-- returns location of CLAW.EXE:
function GetClawPath()
    local str = ffi.new("char[255][1]")
    mdl_exe._GetClawPath(ffi.cast("int", str), 254)
    return ffi.string(ffi.cast("const char*",str[0]))
end

-- convert Lua string into C string:
function _GetCStr(str)
    local c_str = ffi.new("char[?]", #str+1)
    ffi.copy(c_str, str)
    return c_str
end

-- simple message box:
function MessageBox(text, title)
	ffi.C.MessageBoxA(nil, tostring(text), title or "", 0)
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ Load logics ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- add dirnames as prefix for a custom logics:
local function _lp(str)
    str = str:match"LOGICS\\(.*)"
    if str then
        return str:gsub("\\", ":")..":"
    end
	return ""
end

-- iterate over all subfolders and map logics in all of them:
function _lls(logicspath)
	_ll(logicspath)
	for filename in lfs.dir(logicspath) do
		if _DirExists(logicspath.."\\"..filename) and filename ~= "." and filename ~= ".." then
			_lls(logicspath.."\\"..filename)
		end
	end
end

-- load main.lua:
function _lmain(logicspath)
    if _FileExists(logicspath.."\\main.lua") then
		local err = nil
		_menv, err = loadfile(logicspath.."\\main.lua")
		assert(_menv, err)
		setfenv(_menv, _env)
		_menv()
	end
end

-- load logics from a single folder:
function _ll(logicspath, global)
    local prefix = _lp(logicspath)
	for filename in lfs.dir(logicspath) do
		if string.lower(filename) ~= "main.lua" and #filename > 4 then 
            filename = logicspath .. "\\" .. filename
		else 
            filename = "" 
        end
		if _FileExists(filename) then
			local fname = filename:match'.*\\(.*)%.lua'
			if fname then
				local chunk, err = loadfile(filename)
				assert(chunk, err)
				local _test = setmetatable({}, {__index = _G})
				if _menv then setfenv(_menv, _test) _menv() end
				setfenv(chunk, _test)
				chunk()
				if _test["main"] then
                    fname = prefix..fname
					if global then 
						_globallogics[fname] = _test["main"]
					else
                        _maplogics[fname] = _test["main"]
					end
					_env[fname.."Hit"] = _test["hit"]
					_env[fname.."Attack"] = _test["attack"]
					_env[fname.."Init"] = _test["init"]
					_env[fname.."Destroy"] = _test["destroy"]
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Internal Core ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- exceptions handling:
function _exception(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	MessageBox("_exception\n" .. debug.traceback())
end

-- the link between Lua and the DLL:
function _lua(fnName, ptr)
	local fn = _G[fnName]
	if type(fn) ~= "function" then
		MessageBox("Core function " .. fnName .. " doesn't exist!", "Critical error")
	else
		xpcall(function()
			fn(ptr)
		end,
		function(err)
			MessageBox(err .. "\n" .. debug.traceback(), fnName .. " error")
		end)
	end
end

-- on object's creation:
function _create(ptr)
    local addr = tonumber(ffi.cast("int", ptr))
	local object = ffi.cast("ObjectA*", addr)
	object.MoveClawX, object.MoveClawY = 0, 0
    if not _objects[object.ID] then
	    _objects[object.ID] = object
    end
	if not _objects_data[addr] then
		_objects_data[addr] = {}
	end
	mdl_exe._RegisterHitHandler(object, "CustomHit")
	mdl_exe._RegisterAttackHandler(object, "CustomAttack")
end

-- call "main" function of a custom logic:
function _logic(ptr)
    local addr = tonumber(ffi.cast("int", ptr))
    local object = ffi.cast("ObjectA*", addr)
	assert(_objects_data[addr])
	local name = _GetLogicName(object)
	local logic = nil
	if _globallogics[name] then 
        logic = _globallogics[name]
	else
        logic = _maplogics[name]
    end
	if type(logic) == "function" then
        logic(object)
	else
        MessageBox("No logic named '" .. name .. "'")
        object:Destroy()
    end
end

-- call "hit" function of a custom logic:
function _hit(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	local fun = _env[_GetLogicName(object).."Hit"]
	if type(fun) == "function" then
		fun(object)
	end
end

-- call "attack" function of a custom logic:
function _attack(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	local fun = _env[_GetLogicName(object).."Attack"]
	if type(fun) == "function" then
		fun(object)
	end
end

-- call when an object is destroyed:
function _destroy(ptr)
    local addr = tonumber(ffi.cast("int", ptr))
	local object = ffi.cast("ObjectA*", ptr)
	local fun = _env[_GetLogicName(object).."Destroy"]
	if type(fun) == "function" then
		fun(object)
	end
    if object.ID ~= -1 then
        _objects[object.ID] = nil
    end
end

-- restores the game state, mostly:
function _free()
	mdl_exe.NoEffects[0] = 0
    _RestoreGamesCode()
	_DoOnlyOnce = false
    _env["OnMapLoad"] = nil
	_env["OnMapLoad2"] = nil
    _env["OnGameplay"] = nil
	_env["OnLevelEnd"] = nil
    _menv = nil
    _ClearTable(private_cast_table)
    _ClearTable(_maplogics)
    _ClearTable(_objects)
    _ClearTable(_objects_data)
    _ClearTable(_objects_names)
	mdl_cmap.MusicTracks = {"LEVEL", "POWERUP", "MONOLITH"}
	CustomPowerupPointer = nil
	ResetMultiMessage()
	_mappath = ""
    _mapname = ""
	_fullmapname = ""
end

-- The menu start hook:
function _menu()
    mdl_codes.MenuReset()
	_free()
	-- Modding API:
	if _ModdingAPIEnabled then
		for _, v in pairs(_GameModsTab) do
			if v["menu"] and type(v["menu"]) == "function" then
				v["menu"](ptr)
			end
		end
	end
end

-- Chameleon:
function _map(ptr)

	-- Internal modules:
	mdl_codes.Cheats(ptr)
	mdl_clwnd.CustomLevelWindow(ptr)
    mdl_cmd.Map(cl_argv)
    mdl_lclock(ptr)
    mdl_cmap.LoadAssets(ptr)
    mdl_cust_save.Load()
	
	-- Modding API - external plugins:
	if _ModdingAPIEnabled then
		for _, v in pairs(_GameModsTab) do
			if v["map"] and type(v["map"]) == "function" then
				v["map"](ptr)
			end
		end
	end
        
	-- Map custom logics:
	if _chameleon[0] == chamStates.LoadingAssets then
		if _mappath ~= "" then
			local logicspath = _mappath .. "\\LOGICS"
			if _DirExists(logicspath) then 
				_lls(logicspath)
			    _lmain(logicspath)
			end
		end
	end
    
	-- Map all objects:
	if _chameleon[0] == chamStates.LoadingObjects then
		if not _DoOnlyOnce then
			_DoOnlyOnce = true
            if _mappath ~= "" and _DirExists(_mappath.."\\LOGICS") then
				local fun = _env["OnMapLoad"]
			    if type(fun) == "function" then 
                    fun()
                end 
            end
			--CreateObject{name="_TestLogic"}
		end
        local addr = tonumber(ffi.cast("int", ptr))
        local object = ffi.cast("ObjectA*", addr)
        --[[ Uncomment to check for objects with the same ID:
        if _objects[object.ID] then
            MessageBox("Found objects with the same ID " .. object.ID .. ": \nImage = '" .. GetImgStr(_objects[object.ID].Image) .. "', 
			X = " .. _objects[object.ID].X .. ", Y = " .. _objects[object.ID].Y .. ", Logic = " .. GetLogicAddr(_objects[object.ID]) .. ", 
			Name = " .. _GetLogicName(_objects[object.ID]) .."\nImage = '".. GetImgStr(object.Image).."', X = " .. object.X .. ", 
			Y = " .. object.Y .. ", Logic = " .. GetLogicAddr(object) .. ", Name = " .. _GetLogicName(object))
        end ]]
		_objects[object.ID] = object
		if not _objects_data[addr] then
			_objects_data[addr] = {}
		end
		local init = _env[_GetLogicName(object).."Init"]
		if type(init) == "function" then
			init(object)
		end
	end

	
    if _chameleon[0] == chamStates.LoadingEnd then
		if _mappath ~= "" then
			if not CScreenPos then
				CScreenPos = LoopThroughObjects(function(obj) if obj.Logic == CaptainClawScreenPosition then return obj end end)
			end
			local fun = _env["OnMapLoad2"]
			if type(fun) == "function" then 
                fun()
            end
			RegisterCheat{Name = "mptiesto", ID = 0x8064, Toggle = 0, Text = "Tiesto mode"}
        end
    end
	
	if _chameleon[0] == chamStates.OnPostMessage then
		local id = tonumber(ffi.cast("int", ptr))
		if _mappath ~= "" then
			if id == _message.ExitLevel or id == _message.LevelEnd or id == _message.MPMOULDER or (id >= 0x809C and id <= 0x80A9) then
				local fun = _env["OnLevelEnd"]
				if type(fun) == "function" then 
					fun()
				end
				if id ~= _message.ExitLevel then
					_free()
				end
			end
		end
		if id == 670 then
			mdl_exe._ChangeResolution(nRes(), nRes(31), nRes(32))
		elseif id == 671 then
			mdl_exe._BnW(nRes(11,11))
		end
	end

	if _chameleon[0] == chamStates.Gameplay then
        if _mappath ~= "" then
            mdl_cust_save.Save()
			local fun = _env["OnGameplay"]
			if type(fun) == "function" then
                fun(tonumber(ffi.cast("int", ptr)))
            end
        end
		--[[
		if not tr then
			tr = GetMainPlane():CreateTileLayer(60, 40, 3, 3):Resize(7,7):Offset(3, 3)
		end
		if not xxx and GetInput"Special" then
			local somefun = function(params) 
				if params.PlaneTile == -1 then 
					return 56 
				end
			end
			tr:Offset(math.random(-1, 1), math.random(-1,1), 0xEEEEEEEE):Anchor()
			xxx = true
		end
		if xxx and not GetInput"Special" then
			xxx = false
		end
		]]
		mdl_dbg_tools.HealthBars(ptr)
		mdl_dbg_tools.DebugRects(ptr)
		mdl_dbg_tools.DebugText(ptr)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Assets ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function LoadPalette(filename)
	mdl_pals.LoadPalette(filename, nRes(11)+0x360)
end

function LoadFolder(name)
	return mdl_exe._LoadFolder(nRes(13), name)
end

function LoadAsset(name)
	local asset = ffi.new("void*[1]")
	mdl_exe._LoadAsset(Game(10)+16, name, asset)
	return asset[0]
end

function LoadAssetB(name)
	local asset = ffi.new("void*[1]")
	mdl_exe._LoadAsset(Game(4)+16, name, asset)
	return asset[0]
end

function MapSoundsFolder(address,short)
	mdl_exe._MapSoundsFolder(nRes(11,3,10), address, short, "_")
end

function MapImagesFolder(address,short)
	mdl_exe._MapImagesFolder(nRes(11,3,4), address, short, "_")
end

function MapAnisFolder(address,short)
	mdl_exe._MapAnisFolder(nRes(11,3,11), address, short, "_")
end

function LoadSingleFile(address,name,constant)
	return mdl_exe._LoadSingleFile(address,name,constant)
end

function MapMusicFile(address,name)
	local mus = LoadSingleFile(address, name, 0x584D49)
	if mus then
		local _var = ffi.cast("int*", mus)[3]
		mus = mdl_exe._GetMusicAddr(mus)
		if mus then
            table.insert(mdl_cmap.MusicTracks, name)
			mdl_exe._MapMusicFile(nRes(20), mus, _var, name)
		end
	end
end

function IncludeAssets(path)
    local inst = ffi.cast("char*",0x4B720F)
    local oper = ffi.cast("unsigned int*", 0x4B7210)
    inst[0] = 0xE8 -- CALL
    oper[0] = 0xFFFFEEDC -- 004B60F0
	local ret = mdl_exe._IncludeAssets(nRes(13), path, 0)
	return ret
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Game Manager ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function nRes(...)
    return CastGet(_nResult[0], select(1, ...))
end

function snRes(x, ...)
    CastSet(x, _nResult[0], select(1, ...))
end

function Game(...)
    return CastGet(_nResult[0][12], select(1, ...))
end

function CastGet(v, ...)
    for i = 1, select("#", ...) do   
        v = ffi.cast("int*", v)[select(i, ...)]
    end
    return v
end

function CastSet(x, v, ...)
    local count = select("#", ...)
    for i = 1, count - 1 do
        v = ffi.cast("int*", v)[select(i, ...)]
    end
    ffi.cast("int*", v)[select(count, ...)] = x
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- [[[[ Custom Logics API functions ]]]] ------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function GetGameType()
	return ffi.cast("int*", nRes(11,0,4)+1)[0]
end

function GetMapName()
	return ffi.string(ffi.cast("const char*", nRes(49)))
end

function GetMapFolder()
    return _mappath
end

function GetTime()
	return mdl_exe.MsCount[0]
end
GetTicks = GetTime

function GetRealTime()
    return mdl_exe.RealTime[0]
end
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Cheats ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function CheatsUsed()
	return nRes(18,74) ~= 0
end

function RegisterCheat(params)
	mdl_codes.RegisterCustomCheat(params)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Camera ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function CameraToPoint(x, y)
	mdl_exe.CameraX[0] = x
	mdl_exe.CameraY[0] = y
	if CScreenPos and CScreenPos.State ~= 8888 then
		CScreenPos.State = 8888
	end
end

function CameraToObject(object)
	mdl_exe.CameraX[0] = object.X
	mdl_exe.CameraY[0] = object.Y
    if CScreenPos and CScreenPos.State ~= 8888 then
		CScreenPos.State = 8888
	end
end

function GetCameraPoint()
    return ffi.cast("Point*", Game(9,23)+132)[0]
end
GetCameraPos = GetCameraPoint

function SetCameraPoint(x, y)
	if CScreenPos then
		CScreenPos.State = 9000
		local data = ffi.cast("int*", CScreenPos._v._p)
		data[0] = x
		data[1] = y
		data[2] = data[0]
		data[3] = data[1]
	else
		MessageBox("Couldn't find the CaptainClawScreenPosition logic")
	end
end
SetCameraPos = SetCameraPoint

function SetCameraToPointSpeed(x, y) -- default: 400, 400
    PrivateCast(x, "int*", 0x48971D)
    PrivateCast(y, "int*", 0x489722)
end

function CameraToClaw()
    if CScreenPos and CScreenPos.State ~= 26 and CScreenPos.State ~= 5003 then
        CScreenPos.State = 24
    end
	mdl_exe.CameraX[0] = -1
	mdl_exe.CameraY[0] = -1
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Level ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

LoadBaseLevDefaults = mdl_exe._LoadBaseLevDefaults

function SetDeathType(t)
    LevelBasedData[0].DeathTileType = t
    LevelBasedData[1].DeathTileType = t
end

function SetBoss(object)
    if not object or object == 0 then
	    ffi.cast("int*", mdl_exe.CurrentBoss)[0] = 0
    else
        mdl_exe.CurrentBoss[0] = object
    end
end

function GetBoss()
	return mdl_exe.CurrentBoss[0]
end

function GetMapWidth()
    return Game(9,23,12)
end

function GetMapHeight()
    return Game(9,23,13)
end

function InMapBoundaries(x,y)
    return x >= 0 and x < Game(9,23,12) and y >= 0 and y < Game(9,23,13)
end

function SetBossFightPoint(x, y)
    if InMapBoundaries(x,y) then
        LevelBasedData[0].MPSkinnerPosX = x
	    LevelBasedData[0].MPSkinnerPosY = y
    else
        error("SetBossFightPoint - coordinates out of main plane boundaries")
    end
end

function Earthquake(t)
	mdl_exe._Quake(tonumber(t) or 1000)
end

function GetTreasuresNb(n)
	if type(n) == "number" and n >= 0 and n <= 8 then 
        return mdl_exe.TreasuresCountTable[n]
	else
		error("GetTreasuresNb - wrong treasure type ".. n)
    end
end

function RegisterTreasure(n, nb)
	if nb == nil then 
        nb = 1 
    end
	if n >= 0 and n <= 8 then 
        mdl_exe.TreasuresCountTable[n] = mdl_exe.TreasuresCountTable[n]+nb
    end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Inputs ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
local function VKcode(key)
	if VKey[key] then 
        return VKey[key] 
    elseif type(key) == "string" and #key == 1 and tonumber(key) then
        return 0x30 + tonumber(key)
	else
		return key
    end
end

function GetInput(input)
    if not input then
	    return mdl_exe.Inputs[0][0].InputState2
    else
        local flag = InputFlags[input]
        return AND(mdl_exe.Inputs[0][0].InputState2, flag) ~= 0
    end
end

function KeyPressed(key)
	if InputFlags[key] then
		key = mdl_exe.Inputs[0][0].Keyboard[key]
	else
		key = VKcode(key)
	end
	return mdl_exe._KeyPressed(key) ~= 0
end

function GetKeyInput(key)
	if InputFlags[key] then
		key = mdl_exe.Inputs[0][0].Keyboard[key]
	else
		key = VKcode(key)
	end
	return ffi.C.GetAsyncKeyState(key) == -32768
end
GetVKInput = GetKeyInput

function InputPress(key)
	if InputFlags[key] then
		key = mdl_exe.Inputs[0][0].Keyboard[key]
	else
		key = VKcode(key)
	end
	local input = ffi.new("Input[1]")
	input[0].iType = 1
	input[0].ki = {key, 0, 0, 0, nil}
	return ffi.C.SendInput(1, input, ffi.sizeof(input))
end

function InputRelease(key)
	if InputFlags[key] then
		key = mdl_exe.Inputs[0][0].Keyboard[key]
	else
		key = VKcode(key)
	end
	local input = ffi.new("Input[1]")
	input[0].iType = 1
	input[0].ki = {key, 0, 2, 0, nil}
	return ffi.C.SendInput(1, input, ffi.sizeof(input))
end

function GetCursorPos()
    local p = ffi.new("Point[1]")
    ffi.C.GetCursorPos(p)
    return p[0]
end

function GetGameControls()
	return mdl_exe.Inputs[0][0]
end

--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------- [[ Claw ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function GetClaw()
	return mdl_exe.Claw[0]
end

function PlayerData()
	return GetClaw()._v._p
end
PData = PlayerData

function Attempt()
	return tonumber(PlayerData().AttemptNb)
end
Attemp = Attempt

function GetRespawnPoint()
	return ffi.cast("Point*", nRes(11)+68)
end

function GetClawAttackType(str)
    if not str then 
        return AttackString[1+PlayerData().AttackType]
    else
        return AttackString[1+PlayerData().AttackType]:match(".-(" .. string.lower(tostring(str)) .. ").-")
    end
end

function BlockClaw()
	ffi.cast("void (*)()", 0x421450)()
end

function Teleport(x,y)
	mdl_exe.TeleportX[0] = x
	mdl_exe.TeleportY[0] = y
	ffi.C.PostMessageA(nRes(1,1), 0x111, 0x805C, 0);
end
TeleportClaw = Teleport

function KillClaw()
	if GetClaw().Health ~= 0 then
		GetClaw().Health = 0
	end
	mdl_exe._KillClaw(GetClaw(), GetClaw()._v, PData(), 0)
end

function ClawTakeDamage(damage)
	GetClaw().Health = GetClaw().Health - damage
	if GetClaw().Health <= 0 then
		KillClaw()
	end
end

function ClawJump(height)
	mdl_exe._ClawJump(GetClaw(), height)
end

function SetRespawnPoint(x,y)
    if x and y then
        if InMapBoundaries(x,y) then
            snRes(x,11,17)
		    snRes(y,11,18)
        else
	        error("SetRespawnPoint - coordinates out of main plane boundaries")
        end
    else
        snRes(GetClaw().X,11,17)
	    snRes(GetClaw().Y,11,18)
    end
end

function StunClaw(ms)
    snRes(ms or 0,11,473)
end

function SetRunningSpeedTime(t)
    local _at = { 0x7AB4, 0x7AF6, 0x842F, 0x8547, 0x866D, 0x8F9F, 0x90F3, 0x9203, 0x92A3, 0x9730, 0x9B00, 
    0x9CC3, 0x9CF9, 0x9FF7, 0xA09D, 0xAC4B, 0xACFE, 0xAD8F, 0xB0C2, 0xB2D6, 0xB791, 0xBB54, 0xBC14, 
    0xBC98, 0xC6FD, 0xC9A5, 0xCBBE, 0xCBF0, 0xD60C, 0x11108, 0x112ED, 0x1158E, 0x11637, 0x11A1D }
    for _, addr in ipairs(_at) do
        ffi.cast("int*", 0x410000+addr)[0] = t
    end
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Claw Powerups ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function GetCurrentPowerup()
	return _CurrentPowerup[0]
end 

function GetCurrentPowerupTime()
    return _PowerupTime[0]
end

function ClawGivePowerup(powerupId, time)
	mdl_exe._ClawGivePowerup(powerupId, time * 1000)
end

function CustomPowerup(name, time)
	if not name then return end
    if _PowerupTime[0] == 0 or _CurrentPowerup[0] ~= Powerup.Custom then
        CustomPowerupPointer = nil
    end
	if not time then 
        time = 20000
    end
    if PlayerData()._CGlit ~= 0 then
		PlayerData().CatnipGlitter:Destroy()
		PlayerData()._CGlit = 0
	end
	if CustomPowerupPointer ~= nil and CustomPowerupPointer.CPN ~= name then
		CustomPowerupPointer:Destroy()
		CustomPowerupPointer = nil
		mdl_exe._ClawGivePowerup(0,0)
	end
	mdl_exe._ClawGivePowerup(Powerup.Custom, time)
	if CustomPowerupPointer == nil then 
		CustomPowerupPointer = CreateObject {name="_ClawCPowerup"} 
	end
	CustomPowerupPointer.Flags.AlwaysActive = true
	CustomPowerupPointer.CPN = name
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Music ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function SetMusic(name)
	mdl_exe._SetMusic(nRes(20), string.upper(name), 1)
end

function SetMusicSpeed(value, time)
	local t = ffi.cast("int", time*1000)
	if t > 50000 then
		t = 50000
	end
	mdl_exe._SetMusicSpeed(nRes(20,7), value, t)
end

function GetMusicTracks()
    return mdl_cmap.MusicTracks
end

function GetMusicState(name)
    name = string.upper(name)
    if table.contain(mdl_cmap.MusicTracks, name) then
        local ptr = mdl_exe._GetMusic(nRes(20), name)
        return mdl_exe._GetMusicState(ptr) ~= 0
    else
        error("GetMusicState - no music named ".. name)
    end
end

function StopMusic(name)
    if not name then
        for _, v in ipairs(mdl_cmap.MusicTracks) do
            if GetMusicState(v) then
                name = v
            end
        end
    end
    if name then
        local music_plays = GetMusicState(name)
	    if music_plays then
		    local ptr = mdl_exe._GetMusic(nRes(20), string.upper(name))
            ffi.cast("int(*__thiscall)(int*)", ffi.cast("int**", ptr)[0][8])(ptr)
        end
    end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Sounds ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function PlaySound(name, volume, stereo, pitch, loop)
	local sound = mdl_exe._GetSoundA(Game(10), name)
	if not volume or volume == 1 then
		volume = mdl_exe.SoundVolume[0]
	elseif volume >= 3 then
		volume = 3*mdl_exe.SoundVolume[0]
	elseif volume <= 0 then
		volume = 0
	else
		volume = volume*mdl_exe.SoundVolume[0]
	end
	mdl_exe._PlaySound(sound, volume, stereo or 0, pitch or 0, loop or 0)
end

function ClawSound(name)
	mdl_exe._ClawSound(name,0)
end

function ReplaceSound(name1, name2)
    local sound_ptr1 = mdl_exe._GetSound(Game(10)+16, name1)
	local sound_ptr2 = mdl_exe._GetSound(Game(10)+16, name2)
	sound_ptr1[0] = sound_ptr2[0]
end

function SwapSound(name1, name2)
    local sound_ptr1 = mdl_exe._GetSound(Game(10)+16, name1)
	local sound_ptr2 = mdl_exe._GetSound(Game(10)+16, name2)
    local temp = sound_ptr1[0]
	sound_ptr1[0] = sound_ptr2[0]
    sound_ptr2[0] = temp	
end

function RemoveSound(name)
    local sound_ptr1 = mdl_exe._GetSound(Game(10)+16, name)
	local sound_ptr2 = mdl_exe._GetSound(Game(10)+16, "GAME_NULL")
	sound_ptr1[0] = sound_ptr2[0]
end

function StopSound(name)
	local sound = mdl_exe._GetSoundA(Game(10), name)
    if sound[4] then
		mdl_exe._StopSound(sound)
	end
end

function EnemySound(object, name)
    local sound = mdl_exe._GetSoundA(Game(10), name)
    mdl_exe._EnemySound(object, sound, 0)
end

--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- [[ Graphics ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

GetImage = LoadAssetB

function GetImgStr(ch)
	local str = ffi.cast("const char*",ffi.cast("int",ch)+36)
	if ffi.cast("int",str) > 36 then
        return ffi.string(str) 
    end
    return ""
end
GetImageName = GetImgStr

function ChangeResolution(width, height)
	local minPlaneWidth = width/64
	local minPlaneHeight = height/64
	for i = 0, PlanesCount()-1 do
		local plane = GetPlane(i)
		if plane ~= nil and (plane.Width < minPlaneWidth or plane.Height < minPlaneHeight) then
			MessageBox("Plane with index " .. i .. " is too small for this resolution!")
			plane.Flags.NoDraw = true
		end
	end
	snRes(width, 31)
	snRes(height, 32)
	ffi.C.PostMessageA(nRes(1,1), 0x111, 670, 0)
end

function SetHighDetails()
    snRes(1, 105)
end
    
function SetLowDetails()
    snRes(0, 105)
end

function GetDetailsState()
    return nRes(105)
end

function SetImgFlag(img, flag) 
    if type(img) == "string" then
        img = GetImage(img)
    end
    if img ~= nil then
        if flag > 0 and flag <= 7 and flag ~= 4 then
            mdl_exe._SetImgFlag(img, flag)
        else
            error("SetImgFlag - invalid image flag " .. flag)
        end
    else
        error("SetImgFlag - invalid image")
    end
end

function SetImgColor(img, color) 
    if type(img) == "string" then
        img = GetImage(img)
    end
    if img then
        if color then
            mdl_exe._SetImgColor(img, color)  
        else
            error("SetImgColor - invalid color")
        end
    else
        error("SetImgColor - invalid image")
    end
    --[[ -- reverse-engineered:
    if object.Image ~= nil then
        assert(type(color) == "number")
        local img = ffi.cast("int*", object.Image)
        local frame = img[25] -- the first frame
        local lastFrame = img[26]
        while frame < lastFrame do
            if CastGet(img, 5, frame) ~= 0 then
                CastSet(color, img, 5, frame, 12, 6)
            end
            frame = frame+1
        end
    end
    ]]
end

function SetImgCLT(img, clt)
    if type(img) == "string" then
        img = GetImage(img)
    end
    if img ~= nil then
        if string.upper(clt) == "LIGHT" then
            mdl_exe._SetImgCLT(img, nRes(11,474))
        elseif string.upper(clt) == "AVERAGE" then
            mdl_exe._SetImgCLT(img, mdl_exe.AverageCLT[0])
        else
            error("SetImgCLT - invalid color table " .. clt .. "\n Use 'Average' or 'Light'")
        end
    else
        error("SetImgCLT - invalid image")
    end
end
SetImgClt = SetImgCLT

--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- [[ Palettes ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function BnW()
	ffi.C.PostMessageA(nRes(1,1), 0x111, 671, 0)
end

function CreatePalette()
	return ffi.new("CPalette")
end

function GetHtmlColor(color)
	if type(color) == "string" then
		local html = assert(color:match"(#%d%d%d%d%d%d)", "Could not match color to the html format")
		local red = tonumber(html:sub(2, 3), 16)
        local green = tonumber(html:sub(4, 5), 16)
        local blue = tonumber(html:sub(6, 7), 16)
		return ffi.new("CColor", {red, green, blue})
	else
		error("GetHtmlColor - string expected")
	end
end

function GetFirstPalette()
	local new = ffi.new("CPalette")
	mdl_pals.Copy(new, nRes(11)+0x360)
	return new
end

function GetCurrentPalette()
	local new = ffi.new("CPalette")
	mdl_pals.Copy(new, nRes(11,11,4,4))
	return new
end

function LoadPaletteFile(filename)
	return mdl_pals.LoadPalette(filename)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Palette methods ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

_cpalette = {}

function _cpalette:Set()
	mdl_pals.Copy(nRes(11,11,4,4), self)
    mdl_exe._SetPalette(nRes(11,11,4), 0)
	return self
end

function _cpalette:InvertColors()
    mdl_pals.Invert(self)
	return self
end

function _cpalette:AdjustRGB(r, g, b, min, max)
	mdl_pals.AdjustRGB(self,r,g,b,min,max)
	return self
end

function _cpalette:AdjustHSL(h, s, l, min, max)
    mdl_pals.AdjustHSL(self,h,s,l,min,max)
	return self
end

function _cpalette:BlackAndWhite()
	mdl_pals.BlackAndWhite(self)
	return self
end

function _cpalette:ExportToFile(filename)
    mdl_pals.ExportToFile(self, filename)
	return self
end

function _cpalette:CreateLightCltFile(filename)
    mdl_pals.CreateLightCltFile(self, filename)
	return self
end

function _cpalette:CreateAverageCltFile(filename)
    mdl_pals.CreateAverageCltFile(self, filename)
	return self
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ Color Lookup Tables ]] -----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function LoadAverageCLT(filename)
    mdl_pals.LoadCLT(filename, mdl_exe.AverageCLT[0][2])
end

function LoadLightCLT(filename)
    mdl_pals.LoadCLT(filename, nRes(11,474,2))
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ Multiplayer ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function SendMultiPlayerMessage(message0, message1, message2, affects_player)
    local args = ffi.new("int[5]", {0x3F2, message1 or 0, message2 or 0, message0, 0})
    if GetGameType() == GameType.MultiPlayer then
        mdl_exe._SendMultiMessage(nRes(11), args, 1)
    end
    if affects_player then
        MultiMessage[0] = message0
		MultiMessage[1] = message1
		MultiMessage[2] = message2
    end
end
SendMPMessage = SendMultiPlayerMessage

function ResetMultiMessage()
    for i = 0,2 do
        MultiMessage[i] = 0
    end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Objects ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function CreateObject(params)
	return mdl_objs.CreateObject(params)
end

function GetAvailableID()
	return mdl_objs.GetAvailableID()
end
GetEmptyID = GetAvailableID

function LoopThroughObjects(fun, arg)
    return mdl_objs.LoopThroughObjects(fun, arg)
end

function GetObject(id)
	return _objects[id]
end

function CreateGoodie(tab)
	mdl_objs.CreateGoodie(tab)
end

function CreateHUDObject(Rx, Ry, Rz, image)
    return mdl_objs.CreateHUDObject(Rx, Ry, Rz, image)
end

function LoopThroughInterfaces(fun, arg)
    return mdl_objs.LoopThroughInterfaces(fun, arg)
end

function GetInterface(name, digit)
	return mdl_objs.GetInterface(name, digit)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Object's methods ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

_objectA = {}

function _objectA:Destroy()
	self.Flags.flags = 0x10000
end

function _objectA:Physics(x, y)
	return mdl_exe._Physics(Game(9), self, x, y, 8)
end

function _objectA:IsVisible(x)
	return mdl_exe._IsVisible(Game(9), self.X, self.Y, x, 32)
end

function _objectA:AlignToGround()
	mdl_exe._AlignToGround(Game(9), self, 0)
end

function _objectA:GetSelf()
	return tonumber(ffi.cast("int",self))
end

function _objectA:SetImage(name)
	mdl_exe._SetImage(self, name)
end

function _objectA:SetAnimation(name)
	mdl_exe._SetAnimation(self, name, 0)
end

function _objectA:SetFrame(nb)
	mdl_exe._SetImageAndI(self, GetImgStr(self.Image), nb)
end

function _objectA:SetSound(name)
    mdl_exe._SetSound(self, name)
end

function _objectA:AnimationStep()
	mdl_exe._AnimationStep(tonumber(ffi.cast("int",self)) + 0x1A0, mdl_exe.FrameTime[0])
end

function _objectA:IsBelow(object)
	if object ~= nil then
		return object.Flags.OnElevator and object.ObjectBelow == self
	end
end

--[[
function Object:_ResetName() -- DANGER
	self._Name = ffi.cast("const char*",0x52c67c)
end
]]

function _objectA:DropCoin()
	CreateGoodie {x=self.X, y=self.Y, z=self.Z}
end

function _objectA:GetData()
	return _objects_data[tonumber(ffi.cast("int", self))]
end

function _objectA:ShowData()
	local str = ""
	for k,v in pairs(self:GetData()) do
		str = str .. k .. "\n"
	end
	MessageBox("data:\n" .. str)
end

function _objectA:CreateGlitter(img)
    mdl_objs.CreateGlitter(self, img)
end

function _objectA:DestroyGlitter()
    if self.GlitterPointer ~= nil then
        self.GlitterPointer:Destroy()
    end
end

function _objectA:GetAction()
    return mdl_objs.GetAction(self)
end

function _objectA:DialogSound(name)
    mdl_exe._EnemySound(self, mdl_exe._GetSoundA(Game(10), name), 0)
end

function _objectA:InRect(obj, rect)
	return mdl_objs.InRect(self, obj, rect)
end

function _objectA:InMinMax(obj)
	if obj ~= nil then
		return self.X > obj.XMin and self.Y > obj.YMin and self.X < obj.XMax and self.Y < obj.YMax
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Tile properties ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function GetTileA(id)
    return mdl_tiles.GetTileA(id)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Planes ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function PlanesCount()
	return Game(9,15)
end

function GetMainPlane()
    return ffi.cast("CPlane*", Game(9, 14, Game(9,23,1)))
end

function GetFrontPlane()
    return ffi.cast("CPlane*", Game(9, 14, PlanesCount() - 1))
end

function GetPlane(index)
    if index < 0 or index >= PlanesCount() then
        return nil
    end
	return ffi.cast("CPlane*", Game(9, 14, index))
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ Plane methods ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

_cplane = {}

function _cplane:GetTile(x, y)
	return mdl_tiles.PlaneMethods.GetTile(self, x, y)
end

function _cplane:PlaceTile(x, y, tile)
	return mdl_tiles.PlaneMethods.PlaceTile(self, x, y, tile)
end

function _cplane:ColorTile(x, y)
	return mdl_tiles.PlaneMethods.PlaceTile(self, x, y, 0xEEEEEEEE)
end

function _cplane:ClearTile(x, y)
	return mdl_tiles.PlaneMethods.PlaceTile(self, x, y, -1)
end

function _cplane:CreateTileLayer(x, y, w, h)
	return mdl_tiles.PlaneMethods.CreateTileLayer(self, x, y, w, h)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ Tile Layer methods ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

_tileLayer = {}

function _tileLayer:Anchor()
	mdl_tiles.LayerMethods.Anchor(self)
end

function _tileLayer:Clone()
	return mdl_tiles.LayerMethods.Clone(self)
end

function _tileLayer:SetPos(x, y)
	return mdl_tiles.LayerMethods.SetPos(self, x, y)
end

function _tileLayer:Shift(x, y)
	return mdl_tiles.LayerMethods.Shift(self, x, y)
end

function _tileLayer:Offset(offset_x, offset_y, fill)
	return mdl_tiles.LayerMethods.Offset(self, offset_x, offset_y, fill)
end

function _tileLayer:Resize(w, h, fill)
	return mdl_tiles.LayerMethods.Resize(self, w, h, fill)
end

function _tileLayer:SetPlane(plane)
	return mdl_tiles.LayerMethods.SetPlane(self, plane)
end

function _tileLayer:Merge(second_layer, fill)
	return mdl_tiles.LayerMethods.Merge(self, second_layer, fill)
end

function _tileLayer:Map(fun, args)
	return mdl_tiles.LayerMethods.Map(self, fun, args)
end

function _tileLayer:Fill(tile)
	return mdl_tiles.LayerMethods.Fill(self, tile)
end

function _tileLayer:SetContent(content)
	return mdl_tiles.LayerMethods.SetContent(self, content)
end

function _tileLayer:SetTile(tile, x, y)
	return mdl_tiles.LayerMethods.SetTile(self, tile, x, y)
end

function _tileLayer:GetTile(x, y)
	return mdl_tiles.LayerMethods.GetTile(self, x, y)
end

function _tileLayer:SetRow(content, row)
	return mdl_tiles.LayerMethods.SetRow(self, content, row)
end

function _tileLayer:SetColumn(content, column)
	return mdl_tiles.LayerMethods.SetColumn(self, content, column)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Other ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

function TextOut(text)
	mdl_exe._TextOut(ffi.cast("int&", 0x535910), tostring(text))
end

function MakeScreenshot(filename)
	if filename == nil then
		return mdl_exe._DumpScreen(nRes(14),nRes())
	end
	return mdl_exe._MakeScreenToFile(nRes(12,1,4,11), filename, 1, nRes(11,11,4), 0)
end

function GetLogicAddr(obj)
    return HEX(ffi.cast("int*", obj._v)[4])
end

function _GetLogicName(object)
	local name = ffi.string(object._Name)
	return name ~= "" and name
			or _objects_names[tonumber(ffi.cast("int", object))]
			or "<unnamed>"
end

function JumpToLevel(levelCode)
	mdl_exe._JumpToLevel(nRes(), levelCode)
end

function GetFPS()
    return nRes(6)
end

function GetPlayerName()
    return ffi.string(ffi.cast("const char*",nRes(25)+20))
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[[[ Executive part ]]]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

if not _FileExists(GetClawPath().."\\CLAW.USR") then snRes(0,29) end
mdl_exe.SkipTitleScreen[0] = mdl_exe._GetValueFromRegister(nRes(14), "Skip Title Screen", 0)
mdl_exe.SkipLogoMovies[0] = mdl_exe._GetValueFromRegister(nRes(14), "Skip Logo Movies", 0)
-- Load global custom logics:
_ll("Assets\\GAME\\LOGICS", true)
-- Execute command-line arguments:
mdl_cmd.Execute(cl_argv)

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[[[ Modding API ]]]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
local _LoadModsOnce = false
local _ModdingAPIEnabled = false
_GameModsTab = {}

if not _LoadModsOnce and _DirExists(GetClawPath() .. "\\Mods") then
	local path = GetClawPath() .. "\\Mods"
	for filename in lfs.dir(path) do
		if filename:lower():sub(-4) == ".lua" then
			local modName = filename:sub(1,-5)
			_GameModsTab[modName] = require("Mods."..modName)
			if _GameModsTab[modName] ~= nil then
				_ModdingAPIEnabled = true
			end
		end
	end
	_LoadModsOnce = true
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[[[ Ground ZERO ]]]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Weak magic mode:
--PrivateCast(0x4C, "char*", 0x43FA6A)
-- Super ammo mode:
--PrivateCast(0x50, "char*", 0x43FA32)

--[[
local function TNTFix(b)
    local noper = ffi.cast("char*", 0x41D53D)
    local noperb = ffi.cast("char*", 0x41D538)
    if b == true then
	    noper[3] = 0x8A
	    noper[4] = 0x13
	    noperb[1] = 0xF4
	    noperb[2] = 0x14
    else
	    noper[3] = 0x18
	    noper[4] = 0x00
	    noperb[1] = 0x10
	    noperb[2] = 0x27
    end
end
]]

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------- [[[[ Built-in logics ]]]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
setmetatable(_G, { __index = function(_, key) return _GetBuiltinLogic(key)end } )

function _GetBuiltinLogic(name)
	local asset = ffi.new("void*[1]")
	mdl_exe._LoadAsset(Game(5)+16, name, asset)
	if asset[0] == nil then return end
	return ffi.cast("Logic*", ffi.cast("int",asset[0])+16)[0]
end

--[[ ALL BUILT-IN LOGICS:
    CaptainClaw(ObjectA*)
    CaptainClawHit(ObjectA*)
    CaptainClawRemoteRacer(ObjectA*)
    CaptainClawScreenPosition(ObjectA*)
    ClawMultiRacer(ObjectA*)
    Flare(ObjectA*)
    WolvingtonLFX(ObjectA*)
    Bullet(ObjectA*)
    MagicBullet(ObjectA*)
    FireBullet(ObjectA*)
    LightningBullet(ObjectA*)
    IceBullet(ObjectA*)
    PistolBullet(ObjectA*)
    CannonBall(ObjectA*)
    WolvingtonBullet(ObjectA*)
    OmarBullet(ObjectA*)
    SirenBullet(ObjectA*)
    TridentBullet(ObjectA*)
    RedTailKnife(ObjectA*)
    RedTailBullet(ObjectA*)
    LogicHit(ObjectA*)
    LogicAttack(ObjectA*)
    Officer(ObjectA*)
    Soldier(ObjectA*)
    Raux(ObjectA*)
    Rat(ObjectA*)
    PunkRat(ObjectA*)
    RatBomb(ObjectA*)
    GroundCannon(ObjectA*)
    SkullCanon(ObjectA*)
    TowerCannonRight(ObjectA*)
    TowerCannonLeft(ObjectA*)
    PowderKeg(ObjectA*)
    BouncingGoodie(ObjectA*)
    CutThroat(ObjectA*)
    RobberThief(ObjectA*)
    Katherine(ObjectA*)
    TownGuard1(ObjectA*)
    TownGuard2(ObjectA*)
    BearSailor(ObjectA*)
    RedTailPirate(ObjectA*)
    RedTail(ObjectA*)
    Wolvington(ObjectA*)
    Omar(ObjectA*)
    OmarShield(ObjectA*)
    GooVent(ObjectA*)
    Laser(ObjectA*)
    Crate(ObjectA*)
    FrontStackedCrate(ObjectA*)
    BackStackedCrate(ObjectA*)
    AniRope(ObjectA*)
    Dynamite(ObjectA*)
    BreakPlank(ObjectA*)
    SinglePlank(ObjectA*)
    Seagull(ObjectA*)
    Shake(ObjectA*)
    JumpSwitch(ObjectA*)
    HermitCrab(ObjectA*)
    TProjectile(ObjectA*)
    GroundBlower(ObjectA*)
    CrabNest(ObjectA*)
    ConveyorBelt(ObjectA*)
    BackgroundLogic(ObjectA*)
    CrabBomb(ObjectA*)
    Stalactite(ObjectA*)
    CrazyHook(ObjectA*)
    PegLeg(ObjectA*)
    Fish(ObjectA*)
    CanonSwitch(ObjectA*)
    GabrielCannon(ObjectA*)
    Gabriel(ObjectA*)
    GabrielBomb(ObjectA*)
    CannonButton(ObjectA*)
    Aquatis(ObjectA*)
    AquatisCrack(ObjectA*)
    Tentacle(ObjectA*)
    AquatisDynamite(ObjectA*)
    EndLevelGem(ObjectA*)
    AquatisStalactite(ObjectA*)
    Siren(ObjectA*)
    FallingDebris(ObjectA*)
    LavaGeyser(ObjectA*)
    LavaMouth(ObjectA*)
    LavaHand(ObjectA*)
    LavaHandProjectile(ObjectA*)
    Chameleon(ObjectA*)
    TigerGuard(ObjectA*)
    Mercat(ObjectA*)
    WindDebris(ObjectA*)
    RedTailWind(ObjectA*)
    RedTailSpikes(ObjectA*)
    Parrot(ObjectA*)
    Marrow(ObjectA*)
    MarrowFloor(ObjectA*)
    ScoreFrame(ObjectA*)
    WeaponFrame(ObjectA*)
    HealthFrame(ObjectA*)
    LivesFrame(ObjectA*)
    TimerFrame(ObjectA*)
    StatusNumberDigit(ObjectA*)
    ScoreRibbon(ObjectA*)
    MultiStats(ObjectA*)
    GoldPowerup(ObjectA*)
    HealthPowerup(ObjectA*)
    PowerupGlitter(ObjectA*)
    EndOfLevelPowerup(ObjectA*)
    SpecialPowerup(ObjectA*)
    CratePowerup(ObjectA*)
    FrontCrate(ObjectA*)
    BehindCrate(ObjectA*)
    FrontStatue(ObjectA*)
    BehindStatue(ObjectA*)
    CrateHit(ObjectA*)
    CoinPowerup(ObjectA*)
    TreasurePowerup(ObjectA*)
    MagicPowerup(ObjectA*)
    SuperPowerup(ObjectA*)
    AmmoPowerup(ObjectA*)
    GlitterlessPowerup(ObjectA*)
    PointsIcon(ObjectA*)
    CursePowerup(ObjectA*)
    BossWarp(ObjectA*)
    Checkpoint(ObjectA*)
    CheckpointAttack(ObjectA*)
    CheckpointTimer(ObjectA*)
    FirstSuperCheckpoint(ObjectA*)
    SecondSuperCheckpoint(ObjectA*)
    SuperCheckpointAttack(ObjectA*)
    StandardElevator(ObjectA*)
    SlidingElevator(ObjectA*)
    StartElevator(ObjectA*)
    StopElevator(ObjectA*)
    SpringBoard(ObjectA*)
    WaterRock(ObjectA*)
    Elevator(ObjectA*)
    OneWayStartElevator(ObjectA*)
    OneWayTriggerElevator(ObjectA*)
    TriggerElevator(ObjectA*)
    PathElevator(ObjectA*)
    SteppingStone(ObjectA*)
    SteppingStone2(ObjectA*)
    SteppingStone3(ObjectA*)
    SteppingStone4(ObjectA*)
    StartSteppingStone(ObjectA*)
    OneTimeSteppingStone(ObjectA*)
    CrumblingPeg(ObjectA*)
    CrumblingPegNoRespawn(ObjectA*)
    TogglePeg(ObjectA*)
    TogglePeg2(ObjectA*)
    TogglePeg3(ObjectA*)
    TogglePeg4(ObjectA*)
    AniCycle(ObjectA*)
    AniCycleNormal(ObjectA*)
    ChildChar(ObjectA*)
    ChildScoreNum(ObjectA*)
    ChildRibbon(ObjectA*)
    Message(ObjectA*)
    SingleFrameMessage(ObjectA*)
    DoNothingNormal(ObjectA*)
    DoNothing(ObjectA*)
    BehindCandy(ObjectA*)
    FrontCandy(ObjectA*)
    BehindAniCandy(ObjectA*)
    FrontAniCandy(ObjectA*)
    GlitterMother(ObjectA*)
    GlitterBaby(ObjectA*)
    GooCoverup(ObjectA*)
    GooBubble(ObjectA*)
    HitBurst(ObjectA*)
    Splash(ObjectA*)
    BlinkingEyes(ObjectA*)
    FloorSpike(ObjectA*)
    FloorSpike2(ObjectA*)
    FloorSpike3(ObjectA*)
    FloorSpike4(ObjectA*)
    SawBlade(ObjectA*)
    SawBlade2(ObjectA*)
    SawBlade3(ObjectA*)
    SawBlade4(ObjectA*)
    TreasureCounter(ObjectA*)
    SimpleAnimation(ObjectA*)
    TreasureLogic(ObjectA*)
    MapPieceLogic(ObjectA*)
    AmuletGemLogic(ObjectA*)
    MapProgressLogic(ObjectA*)
    StationaryLight(ObjectA*)
    ChildLight(ObjectA*)
    MenuSparkle(ObjectA*)
    MenuClaw(ObjectA*)
    SoundTrigger(ObjectA*)
    BigSoundTrigger(ObjectA*)
    SmallSoundTrigger(ObjectA*)
    TinySoundTrigger(ObjectA*)
    HugeSoundTrigger(ObjectA*)
    TallSoundTrigger(ObjectA*)
    WideSoundTrigger(ObjectA*)
    ClawDialogSound(ObjectA*)
    EnemyDialogSound(ObjectA*)
    ClawDialogSoundTrigger(ObjectA*)
    ClawDialogBigSoundTrigger(ObjectA*)
    ClawDialogSmallSoundTrigger(ObjectA*)
    ClawDialogTinySoundTrigger(ObjectA*)
    ClawDialogHugeSoundTrigger(ObjectA*)
    ClawDialogTallSoundTrigger(ObjectA*)
    ClawDialogWideSoundTrigger(ObjectA*)
    GlobalAmbientSound(ObjectA*)
    AmbientSound(ObjectA*)
    AmbientPosSound(ObjectA*)
    SpotAmbientSound(ObjectA*)
    BossStager(ObjectA*)
    BossStagerAttack(ObjectA*)
    BossHealthMeter(ObjectA*)
	CustomLogic(ObjectA*)
]]
