---------------------------------------------------------
---------------------------------------------------------
----------------- CRAZY HOOK 1.4 UPDATE -----------------
------------- CREATED BY KUBUS_PL AND ZAX37 -------------
--------------- WITH CONTRIBUTION BY TSXD ---------------
---------------------------------------------------------
---------------------------------------------------------

version = 1450

-- extension modules:
ffi = require 'ffi'
bit = require 'bit'
local lfs = require 'lfs'

-- execute these files:
if not _DoOnceOnStart then
	dofile 'mods\\chCdecl.lua'
	dofile 'mods\\CrazyPatches.lua'
	_DoOnceOnStart = true
end

-- different CrazyHook modules:
local mdl_enums = require 'mods.chEnums'
local mdl_flags = require 'mods.chFlags'
local mdl_exef = require 'mods.chExeFuns'
local mdl_exev = require 'mods.chExeVars'
local mdl_codes = require 'mods.chCodes'
local mdl_drects = require 'mods.chDebugRects'
local mdl_commandline = require 'mods.chCommandLine'
local mdl_customs_window = require 'mods.chCustomLevelWindow'

-- bit module functions:
OR = bit.bor
AND = bit.band
NOT = bit.bnot
XOR = bit.bxor
HEX = bit.tohex

-- various enums:
GameType = mdl_enums.GameType
TreasureType = mdl_enums.TreasureType
Powerup = mdl_enums.Powerup
ObjectType = mdl_enums.ObjectType
DeathType = mdl_enums.DeathType
chamStates = mdl_enums.Chameleon

-- flags and flags metatypes:
InfosFlags = mdl_flags.InfosFlags
Flags = mdl_flags.Flags
DrawFlags = mdl_flags.DrawFlags
mdl_flags.SetFlagsMetatype("Flags")
mdl_flags.SetFlagsMetatype("DrawFlags")

-- game vars:
_nResult = mdl_exev.nResult
nRes = mdl_exev.nRes
snRes = mdl_exev.snRes
Game = mdl_exev.Game
_mResult = mdl_exev.mResult
_hwnd = mdl_exev.Hwnd
LoadBaseLevDefaults = mdl_exef._LoadBaseLevDefaults
LevelBasedData = mdl_exev.LevelBasedData
local SkipLogoMovies = mdl_exev.SkipLogoMovies
local SkipTitleScreen = mdl_exev.SkipTitleScreen
InfosDisplayState = mdl_exev.InfosDisplayState
_chameleon = mdl_exev.Chameleon

-- these two vars must stay for the compatibility with previous versions:
_CurrentPowerup = mdl_exev.CurrentPowerup
_PowerupTime = mdl_exev.PowerupTime

--objects tables:
local _objects = {} -- id -> ObjectA*
local _data = {} -- address -> data table
local _names = {} -- address -> object name (ones from CreateObject)
local Object = {} -- Object methods

--map-related vars:
local fullname = ""
local name = ""
local path = ""

-- Get command line arguments:
local cl_argv = mdl_commandline.Get()

--[[----------------------------------------------------------]]--
--[[----------------------------------------------------------]]--
--[[-----------------INTERNAL CORE FUNCTIONS------------------]]--
--[[----------------------------------------------------------]]--
--[[----------------------------------------------------------]]--

local _env = setmetatable({}, {__index = _G})
local _menv = nil
local _maplogics = {}
local _maphits = {}
local _mapattacks = {}
local _mapinits = {}
local _globallogics = {}
setmetatable(_G, { __index = function(_, k) return GetBuiltinLogic(k) end })

local function _DirExists(filepath)
	return lfs.attributes(filepath, "mode") == "directory"
end

local function _FileExists(filepath)
	return lfs.attributes(filepath, "mode") == "file"
end

local function _GetObjectsAddress(object)
	return tonumber(ffi.cast("int", object))
end

local function GetCustomLogicName(object)
	local name = ffi.string(object._Name)
	return name ~= "" and name
			or _names[_GetObjectsAddress(object)]
			or "<unnamed>"
end

function _create(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	object.MoveClawX, object.MoveClawY = 0, 0

	_objects[object.ID] = object
	if not _data[_GetObjectsAddress(object)] then 
		_data[_GetObjectsAddress(object)] = {} 
	end

	mdl_exef._RegisterHitHandler(object, "CustomHit")
	mdl_exef._RegisterAttackHandler(object, "CustomAttack")
end

function _logic(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	assert(_data[_GetObjectsAddress(object)])
	local name = GetCustomLogicName(object)
	local logic = nil
	if _globallogics[name] then logic = _globallogics[name]
	else logic = _maplogics[name] end
	if type(logic) == "function" then
		logic(object)
	else
		MessageBox("No logic named '" .. name .. "'")
		object:Destroy()
	end
end

function _hit(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	local hit = _env[GetCustomLogicName(object).."Hit"]
	if type(hit) == "function" then
		hit(object)
	end
end

function _attack(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	local attack = _env[GetCustomLogicName(object).."Attack"]
	if type(attack) == "function" then
		attack(object)
	end
end

function _init(object)
	local init = _env[GetCustomLogicName(object).."Init"]
	if type(init) == "function" then
		init(object)
	end
end

function _destroy(ptr)
	do return end
	local object = ffi.cast("ObjectA*", ptr)
	_objects[object.ID] = nil
	_data[_GetObjectsAddress(object)] = nil
	_names[_GetObjectsAddress(object)] = nil
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

local function map_folder(mappath, folder)
	if not _DirExists(mappath .. "\\" .. folder) then return end
	local fn =	(folder == "IMAGES" or folder == "TILES") and MapImagesFolder or
				folder == "SOUNDS" and MapSoundsFolder or
				folder == "ANIS" and MapAnisFolder or
				folder == "LEVEL" or
				error("bad name passed to map_folder")
	if folder=="LEVEL" then
		local lf = LoadFolder(folder)
		MapImagesFolder(lf,"LEVEL") MapSoundsFolder(lf,"LEVEL") MapAnisFolder(lf,"LEVEL")
	elseif folder == "TILES" then fn(LoadFolder(folder), "")
	else fn(LoadFolder(folder), "CUSTOM") end
end

local function ExecuteLogic(object)
	object.Logic(object)
end

local function TNTFix(bool)
    local noper = ffi.cast("char*",0x41D53D)
    local noperb = ffi.cast("char*",0x41D538)
    if (bool == true) then
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

function _TimeThings()
	mdl_exef._TimeThings(_nResult)
end

local function _ll(logicspath, global)
	if _DirExists(logicspath) then
		for filename in lfs.dir(logicspath) do
			if string.lower(filename)~="main.lua" then 
				filename = logicspath .. "\\" .. filename
			else 
				filename="" 
			end
			if _FileExists(filename) then
				local fname = filename:match'.*\\(.*)%.lua'
				if #fname>=1 then
					local chunk, err = loadfile(filename)
					assert(chunk, err)
					local _test = setmetatable({}, {__index = _G})
					if _menv then 
						setfenv(_menv, _test) _menv() 
					end
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
	if _FileExists(logicspath.."\\main.lua") then
		local err = nil
		_menv, err = loadfile(logicspath.."\\main.lua")
		assert(_menv, err)
		setfenv(_menv, _env)
		_menv()
	end
	
end

function _menu()
	MapSoundsFolder(LoadFolder("GAME_SOUNDS"),"GAME")
	MapImagesFolder(LoadFolder("GAME_IMAGES"),"GAME")
	TextOutWithObjects(285,115,9000, 0, "CRAZY HOOK UPDATE","GAME_FONT","TextFadeIn")
	TextOutWithObjects(270,122,9000, 0, "BY ZAX37 & CUBUSPL42","GAME_FONT","TextDelayed")
end

function _map(ptr)

	mdl_codes.CrazyCheats(ptr)
	mdl_customs_window(ptr)
	mdl_commandline.Map(cl_argv)
	
	-- The level is selected and the loading starts:
	if _chameleon[0] == chamStates.LoadingStart then
		ChangeResolution(864,486)
		snRes(864, 31)
		snRes(486, 32)
		local ccnopera = ffi.cast("char*",0x41D4B6)
		local ccnoperb = ffi.cast("char*",0x41D4CB)
		for i=2,4 do 
			ccnopera[i] = 0xFF 
			ccnoperb[i] = 0xFF 
		end
		ccnopera[5] = 0xFD 
		ccnoperb[5] = 0xFE
        TNTFix(false)
		_DoOnlyOnce, _env["OnMapLoad"] = false, nil
		mdl_exev.NoEffects[0] = 0
		local splasher = ffi.cast("char*",0x463B5C)
		splasher[1] = 0x80
		splasher[2] = 0x78
		splasher[3] = 0x52
		fullname = GetMapName()
		if #fullname == 0 then
			mdl_exef._SetBgImage(nRes(11), "LOADING", 1, 1, 1, 0) 
		else
			name = fullname:match'^%a:*\\(.*)%.'
			assert(name, "Could not match the map name in string '" .. fullname .. "'.")
			path = fullname:match'^(.*)%.'
			assert(path, "Could not match the map path in string '" .. fullname .. "'.")
			--
			local cscreen = 0
			if _DirExists(path) then
			--
				IncludeAssets(path)
				if _DirExists(path.."\\SCREENS") then
					local temp = nRes(11,8)
					local str = ffi.cast("char*", 0x52719C)
					local cpy = ffi.cast("char*","%s")
					for i=0,3 do
						str[i] = cpy[i]
					end
					snRes(ffi.cast("int",LoadFolder("SCREENS")),11,8)
					cscreen = mdl_exef._SetBgImage(nRes(11),"LOADING",1,1,1,0)
					cpy = ffi.cast("char*","\\SCREENS\\%s")
					for i=0,12 do
						str[i] = cpy[i]
					end
					snRes(temp,11,8)
				end
			end
			if cscreen==0 then	
				mdl_exef._SetBgImage(nRes(11),"LOADING",1,1,1,0) 
			end
		end
	-- the loading, the game gets the assets:
	elseif _chameleon[0] == chamStates.LoadingAssets then
		MessageBox("x")
		if fullname ~= "" then
			map_folder(path,"TILES")
			map_folder(path,"IMAGES")
			map_folder(path,"SOUNDS")
			map_folder(path,"ANIS")
			map_folder(path,"LEVEL")
			if _DirExists(path.."\\IMAGES\\SPLASH") then
				if LoadAssetB("CUSTOM_SPLASH") ~= nil then
					local splasher = ffi.cast("char*",0x463B5C)
					splasher[1] = 0x60
					splasher[2] = 0xBE
					splasher[3] = 0x50
				end
			end
			_maplogics = {}
			_menv = nil
			_ll(path .. "\\LOGICS")
		end
		
	-- the loading, the game gets the objects:
	elseif _chameleon[0] == chamStates.LoadingObjects then
		if not _DoOnlyOnce then
			_DoOnlyOnce = true
			_objects = {}
			_data = {}
			_names = {}
			local logic = _env["OnMapLoad"]
			if type(logic) == "function" then 
                logic() 
            end
		end
		local object = ffi.cast("ObjectA*",ptr)
		_objects[object.ID] = object
		_data[_GetObjectsAddress(object)] = {}
		_init(object)
		
	-- the level starts:	
	elseif _chameleon[0] == chamStates.LoadingEnd then
		if fullname ~= "" then 
			local musicspath = path .. "\\MUSIC"
			if _DirExists(musicspath) then
				for filename in lfs.dir(musicspath) do
					if _FileExists(musicspath.."\\"..filename) then
						MapMusicFile(LoadFolder("MUSIC"),filename:match('(.*)%.'))
					end
				end
			end
		end
		
	-- during the gameplay when the window gets the message:	
	--elseif _chameleon[0] == chamStates.OnPostMessageA then
		--MessageBox(HEX(tonumber(ffi.cast("int",ptr))))
		
	-- during the gameplay:
	elseif _chameleon[0] == chamStates.Gameplay then
		mdl_drects.DebugRects(ptr)
	end
	
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
	return ffi.cast("Logic*",ffi.cast("int",asset[0])+16)[0]
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

function LoadSingleFile(address,name,constante)
	return mdl_exef._LoadSingleFile(address,name,constante)
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

function IncludeAssets(name)
	local noper = ffi.cast("char*",0x4B720F)
	noper[0]=0xE8 noper[1]=0xDC noper[2]=0xEE noper[3]=0xFF noper[4]=0xFF
	ret = mdl_exef._IncludeAssets(nRes(13),name,0)
	--if ret==1 then AssetsNb = AssetsNb + 1 end
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
	if catglit~=nil then
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

function TextOutWithObjects(x,y,z,flags,string,image,effect)
	local logic = 'CustomLogic'
	if effect==nil then 
		logic = 'DoNothing'
	end
	
	for i = 1, #string do
		local obj = CreateObject{x = x + i*8, y = y, z = z, flags = flags, logic = logic, name = "_" .. effect}
		obj:SetImage(image)
		obj.DrawFlags.flags = DrawFlags.NoDraw
		local frame = string.upper(string):byte(i)
		if frame > 64 and frame < 91 then 
			obj:SetFrame(frame-64)
		elseif frame == 32 then 
			obj.Flags.flags = 0x10000
		elseif frame == 38 then 
			obj:SetFrame(53)
		elseif frame == 46 then 
			obj:SetFrame(38) 
			obj.Y = obj.Y+3
		else 
			obj:SetFrame(frame-21) 
		end
		if i==1 then 
			obj.First = true 
		end
		if i==#string then 
			obj.Last = true 
		end
		
		if effect=='TextDelayed' then 
			obj.State = i*2+18
		elseif effect=='TextFadeIn' then 
			obj.State = i*3 
		end
	end
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
			if i=="name" then name = params.name
			elseif i=="logic" then logic = params.logic
			elseif i=="x" then x = params.x
			elseif i=="y" then y = params.y
			elseif i=="z" then z = params.z
			elseif i=="flags" then flags = params.flags
			elseif i=="ref" then ref = params.ref
			elseif i=="image" then image = params.image
			else vars[i]=params[i] end
		end
	end
	object = mdl_exef._CreateObject(
		ref or Game(2), 0,
		x or 0, y or 0,	z or 0,
		logic, flags or 0x40000
	)
	assert(object)
	if image then
		object:SetImage(image)
	end
	if name then
		if logic ~= "CustomLogic" then
			error("You can call CreateObject with 'name' only for CustomLogic, not for " .. logic .. "!")
		end
		_names[_GetObjectsAddress(object)] = name
	end
	for i,k in pairs(vars) do object[i] = k end
	object:Logic()
	return object
end

function KeyPressed(key)
	return mdl_exef._KeyPressed(key)~=0
end

function SetDeathType(type)
	for i=0,2 do LevelBasedData[i].DeathTileType = type end
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
	else 
        return "LOL NOPE" 
    end
end

function RegisterTreasure(n, nb)
	if nb==nil then 
        nb = 1 
    end
	if n>=0 and n<=8 then 
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

function GetTime()
	return mdl_exev.MsCount[0]
end

GetTicks = GetTime

function TextOut(text)
	mdl_exef._TextOut(ffi.cast("int&", 0x00535910), tostring(text))
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
	mdl_exef._SetMusic(nRes(20), name, 1)
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
	return ffi.cast("int**", 0x535918)[0][2]
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

function PlaySound(name, ignore_err)
	local sound = nil
	if name and type(name)~="string" then sound = name else sound = LoadAsset(name) end
	if not ignore_err then assert(sound~=nil, "Sound does not exist!") end
	if sound~=nil then mdl_exef._PlaySound(sound, ffi.cast("int*", 0x530990)[0], 0, 0, 0) return ffi.cast("int**",sound)[4][10]+100 end
end

function ClawSound(name)
	mdl_exef._ClawSound(name,0)
end

function GetObject(id)
	return _objects[id]
end

function CreateGoodie(table)
	if not table.x then table.x = GetClaw().X end
	if not table.y then table.y = GetClaw().Y end
	if not table.z then table.z = 1000 end
	if not table.powerup then table.powerup = 33 end
	mdl_exef._CreateGoodie(Game(),table.x,table.y,table.z,table.powerup)
end

function CustomPowerup(func_name, time)
	if not func_name then return end
	if not time then time=0 end
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

----------------------------------------------------------
----------------------------------------------------------
-----------------------OBJECT METHODS---------------------
----------------------------------------------------------
----------------------------------------------------------

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
	mdl_exef._AnimationStep(ffi.cast("char*", self) + 0x1A0, ffi.cast("int*", 0x005AAFD8)[0])
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
	return _data[_GetObjectsAddress(self)]
end

----------------------------------------------------------
----------------------------------------------------------
----------------------OBJECT METATYPE---------------------
----------------------------------------------------------
----------------------------------------------------------

ffi.metatype("ObjectA", {
	__index = function(self, key)
		local ok, result = pcall(function()
			return self._v[key]
		end)
		if ok then
			return result
		end
		local data = _data[_GetObjectsAddress(self)]
		if data then
			local result = data[key]
			if result ~= nil then
				return result
			end
		end
		if Object[key] then
			return Object[key]
		end
	end,
	__newindex = function(self, key, val)
		local ok = pcall(function()
			return self._v[key]
		end)
		if ok then
			self._v[key] = val
			return
		end
		local data = _data[_GetObjectsAddress(self)]
		if data then
			data[key] = val
			return
		end
		error("ObjectA __newindex " .. GetCustomLogicName(self) .. " " .. key .. " " .. tostring(val))
	end
})

----------------------------------------------------------
----------------------------------------------------------
-----------------------EXECUTIVE PART---------------------
----------------------------------------------------------
----------------------------------------------------------

SkipTitleScreen[0] = GetValueFromRegister("Skip Title Screen")
SkipLogoMovies[0] = GetValueFromRegister("Skip Logo Movies")
_ll("Assets\\GAME\\LOGICS", true)
mdl_commandline.Execute(cl_argv)
