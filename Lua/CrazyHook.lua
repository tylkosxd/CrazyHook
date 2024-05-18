---------------------------------------------------------
---------------------------------------------------------
----------------- CRAZY HOOK 1.4 UPDATE -----------------
------------- CREATED BY KUBUS_PL AND ZAX37 -------------
---------------------------------------------------------
----------------- WITH TSXD'S TREATMENT -----------------
---------------------------------------------------------
---------------------------------------------------------

version = 1450

-- extension modules:
ffi             = require 'ffi'
bit             = require 'bit'
local lfs       = require 'lfs'

-- declare C types and metatypes:
dofile 'mods\\chCdecl.lua'
dofile 'mods\\chMetaTypes.lua'

-- load CrazyHook modules:
local mdls_path         = 'mods.'
local mdl_enums         = require (mdls_path .. 'chEnums')
local mdl_flags         = require (mdls_path .. 'chFlags')
local mdl_codes         = require (mdls_path .. 'chCodes')
local mdl_dbg_tools     = require (mdls_path .. 'chDbgTools')
local mdl_cmd           = require (mdls_path .. 'chCommandLine')
local mdl_cust_wnd      = require (mdls_path .. 'chCustomLevelWindow')
local mdl_pals          = require (mdls_path .. 'chPalettes')
local mdl_lclock        = require (mdls_path .. 'chLiveClock')
local mdl_cust_map      = require (mdls_path .. 'chCustomMap')
mdl_exef                = require (mdls_path .. 'chExeFuns')
mdl_exev                = require (mdls_path .. 'chExeVars')

-- bit module functions:
OR                  = bit.bor
AND                 = bit.band
NOT                 = bit.bnot
XOR                 = bit.bxor
HEX                 = bit.tohex

-- various enums:
GameType            = mdl_enums.GameType
TreasureType        = mdl_enums.TreasureType
Powerup             = mdl_enums.Powerup
ObjectType          = mdl_enums.ObjectType
DeathType           = mdl_enums.DeathType
TileType            = mdl_enums.TileType
TileAttribute       = mdl_enums.TileAttribute
PlayerInput         = mdl_enums.PlayerInput
ImageFlags          = mdl_enums.ImageFlags
chamStates          = mdl_enums.Chameleon
_message            = mdl_enums.Message

-- game vars:
_nResult            = mdl_exev.nResult
nRes                = mdl_exev.nRes
snRes               = mdl_exev.snRes
Game                = mdl_exev.Game
_mResult            = mdl_exev.mResult
_hwnd               = mdl_exev.Hwnd
LevelBasedData      = mdl_exev.LevelBasedData
InfosDisplay        = mdl_exev.InfosDisplay
_chameleon          = mdl_exev.Chameleon

-- these vars should stay for the compatibility with previous version(-s):
_CurrentPowerup     = mdl_exev.CurrentPowerup
_PowerupTime        = mdl_exev.PowerupTime
_TeleportX          = mdl_exev.TeleportX
_TeleportY          = mdl_exev.TeleportY

-- flags:
InfosFlags          = mdl_flags.InfosFlags
Flags               = mdl_flags.Flags
DrawFlags           = mdl_flags.DrawFlags
PlaneFlags          = mdl_flags.PlaneFlags
SpecialFlags        = mdl_flags.SpecialFlags

-- the flags metatypes:
mdl_flags.SetFlagsMetatype("Flags")
mdl_flags.SetFlagsMetatype("DrawFlags")
mdl_flags.SetFlagsMetatype("PlaneFlags")
mdl_flags.SetFlagsMetatype("SpecialFlags")
mdl_flags.SetFlagsMetatype("InfosFlags")

-- object methods:
Object              = {}

-- get command line args:
local cl_argv       = mdl_cmd.Get()

-- debug text table:
debug_text          = {"Put whatever you want here by writing in your custom logic: ",
                        "debug_text[0] = 'whatever'; debug_text[1] = 'whatever more'; etc" }

--------------------------------------------------------------
--------------------------------------------------------------
-------------------INTERNAL CORE FUNCTIONS--------------------
--------------------------------------------------------------
--------------------------------------------------------------

local _env          = setmetatable({}, {__index = _G})
local _menv         = nil -- "main" environment
local _maplogics    = {}
--local _maphits      = {}
--local _mapattacks   = {}
--local _mapinits     = {}
local _globallogics = {}
setmetatable(_G, { __index = function(_, key) return GetBuiltinLogic(key) end })

function _DirExists(filepath)
	return lfs.attributes(filepath, "mode") == "directory"
end

function _FileExists(filepath)
	return lfs.attributes(filepath, "mode") == "file" and lfs.attributes(filepath, "mode") ~= "directory"
end

function _TableContainsKey(tab, name)
    for k,_ in pairs(tab) do
        if k == name then
            return true
        end
    end
    return false
end

function _GetObjectsAddress(object)
	return tonumber(ffi.cast("int", object))
end

function _GetLogicName(object)
	local name = ffi.string(object._Name)
	return name ~= "" and name
			or _objects_names[_GetObjectsAddress(object)]
			or "<unnamed>"
end

function _create(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	object.MoveClawX, object.MoveClawY = 0, 0

	_objects[object.ID] = object
	if not _objects_data[_GetObjectsAddress(object)] then 
		_objects_data[_GetObjectsAddress(object)] = {} 
	end

	mdl_exef._RegisterHitHandler(object, "CustomHit")
	mdl_exef._RegisterAttackHandler(object, "CustomAttack")
end

function _logic(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	assert(_objects_data[_GetObjectsAddress(object)])
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

function _hit(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	local hit = _env[_GetLogicName(object).."Hit"]
	if type(hit) == "function" then
		hit(object)
	end
end

function _attack(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	local attack = _env[_GetLogicName(object).."Attack"]
	if type(attack) == "function" then
		attack(object)
	end
end

function _init(object)
	local init = _env[_GetLogicName(object).."Init"]
	if type(init) == "function" then
		init(object)
	end
end

function _destroy(ptr)
	do return end
	local object = ffi.cast("ObjectA*", ptr)
	_objects[object.ID] = nil
	_objects_data[_GetObjectsAddress(object)] = nil
	_objects_names[_GetObjectsAddress(object)] = nil
end

function _exception(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	MessageBox("_exception")
	MessageBox(debug.traceback())
end

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

function _TimeThings()
	mdl_exef._TimeThings(_nResult)
end

local function _lls(logicspath)
    if _DirExists(logicspath) then
        _ll(logicspath)
        for filename in lfs.dir(logicspath) do
            if filename ~= "." and filename ~= ".." and _DirExists(logicspath.."\\"..filename) then
                _lls(logicspath.."\\"..filename)
            end
        end
    end
end

local function _lmain(logicspath)
    if _FileExists(logicspath.."\\main.lua", "mode") then
		local err = nil
		_menv, err = loadfile(logicspath.."\\main.lua")
		assert(_menv, err)
		setfenv(_menv, _env)
		_menv()
	end
end

function _ll(logicspath, global)
	if _DirExists(logicspath) then
		for filename in lfs.dir(logicspath) do
			if string.lower(filename) ~= "main.lua" and #filename > 4 then 
                filename = logicspath .. "\\" .. filename
		    else 
                filename = "" 
            end
			if lfs.attributes(filename, "mode") == "file" then
				local fname = filename:match'.*\\(.*)%.lua'
				if #fname > 0 then
					local chunk, err = loadfile(filename)
					assert(chunk, err)
					local _test = setmetatable({}, {__index = _G})
					if _menv then setfenv(_menv, _test) _menv() end
					setfenv(chunk, _test)
					chunk()
					if _test["main"] then
						if global then 
							_globallogics[fname] = _test["main"]
						else
                            _maplogics[fname] = _test["main"]
						end
						_env[fname.."Hit"] = _test["hit"]
						_env[fname.."Attack"] = _test["attack"]
						_env[fname.."Init"] = _test["init"]
					end
				end
			end
		end
	end
end

function _menu()
	--MapSoundsFolder(LoadFolder("GAME_SOUNDS"),"GAME")
	--MapImagesFolder(LoadFolder("GAME_IMAGES"),"GAME")
end

function _map(ptr)

	mdl_codes.CrazyCheats(ptr)
	mdl_cust_wnd(ptr)
	mdl_cmd.Map(cl_argv)
    mdl_lclock.clock(ptr)
    mdl_cust_map.LoadCustomAssets(ptr)

	if _chameleon[0] == chamStates.LoadingStart then
        mdl_exev.NoEffects[0] = 0
		_DoOnlyOnce = false
        _env["OnMapLoad"] = nil
        _maplogics = { }
	    _menv = nil
        _objects            = {} -- id -> ObjectA*
        _objects_data       = {} -- address -> data table
        _objects_names      = {} -- address -> object name (ones from CreateObject)
        
	elseif _chameleon[0] == chamStates.LoadingAssets then
        local map_fullname = GetMapName()
		if #map_fullname > 0 then
            local map_path = map_fullname:match'^(.*)%.'
            _lls(map_path .. "\\LOGICS")
            _lmain(map_path .. "\\LOGICS")
		end
		
	elseif _chameleon[0] == chamStates.LoadingObjects then
		if not _DoOnlyOnce then
			_DoOnlyOnce = true
			local logic = _env["OnMapLoad"]
			if type(logic) == "function" then 
                logic() 
            end
            
		end
		local object = ffi.cast("ObjectA*",ptr)
		_objects[object.ID] = object
		_objects_data[_GetObjectsAddress(object)] = {}
		_init(object)

	elseif _chameleon[0] == chamStates.Gameplay then
        --LoopThroughObjects(debug_try)
		mdl_dbg_tools.DebugRects(ptr)
		mdl_dbg_tools.DebugText(ptr)
	end

end

function LoadPalette(filename)
	mdl_pals.LoadPalette(filename, nRes(11)+0x360)
end

function LoadFolder(name)
	return mdl_exef._LoadFolder(nRes(13), name)
end

function LoadAsset(name)
	local asset = ffi.new("void*[1]")
	mdl_exef._LoadAsset(Game(10)+16, name, asset)
	return asset[0]
end

function LoadAssetB(name)
	local asset = ffi.new("void*[1]")
	mdl_exef._LoadAsset(Game(4)+16, name, asset)
	return asset[0]
end

function GetBuiltinLogic(name)
	local asset = ffi.new("void*[1]")
	mdl_exef._LoadAsset(Game(5)+16, name, asset)
	if asset[0] == nil then return end
	return ffi.cast("Logic*", ffi.cast("int",asset[0])+16)[0]
end

function MapSoundsFolder(address,short)
	mdl_exef._MapSoundsFolder(nRes(11,3,10), address, short, "_")
end

function MapImagesFolder(address,short)
	mdl_exef._MapImagesFolder(nRes(11,3,4), address, short, "_")
end

function MapAnisFolder(address,short)
	mdl_exef._MapAnisFolder(nRes(11,3,11), address, short, "_")
end

function LoadSingleFile(address,name,constant)
	return mdl_exef._LoadSingleFile(address,name,constant)
end

function MapMusicFile(address,name)
	local mus = LoadSingleFile(address ,name, 0x584D49)
	if mus then
		local _GetAddr = ffi.cast("void *(*__thiscall)(void*)", 0x4B5B30)
		local _var = ffi.cast("int*",mus)[3]
		mus = _GetAddr(mus)
		if mus then
			mdl_exef._MapMusicFile(nRes(20), mus, _var, name)
		end
	end
end

function IncludeAssets(path)
    local inst = ffi.cast("char*",0x4B720F)
    local oper = ffi.cast("unsigned int*", 0x4B7210)
    inst[0] = 0xE8 -- CALL
    oper[0] = 0xFFFFEEDC -- 004B60F0
	ret = mdl_exef._IncludeAssets(nRes(13), path, 0)
	return ret
end

function LoopThroughObjects(funct, arg)
	local one = nRes(11,3)
	if one then
		one = ffi.cast("int*",one)[2]+16
		if one then
			local two = ffi.cast("int*",one)[1]
			while two~=0 do
				local object = ffi.cast("ObjectA**",two)[2]
				two = ffi.cast("int*",two)[0]
				if funct then funct(object, arg) else object:Logic() end
			end
		end
	end
end

local function _ReduceClawGlitters()
	local catglit = ffi.cast("ObjectA*",PlayerData()._CGlit)
	if catglit ~= nil then
		catglit:Destroy()
		PlayerData()._CGlit = 0
	end
end

function MessageBox(text, title)
	ffi.C.MessageBoxA(nil, tostring(text), title or "", 0)
end

function GetValueFromRegister(ch)
	return mdl_exef._GetValueFromRegister(nRes(14),ch,0)
end

function MakeScreenshot(filename)
	if filename==nil then
		return mdl_exef._DumpScreen(nRes(14),nRes())
	end
	return mdl_exef._MakeScreenToFile(nRes(12,1,4,11), filename, 1, nRes(11,11,4), 0)
end

----------------------------------------------------------
----------------------------------------------------------
-----------------MAIN API FUNCTION EXPORTS----------------
----------------------------------------------------------
----------------------------------------------------------

function CreateObject(params)
	local name,logic,object,image,x,y,z,flags,ref = nil
	local vars = {}
	if params then
		for i,k in pairs(params) do
			if i == "name" then name = params.name
			elseif i == "logic" then logic = params.logic
			elseif i == "x" then x = params.x
			elseif i == "y" then y = params.y
			elseif i == "z" then z = params.z
			elseif i == "flags" then flags = params.flags
			elseif i == "ref" then ref = params.ref
			elseif i == "image" then image = params.image
            elseif i == "animation" then animation = params.animation
			else vars[i] = params[i] 
            end
		end
	end
    if not logic then logic = "CustomLogic" end
	object = mdl_exef._CreateObject(
		ref or Game(2),
        0,
		x or GetClaw().X,
        y or GetClaw().Y,	
        z or 0,
		logic,
        flags or 0x40000
	)
	assert(object)
	if image then
		object:SetImage(image)
	end
    if animation then
        object:SetAnimation(animation)
    end
	if name then
		if logic ~= "CustomLogic" then
			error("You can call CreateObject with 'name' only for CustomLogic, not for " .. logic .. "!")
		end
		_objects_names[_GetObjectsAddress(object)] = name
	end
	for i,k in pairs(vars) do 
        object[i] = k 
    end
	object:Logic()
	return object
end

function KeyPressed(key)
	return mdl_exef._KeyPressed(key) ~= 0
end

function SetDeathType(type)
	for i=0,1 do 
		LevelBasedData[i].DeathTileType = type 
	end
end

function ChangeResolution(width,height)
	mdl_exef._ChangeResolution(nRes(),width,height)
end

function Teleport(x,y)
	mdl_exev.TeleportX[0] = x
	mdl_exev.TeleportY[0] = y
	ffi.C.PostMessageA(nRes(1,1), 0x111, 0x805C, 0);
end

function CameraToPoint(x,y)
	mdl_exev.CameraX[0] = x
	mdl_exev.CameraY[0] = y
end

function CameraToClaw()
	mdl_exev.CameraX[0] = -1
	mdl_exev.CameraY[0] = -1
end

function CameraToObject(object)
	mdl_exev.CameraX[0] = object.X
	mdl_exev.CameraY[0] = object.Y
end

function GetTreasuresNb(n)
	if n >= 0 and n <= 8 then 
        return mdl_exev.TreasuresCountTable[n]
    end
end

function RegisterTreasure(n, nb)
	if nb == nil then 
        nb = 1 
    end
	if n >= 0 and n <= 8 then 
        mdl_exev.TreasuresCountTable[n] = mdl_exev.TreasuresCountTable[n]+nb
    end
end

function GetImgStr(ch)
	local str = ffi.cast("const char*",ffi.cast("int",ch)+36)
	if ffi.cast("int",str)>36 then
        return ffi.string(str) 
    end
end

function GetClaw()
	return mdl_exev.Claw[0]
end

function BlockClaw()
	ffi.cast("void (*)()", 0x421450)()
end

function Attempt()
	return tonumber(PlayerData().AttemptNb)
end
Attemp = Attempt

function PlayerData()
	return GetClaw()._v._p
end
PData = PlayerData

function GetTime()
	return mdl_exev.MsCount[0]
end
GetTicks = GetTime

function TextOut(text)
	mdl_exef._TextOut(ffi.cast("int&", 0x535910), tostring(text))
end

function KillClaw()
	mdl_exef._ClawGivePowerup(0,0)
	mdl_exef._KillClaw(GetClaw(), GetClaw()._v, ffi.cast("char*", GetClaw()._v) + 0x14, 0)
end

function ClawTakeDamage(damage)
	GetClaw().Health = GetClaw().Health - damage
	if GetClaw().Health <= 0 then
		KillClaw()
	end
end

function ClawGivePowerup(powerupId, time)
	mdl_exef._ClawGivePowerup(powerupId, time * 1000)
end

function ClawJump(height)
	mdl_exef._ClawJump(GetClaw(), height)
end

function GetGameType()
	return ffi.cast("int*", nRes(11,0,4)+1)[0]
end

function SetMusic(name)
	mdl_exef._SetMusic(nRes(20), string.upper(name), 1)
end

function SetMusicSpeed(value, time)
	local t = ffi.cast("int", time*1000)
	if t > 50000 then
		t = 50000
	end
	mdl_exef._SetMusicSpeed(nRes(20,7), value, t)
end

function BnW()
	mdl_exef._BnW(nRes(11,11))
end

function GetInput()
	return mdl_exev.Inputs[0][2]
end

function GetMapName()
	return ffi.string(ffi.cast("const char*",nRes(49)))
end

function OpenWindow()
	return ffi.string(mdl_exef._OpenWindow(nRes(), nRes(1,1), 0)[0])
end

function JumpToLevel(levelCode)
	mdl_exef._JumpToLevel(nRes(), levelCode)
end

function SetBoss(object)
	mdl_exev.CurrentBoss[0] = object
end

function GetBoss()
	return mdl_exev.CurrentBoss[0]
end

function ClawSound(name)
	mdl_exef._ClawSound(name,0)
end

function GetObject(id)
	return _objects[id]
end

LoadBaseLevDefaults = mdl_exef._LoadBaseLevDefaults

function CreateGoodie(table)
	if not table.x then table.x = GetClaw().X end
	if not table.y then table.y = GetClaw().Y end
	if not table.z then table.z = 1000 end
	if not table.powerup then table.powerup = 33 end
	mdl_exef._CreateGoodie(Game(),table.x,table.y,table.z,table.powerup)
end

function CustomPowerup(func_name, time)
	if not func_name then return end
	if not time then time = 0 end
    _ReduceClawGlitters()
	if CustomPowerupPointer and CustomPowerupPointer.CPN ~= func_name then
		CustomPowerupPointer:Destroy()
		CustomPowerupPointer = nil
		mdl_exef._ClawGivePowerup(0,0)
	end
	mdl_exef._ClawGivePowerup(666, time)
	if not CustomPowerupPointer then 
		CustomPowerupPointer = CreateObject {x=GetClaw().X,y=GetClaw().Y,z=GetClaw().Z,logic="CustomLogic",name="_ClawCPowerup"} 
	end
	CustomPowerupPointer.CPN = func_name
end

--------------------------------------------------------------
--------------------------------------------------------------
---------------------NEW FUNCTIONS IN 1.4.5-------------------
--------------------------------------------------------------
--------------------------------------------------------------

function GetLogicAddr(obj)
    return HEX(ffi.cast("int*", obj._v)[4])
end

function GetMusicState(name)
    local ptr = mdl_exef._GetMusic(nRes(20), string.upper(name))
    return mdl_exef._GetMusicState(ptr)
end

function StopMusic(name)
	if GetMusicState(name) then
        ffi.cast("int(*__thiscall)(int)", ffi.cast("int**", ptr)[0][8])(ptr)
    end
end

function GetMainPlane()
    return ffi.cast("Plane*", Game(9, 14, Game(9,23,1)))
end

function GetFrontPlane()
    return ffi.cast("Plane*", Game(9, 14, Game(9,15) - 1))
end

function GetPlane(pI)
	return ffi.cast("Plane*", Game(9,14,pI))
end

local function _planesNumber()
	return Game(9,15)
end

function GetTile(pI, x, y)
    if pI >= 0 and pI < _planesNumber() then
		local _plane = GetPlane(pI)
        if x >= 0 and x < _plane.Width and y >= 0 and y < _plane.Height then
            local _tileIndex = x + y * _plane.Width
            return _plane.Tiles[_tileIndex]
        else
            return -3
        end
    else
        error("Error: no plane with index " .. pI .."!")
    end
end

function PlaceTile(id, pI, x, y)
    if pI >= 0 and pI < _planesNumber() then
		local _plane = GetPlane(pI)
        if x >= 0 and x < _plane.Width and y >= 0 and y < _plane.Height then
            local _TileIndex = x + y * _plane.Width
            _plane.Tiles[_tileIndex] = id
        else
            error("Coordinates out of plane boundaries!")
        end
    else
        error("No plane with index " .. pI .."!")
    end
end

function GetTileA(id)
	local _tType = Game(9,19,id,0)
	if _tType == TileType.Single then
        return ffi.cast("SingleTileA*", Game(9,19,id))
    elseif _tType == TileType.Double then
        return ffi.cast("DoubleTileA*", Game(9,19,id))
    elseif _tType == TileType.Mask then
        return ffi.cast("MaskTileA*", Game(9,19,id))
    end
end

function GetDetailsState()
    return nRes(105)
end

function GetCurrentPowerup()
	return _CurrentPowerup[0]
end 

function GetCurrentPowerupTime()
    return _PowerupTime[0]
end

function GetRespawnPoint()
	return {x = nRes(11,17), y = nRes(11,18)}
end

function SetRespawnPoint(x,y)
    if x < Game(9,23,12) and x >= 0 and y < Game(9,23,13) and y >= 0 then
	    snRes(x,11,17)
		snRes(y,11,18)
    else
        error("Coordinates out of main plane boundaries!")
    end
end

function GetClawAttackString()
    return mdl_enums.AttackString[1+PlayerData().AttackType]
end

function CheatsUsed()
	return nRes(18,74)
end

function StunClaw(mseconds)
    snRes(mseconds,11,473)
end

function GetCameraPosition()
    return {x = Game(9,23,33), y = Game(9,23,34)}
end

function GetFPSCounter()
    return nRes(6)
end

function GetPlayerName()
    return ffi.string(ffi.cast("const char*",nRes(25)+20))
end

function Earthquake(t)
	mdl_exef._Quake(math.floor(t))
end

function CreateHUDObject(Rx, Ry, Rz, image)
    local window = mdl_exev.PlayAreaRect[0]
    if string.upper(tostring(Rx)) == "RANDOM" then 
        Rx = math.random(window.Right) 
    elseif string.upper(tostring(Rx)) == "CENTER" then
        Rx = math.floor(0.5 + window.Right/2)
    elseif tonumber(Rx) then
        if Rx < 0 then 
            Rx = rect.Right + Rx
        else
            Rx = tonumber(Rx) 
        end 
    else
        error("Invalid X position")
    end
    if string.upper(tostring(Ry)) == "RANDOM" then 
        Ry = math.random(window.Bottom) 
    elseif string.upper(tostring(Ry)) == "CENTER" then
        Ry = math.floor(0.5 + window.Bottom/2)
    elseif tonumber(Ry) then
        if Ry < 0 then 
            Ry = window.Bottom + Ry
        else
            Ry = tonumber(Ry) 
        end 
    else
        error("Invalid Y position")
    end
    if not tonumber(Rz) then
        Rz = 0
    else
        Rz = tonumber(Rz)
    end
    local flags = ffi.new("Flags_t", 2)
    return CreateObject{x=Rx,y=Ry,z=Rz,logic="BackgroundLogic",image=image, Flags=flags}
end

function ReplaceSound(name1, name2)
    local _sound_ptr1 = mdl_exef._GetSound(Game(10)+16, name1)
	local _sound_ptr2 = mdl_exef._GetSound(Game(10)+16, name2)
	_sound_ptr1[0] = _sound_ptr2[0]
end

function PlaySound(name, volume, stereo, pitch, loop)
	if not tostring(name) then
		error("Invalid sound name")
	else
		local sound = mdl_exef._GetSoundA(Game(10), name)
		if not volume then
			volume = mdl_exev.SoundVolume[0]
		elseif volume >= 3 then
			volume = volume*mdl_exev.SoundVolume[0]
		elseif volume <= 0 then
			volume = 0
		else
			volume = volume*mdl_exev.SoundVolume[0]
		end
		if not stereo then
			stereo = 0
		end
		if not pitch then
			pitch = 0
		end
		if not loop then
			loop = 0
		end
		mdl_exef._PlaySound(sound, volume, stereo, pitch, loop)
	end
end

function StopSound(name)
	local sound = mdl_exef._GetSoundA(Game(10), name)
    if sound[4] then
		mdl_exef._StopSound(sound)
	end
end

function GetFoeAction(object)
    actions = ffi.cast("int**", 0x5ACD40)[0]
    return ffi.string( ffi.cast("const char*", actions[object.State - 2000]) )
end

function SetImgFlag(object, flag) 
    if flag > 0 and flag <= 7 and flag ~= 4 then
        mdl_exef._SetImgFlag(object.Image, flag)
    else
        error("Invalid image flag")
    end
end

function SetImgColor(object, color) 
    mdl_exef._SetImgColor(object.Image, tonumber(color))
end

function SetImgCLT(object, clt)
    if string.upper(clt) == "LIGHT" then
        mdl_exef._SetImgCLT(object.Image, nRes(11,474))
    elseif string.upper(clt) == "AVERAGE" then
        mdl_exef._SetImgCLT(object.Image, ffi.cast("int*", 0x5AAFBC)[0])
    else
        error("Invalid color table, use 'Average' or 'Light'")
    end
end

function SetPalette(filename)
	mdl_pals.LoadPalette(filename, nRes(11,11,14))
    snRes(0xFFFF,11,11,4,3,55)
    BnW()
end

function LoadAverageCLT(filename)
    mdl_pals.LoadCLT(filename, ffi.cast("int**", 0x5AAFBC)[0][2])
end

function LoadLightCLT(filename)
    mdl_pals.LoadCLT(filename, nRes(11,474,2))
end

--------------------------------------------------------------
--------------------------------------------------------------
-----------------------OBJECT METHODS-------------------------
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------


function Object:Destroy()
	self.Flags.flags = 0x10000
end

function Object:Physics(x, y)
	return mdl_exef._Physics(Game(9), self, x, y, 8)
end

function Object:IsVisible(x)
	return mdl_exef._IsVisible(Game(9), self.X, self.Y, x, 32)
end

function Object:AlignToGround()
	mdl_exef._AlignToGround(Game(9), self, 0)
end

function Object:GetSelf()
	return tonumber(ffi.cast("int",self))
end

function Object:SetImage(name)
	mdl_exef._SetImage(self, name)
end

function Object:SetAnimation(name)
	mdl_exef._SetAnimation(self, name, 0)
end

function Object:SetFrame(nb)
	mdl_exef._SetImageAndI(self, GetImgStr(self.Image), nb)
end

function Object:AnimationStep()
	mdl_exef._AnimationStep(ffi.cast("char*", self) + 0x1A0, ffi.cast("int*", 0x5AAFD8)[0])
end

function Object:IsBelow(object)
	return object.Flags.OnElevator and object.ObjectBelow == self
end

function Object:_ResetName() -- DANGER
	self._Name = ffi.cast("const char*",0x52c67c)
end

function Object:DropCoin()
	CreateGoodie {x=self.X, y=self.Y, z=self.Z}
end

function Object:GetData()
	return _objects_data[_GetObjectsAddress(self)]
end

function Object:CreateGlitter(img)
    if tonumber(ffi.cast("int", Object.GlitterPointer)) == 0 then
        if not img then img = "GAME_GLITTER"
        elseif string.lower(img) == "green" then img = "GAME_GREENGLITTER"
        elseif string.lower(img) == "red" then img = "GAME_GLITTERRED"
        elseif string.lower(img) == "warp" then img = "GAME_WARPGLITTER"
        elseif string.lower(img) == "gold" then img = "GAME_GLITTER"
        end
        Object.GlitterPointer = CreateObject{x=Object.X, y=Object.Y, z=Object.Z, logic="PowerupGlitter", image=img, animation="GAME_CYCLE50"}
    end
end

--------------------------------------------------------------
--------------------------------------------------------------
------------------------EXECUTIVE PART------------------------
--------------------------------------------------------------
--------------------------------------------------------------

dofile 'mods\\CrazyPatches.lua'
mdl_exev.SkipTitleScreen[0] = GetValueFromRegister("Skip Title Screen")
mdl_exev.SkipLogoMovies[0] = GetValueFromRegister("Skip Logo Movies")
_ll("Assets\\GAME\\LOGICS", true)
mdl_cmd.Execute(cl_argv)

--[[ testing ground:
ffi.cast("int*", 0x4940BF)[0] = 250000 -- value for the next extra live, default: 500000
ffi.cast("char*", 0x494136)[0] = 4 -- left shift of 15625, default: 5
-- Tiger magic block (may crash on other enemies):
ffi.cast("char*", 0x43FA6A)[0] = 0x4C
function debug_try(obj)
    --if obj.Logic == Tentacle then -- 0x495870
    --if obj.Logic == BossStager then -- 0x4913D0
    --if obj.Logic == AmmoPowerup then -- 472CB0
    --if obj.Logic == CursePowerup then -- 472600
    --if GetImgStr(obj.Image) == "LEVEL_RATBOMB" then
    --if obj.Logic == Bullet then
    --if obj.Logic == BossWarp then -- 472450
    --if GetImgStr(obj.Image) == "GAME_MAPPIECE" then -- 471D90
    if obj.Logic == CursePowerup then
        TextOut(ffi.cast("int*", obj._v)[90].." "..ffi.cast("int*", obj._v)[91])
        --obj.PhysicsType = 1
        -- 410510 arrow -- 415940 cannonball -- 411090 sirenproj -- 411200 trident
        -- 410680 claw pistol -- 4107F0 magic claw -- 480090 rat bomb
        --TextOut(GetLogicAddr(obj).." "..obj.AttackRect.Left.." "..obj.AttackRect.Top.." "..obj.AttackRect.Right.." "..obj.AttackRect.Bottom)
        --BossStager States: {5, 8006, 8008, 8005, 8007, 8000, 8001, 8002, 8004}
        --ffi.cast("int*", obj._userdata)[195] = 1
    end
end]]
