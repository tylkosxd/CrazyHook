--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------[[ CRAZY HOOK 1.4.5 UPDATE ]]-----------------------------------------------------
--------------------------------------------------- CREATED BY KUBUS_PL AND ZAX37 ----------------------------------------------------
---------------------------------------------------------- EXTENDED BY TSXD ----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
version = 1453

ffi	= require 'ffi'
bit	= require 'bit'
lfs	= require 'lfs'

dofile'CrazyHookConsts.lua'

dofile'Assets\\GAME\\MODULES\\c_defs.lua'
dofile'Assets\\GAME\\MODULES\\asm_crazy_patches.lua'
dofile'Assets\\GAME\\MODULES\\custom_flags.lua'

package.path = package.path .. ".\\Assets\\GAME\\MODULES\\?.lua;"

local mdl_gen		= require'lua_utils'
local mdl_privc		= require'custom_priv_casting'
local mdl_logics	= require'custom_logics'
local mdl_images	= require'custom_images'
local mdl_objects	= require'custom_objects.objects_main'
local mdl_inputs	= require'custom_inputs'
local mdl_pals		= require'custom_palettes.palettes_main'
local mdl_planes	= require'custom_planes.planes_main'
local mdl_player	= require'custom_player'
local mdl_level		= require'custom_level'
mdl_exe          	= require'c_exe'
local mdl_sound		= require'custom_music_sounds'
local mdl_camera	= require'custom_camera'
local mdl_cpowerup	= require'custom_powerup'
local mdl_codes		= require'game_codes.codes_main'
local mdl_plasma	= require'game_plasma_sword'
local mdl_cmap		= require'custom_assets'
local mdl_clwnd		= require'game_custom_dlg.cdlg_main'
local mdl_csaves	= require'game_csaves.csaves_main'
local mdl_cmd		= require'game_argvs'
local mdl_mousewh	= require'custom_mousewheel'
local mdl_plugins	= require'game_plugins'

-- Adds the built-in logics as functions to the global environment:
setmetatable(_G, { __index = function(_, key) return mdl_logics.GetBuiltInLogic(key) end } )
-- See the list of all built-in logics in the 'BuiltInLogics' table in the 'CrazyHookConsts' module

_nResult            = mdl_exe.nResult
LevelBasedData      = mdl_exe.LevelBasedData
InfosDisplay        = mdl_exe.InfosDisplay
MultiMessage        = mdl_exe.MultiMessage
_chameleon          = mdl_exe.Chameleon
PlayAreaRect        = mdl_exe.PlayAreaRect
_CurrentPowerup     = mdl_exe.CurrentPowerup
_PowerupTime        = mdl_exe.PowerupTime
_TeleportX          = mdl_exe.TeleportX
_TeleportY          = mdl_exe.TeleportY

-- Debug text table (used with MPTEXT code):
debug_text       = {"CrazyHook version "..version}

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[[[ CrazyHook core ]]]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local firstPalette = ffi.new("CPalette") -- the initial level's palette
local doOnlyOnce = false -- used in chameleon's loop
local chamState = chamStates
local test = false

-- The link between Lua and the DLL. After initial execution of the CrazyHook.lua file, all the Lua code will go through this function:
function _ch_link(funName, ptr)
	local fun = _G[funName]
	if type(fun) == "function" then
		xpcall(function()
			fun(ptr)
		end,
		function(err)
			MessageBox(err .. "\n" .. debug.traceback(), funName .. " error")
		end)
	end
end

-- called when the CustomLogic is created:
function _ch_create(ptr)
    local addr = tonumber(ffi.cast("int", ptr))
	local object = ffi.cast("ObjectA*", addr)
	object.MoveClawX, object.MoveClawY = 0, 0
    if not mdl_objects.ObjectsList[object.ID] then
	    mdl_objects.ObjectsList[object.ID] = object
    end
	if addr and not mdl_objects.ObjectsData[addr] then
		mdl_objects.ObjectsData[addr] = {}
	end
	mdl_exe._RegisterHitHandler(object, "CustomHit")
	mdl_exe._RegisterAttackHandler(object, "CustomAttack")
end

-- calls "main" function of a custom logic:
function _ch_logic(ptr)
    local addr = tonumber(ffi.cast("int", ptr))
	assert(mdl_objects.ObjectsData[addr])
	local object = ffi.cast("ObjectA*", addr)
	mdl_logics.LogicMain(object)
end

-- calls "hit" function of a custom logic:
function _ch_hit(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	mdl_logics.LogicFunction(object, "Hit")
end

-- calls "attack" function of a custom logic:
function _ch_attack(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	mdl_logics.LogicFunction(object, "Attack")
end

-- calls "destroy" function of a custom logic (when the object is destroyed):
function _ch_destroy(ptr)
	local object = ffi.cast("ObjectA*", ptr)
	mdl_logics.LogicFunction(object, "Destroy")
end

-- The menu start hook:
function _ch_menu()
	mdl_codes.MenuReset()
	CreateObject{
		x = 720,
		y = 100, -- the same Y as claw in the menu
		z = 5000,
		flags = 0, -- flags must be 0 for the objects in the menu
		image = "MENU_CRAZYHOOK",
		name = "_CrazyHookMenu" -- see the logic in Assets\GAME\LOGICS directory
	}
	mdl_plugins.MenuExec()
end

-- Restores the game's state:
local function _ch_reset()
	mdl_exe.NoEffects[0] = 0
    mdl_privc.RestoreGamesCode()
	mdl_codes.ClearGDI()
	doOnlyOnce = false
    table.clear(mdl_logics.Environment)
    table.clear(mdl_logics.CustomLogics)
    table.clear(mdl_objects.ObjectsList)
    table.clear(mdl_objects.ObjectsData)
    table.clear(mdl_objects.ObjectsNames)
	mdl_cmap.MapName = ""
	mdl_cmap.MapPath = ""
	mdl_cmap.FullMapPath = ""
	mdl_cpowerup.PtrPowerupHandler = nil
	mdl_camera.PtrCameraObject = nil
	ResetMultiMessage()
	mdl_clwnd.ChosenLevel = ""
end

-- Map a single object and call its "init" function:
function _ch_map_object(addr)
	local object = ffi.cast("ObjectA*", addr)
	mdl_objects.ObjectsList[object.ID] = object
	mdl_objects.ObjectsData[addr] = mdl_objects.ObjectsData[addr] or {}
	mdl_logics.LogicFunction(object, "Init")
	-- Remove unobtainable treasures from some objects in custom levels:
	if not IsCustomLevel() then return end
	local logic = object.Logic
	if logic == DoNothing or logic == DoNothingNormal or logic == BehindCandy or logic == FrontCandy or logic == BehindAniCandy or
	logic == FrontAniCandy or logic == AniCycle then
		object.Powerup = 0
		object.UserRect1 = {0,0,0,0}
		object.UserRect2 = {0,0,0,0}
	end
end

-- "Chameleon":
function _ch_map(ptr)
	mdl_clwnd.Main(ptr) -- custom level window 
    mdl_cmd.Main(ptr) -- employing commandline arguments 
    mdl_cmap.Main() -- loading assets
	mdl_codes.Main(ptr) -- managing cheatcodes
	mdl_csaves.Main(ptr) -- save system for custom levels
	mdl_mousewh.Main(ptr) -- listening to mouse wheel events

	local cham = _chameleon[0]
	local arg = tonumber(ffi.cast("int", ptr))

	if cham == chamState.LoadingAssets and IsCustomLevel() then
		local logicspath = GetMapFolder() .. "\\LOGICS"
		mdl_logics.LoadFolderRecursive(logicspath)
	end

	if cham == chamState.LoadingObjects then
		if not doOnlyOnce then
			mdl_logics.CustomFunction"OnMapLoad"
			mdl_pals.Copy(firstPalette, nRes(11)+0x360) -- is used to come back from other palette changes
			doOnlyOnce = true
		end
		_ch_map_object(arg)
	end

    if cham == chamState.LoadingEnd then
		mdl_camera.MapCameraPtr()
		mdl_logics.CustomFunction"OnMapLoad2"
		if test == true then CreateObject{name='_TestLogic'} end
    end

	if cham == chamState.OnPostMessage then
		local message = _message
		-- when the player finishes/exits the level:
		if arg == message.ExitLevel or arg == message.LevelEnd or arg == message.MPMOULDER or (arg >= 0x809C and arg <= 0x80A9) then
			mdl_logics.CustomFunction"OnLevelEnd"
			_ch_reset()
		-- ChangeResolution and BnW wrappers:
		elseif arg == message.ChangeResWrapper then
			mdl_exe._ChangeResolution(nRes(), nRes(31), nRes(32))
		elseif arg == message.BnWWrapper then
			mdl_exe._BnW(nRes(11,11))
		end
	end

	if cham == chamState.Gameplay then
		mdl_logics.CustomFunction("OnGameplay", arg)
		mdl_plasma.Main()
	end

	-- Plugins:
	mdl_plugins.MapExec(ptr)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Assets ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Returns void* to a specified sound asset.
function LoadAsset(name)
	return mdl_cmap.LoadAsset(10, name)
end

-- Returns void* to a specified image asset.
function LoadAssetB(name)
	return mdl_cmap.LoadAsset(4, name)
end

-- Returns void* to a specified ani asset.
function LoadAssetC(name)
	return mdl_cmap.LoadAsset(11, name)
end

function LoadFolder(name)
	return mdl_exe._LoadFolder(nRes(13), name)
end

function MapSoundsFolder(path, short)
	mdl_exe._MapSoundsFolder(nRes(11, 3, 10), path, short, "_")
end

function MapImagesFolder(path, short)
	mdl_exe._MapImagesFolder(nRes(11, 3, 4), path, short, "_")
end

function MapAnisFolder(path, short)
	mdl_exe._MapAnisFolder(nRes(11, 3, 11), path, short, "_")
end

LoadSingleFile = mdl_exe._LoadSingleFile

MapMusicFile = mdl_cmap.MapMusicFile

IncludeAssets = mdl_cmap.IncludeAssets

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Game Manager ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------


-- Traverses through a given structure and returns an int value.
function CastGet(v, ...)
    for i = 1, select("#", ...) do   
        v = ffi.cast("int*", v)[select(i, ...)]
    end
    return v
end

-- Traverses through a given structure and sets an int value.
function CastSet(x, v, ...)
    local count = select("#", ...)
    for i = 1, count - 1 do
        v = ffi.cast("int*", v)[select(i, ...)]
    end
    ffi.cast("int*", v)[select(count, ...)] = x
end

-- Gets a value from nRes. It's an important structure, that contains most of the level's data. It's mostly unknown.
function nRes(...) 
	return CastGet(_nResult[0], select(1, ...))
end

-- Sets a value in nRes. It's an important structure, that contains most of the level's data. It's mostly unknown.
function snRes(x, ...)
	CastSet(x, _nResult[0], select(1, ...))
end

-- Gets a value from nRes(12).
function Game(...)
	return CastGet(_nResult[0][12], select(1, ...))
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- [[[[ Custom Logics API functions ]]]] ------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Returns 3 for single-player or 4 for multi-player.
function GetGameType()
	return (nRes(11) == 0 or nRes(11,0) == 0) and 0 or ffi.cast("int*", nRes(11,0,4)+1)[0]
end

function IsCustomLevel()
	return mdl_cmap.MapPath ~= ""
end

-- Returns full path to the current custom level.
function GetFullMapPath()
	return ffi.string(ffi.cast("const char*", nRes(49)))
end
GetMapName = GetFullMapPath

-- Returns full path to the current custom level's assets directory.
function GetMapFolder()
	return mdl_cmap.MapPath
end

-- Returns the level name:
function GetLevelName()
	return mdl_cmap.MapName
end

-- Returns in-game time in miliseconds.
function GetTime()
	return mdl_exe.MsCount[0]
end
GetTicks = GetTime

-- Returns time in miliseconds since the start of the local machine.
function GetRealTime()
	return mdl_exe.RealTime[0]
end

-- Returns the fps counter.
function GetFPS()
    return nRes(6)
end

-- Returns the player name.
function GetPlayerName()
    return ffi.string(ffi.cast("const char*",nRes(25)+20))
end

-- Text out on screen.
function TextOut(text)
	mdl_exe._TextOut(ffi.cast("int&", 0x535910), tostring(text))
end

-- Makes the screenshot and saves it in the game's directory.
function MakeScreenshot(filename)
	if filename == nil then
		return mdl_exe._DumpScreen(nRes(14),nRes())
	end
	return mdl_exe._MakeScreenToFile(nRes(12,1,4,11), filename, 1, nRes(11,11,4), 0)
end

-- Returns the logic's memory address.
function GetLogicAddr(obj)
    return HEX(ffi.cast("int*", obj._v)[4])
end

-- Returns the object's name (only objects with CustomLogic can have a name).
function _GetLogicName(obj)
	return mdl_objects.GetLogicName(obj)
end

-- Jumps to the retail level (1-14).
function JumpToLevel(levelCode)
	mdl_exe._JumpToLevel(nRes(), levelCode)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Cheats ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Returns true if any major cheat has been used by the player, otherwise false.
function CheatsUsed()
	return nRes(18,74) ~= 0
end

--[[ Registers new cheat exclusively for a custom level. The argument is a table that should contain the following parameters:
	Name - the cheat name (required).
	Type - the cheat type (0 - major, 1 - minor, 2 - minor for custom levels, 3 - none). It defaults to 0 if not specified.
	Toggle - the cheat's toggle. Specify it only for cheats than can be turned on and off. 0 - turned off, 1 - turned on.
	Enable - a function called every time the cheat is triggered (when it doesn't have Toggle) or turned on (when it has Toggle).
	Disable - a function called when cheat is turned off.
	Text - a string that shows on screen when cheat is triggered or enabled/disabled (in this case "On" or "Off" is added to string).
	Gameplay - a function that will be called continuously on gameplay when cheat is active.
	Teleport - a function called when Claw teleports and the cheat is active.
	ClawDeath - a function called when Claw dies and the cheat is active.
	Init - a function called on the level load.
The function returns the new ID number of the cheat if successful, otherwise nil.]]
function RegisterCheat(params)
	return mdl_codes.RegisterCustomCheat(params)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Camera ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Takes the map coordinates x and y (or a Point) as arguments. When called, the camera will go to and then center on this coordinates.
function CameraToPoint(x,y)
	mdl_camera.CameraToPoint(x,y)
end

-- Takes game's Object as argument. When called, the camera will go to and center on this object.
function CameraToObject(obj)
	mdl_camera.CameraToObject(obj)
end

-- Returns Point of the camera's current position. 
function GetCameraPoint()
	return mdl_camera.GetCameraPoint()
end
GetCameraPos = GetCameraPoint

-- Takes the x, y coordinates (or a Point) as arguments and instantly sets the camera position on this coordinates.
function SetCameraPoint(x,y)
	mdl_camera.SetCameraPoint(x,y)
end
SetCameraPos = SetCameraPoint

--[[ Sets the horizontal and vertical camera's speeds, when the camera is not in the default mode.
Takes effect with CameraToPoint and CameraToObject functions. Default speed is 400, 400.]]
function SetCameraToPointSpeed(vx, vy)
	mdl_camera.SetCameraToPointSpeed(vx, vy)
end

-- When called, the camera will be set to default mode, which means it will follow Claw.
function CameraToClaw()
	mdl_camera.CameraToClaw()
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Level ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Takes a retail level number (1-14) as argument and sets default Rects for basic platforms.
LoadBaseLevDefaults = mdl_exe._LoadBaseLevDefaults

-- Sets a default death type for the map. Either 0 (Spikes) or 1 (Goo). Tip: use function SwapSound to change the default sound too.
function SetDeathType(t)
    mdl_level.SetDeathType(t)
end

-- Sets a given Object as boss. 
function SetBoss(object)
    mdl_exe.CurrentBoss[0] = object == 0 and nil or object
end

-- Returns the current boss or nil, if there is no boss.
function GetBoss()
	return mdl_exe.CurrentBoss[0] ~= nil and mdl_exe.CurrentBoss[0] or nil
end

-- Returns the level's width.
function GetMapWidth()
    return Game(9,23,12)
end

-- Returns the level's height.
function GetMapHeight()
    return Game(9,23,13)
end

-- Returns true if the given coordinates are inside the current map.
function InMapBoundaries(x,y)
    return x >= 0 and x < Game(9,23,12) and y >= 0 and y < Game(9,23,13)
end

-- Takes the map coordinates as arguments. Sets the position to teleport Claw upon using MPSKINNER cheat-code.
function SetBossFightPoint(x, y)
    mdl_level.SetBossFightPoint(x, y)
end

-- Shakes the camera for the given amount of time in miliseconds or 1000ms if not specified.
function Earthquake(t)
	mdl_exe._Quake(tonumber(t) or 1000)
end

--[[ Returns the amount of a specified treasure type possible to collect in the current map. 
See the 'TreasureType' table in the 'CrazyHookConsts' module.]]
function GetTreasuresNb(t)
	return mdl_level.GetTreasuresNb(t)
end

--[[ Adds a specified amount of a given treasure type possible to collect in the current map. 
See the 'TreasureType' table in the 'CrazyHookConsts' module.]]
function RegisterTreasure(t, nb)
	mdl_level.RegisterTreasure(t, nb)
end

--[[ Returns pointer to CBasePickups structure, that controls the values given to the player when picking up some items. Look for 
'struct CBasePickups' in 'CrazyHook.h' file. Example:
	local pickups = BasePickupsVals()
	pickups.Food = 15 -- the level's food will be restoring 15 HP
	pickups.BigPotion = 35 -- the big health potion will be restoring 35 HP
	pickups.Catnip1 = pickups.Catnip1 + 3000 -- the duration of default catnip will be extended by 3000ms ]]
function BasePickupsVals()
	return mdl_exe.Pickups
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Inputs ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[When called without arguments, returns the input state of all controls.
If called with an argument, returns true if the input mapped to a specified control is being pressed, otherwise returns false.
See the 'InputFlags' table in the 'CrazyHookConsts' module.]]
function GetInput(input)
	return mdl_inputs.GetInput(input)
end

--[[Returns true if the specified key or an input mapped to a specific control is being pressed, otherwise returns false.
Argument must be a string. See the 'InputFlags' and 'VKey' in the 'CrazyHookConsts' module for the available arguments.]]
function KeyPressed(key)
	return mdl_inputs.KeyPressed(key)
end

--[[ Returns true if the specified key or an input mapped to a specific control is being pressed now, otherwise returns false.
Argument must be a string. Use if function 'KeyPressed' doesn't work for your needs. 
See the 'InputFlags' and 'VKey' in the 'CrazyHookConsts' module for the available arguments.]]
function GetKeyInput(key)
	return mdl_inputs.GetKeyInput(key)
end
GetVKInput = GetKeyInput

--[[ Sends an input press to the window. Argument must be a string - either a key or an input mapped to a game controls.
See the 'InputFlags' and 'VKey' in the 'CrazyHookConsts' module for the available arguments. Returns 1 if successful or 0 if not.]]
function InputPress(key)
	return mdl_inputs.InputPress(key)
end

--[[ Sends an input release to the window. Argument must be a string - either a key or an input mapped to a game controls.
See the 'InputFlags' and 'VKey' in the 'CrazyHookConsts' module for the available arguments. Returns 1 if successful or 0 if not.]]
function InputRelease(key)
	return mdl_inputs.InputRelease(key)
end

-- Returns the cursor position as Point.
function GetCursorPos()
	return mdl_inputs.GetCursorPos()
end

-- Returns 1 if the mouse wheel has been scrolled up, -1 if down, otherwise 0.
function GetMouseWheelEvent()
	return mdl_mousewh.GetMouseWheelEvent()
end

-- Returns a pointer to the game controls. Look for 'struct CControlsMgr' in 'CrazyHook.h' file.
function GetGameControls()
	return mdl_exe.ControlsMgr[0][0]
end

--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------- [[ Claw ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ Returns a pointer to the Claw Object. See the Object's structures in 'CrazyHook.h' file - look for 'struct ObjectA' and 
'struct ObjectV'.]]
function GetClaw()
	return mdl_exe.Claw[0]
end

-- Returns a pointer to the CPlayerData structure. See it in 'CrazyHook.h' file - look for 'struct CPlayerData'.
function PlayerData()
	return GetClaw()._v._p
end
PData = PlayerData

-- Returns the number of Claw deaths since a level start.
function Attempt()
	return PlayerData().AttemptNb
end
Attemp = Attempt

--[[ Returns respawn Point if at least one checkpoint has been triggered or SetRespawnPoint function has been used.
Otherwise returns Point: X = -1, Y = -1. For the first spawn cordinates check PlayerData.]]
function GetRespawnPoint()
	return ffi.cast("Point*", nRes(11)+68)
end

--[[ If called without arguments, returns Claw's current attack type as a string. 
If called with a string argument, returns the attack type that contains this string based on the attack Claw is using.
Otherwise returns nil. See 'AttackString' table in the 'CrazyHookConsts' module for the possible attack types. ]]
function GetClawAttackType(str)
	return mdl_player.GetClawAttackType(str)
end

-- Freezes Claw and locks all the inputs.
function BlockClaw()
	mdl_player.BlockClaw()
end

-- Unfreezes Claw and unlocks the inputs.
function UnblockClaw()
	mdl_player.UnblockClaw()
end

-- Freezes Claw for a specified time in miliseconds and sets the "confused" frame for Claw.
function StunClaw(ms)
    snRes(ms or 0,11,473)
end

-- Teleports Claw to the specified map coordinates x and y.
function TeleportClaw(x, y)
	mdl_player.TeleportClaw(x, y)
end
Teleport = TeleportClaw

-- Kills Claw.
function KillClaw()
	mdl_player.KillClaw()
end

-- Kills Claw like a death tile would.
function KillClawByDeathTile()
	GetClaw().Flags.OnDeathTile = true
end

-- Substracts the specified amount of health from Claw.
function ClawTakeDamage(dmg)
	mdl_player.ClawTakeDamage(dmg)
end

-- When called, Claw jumps a specified height.
function ClawJump(height)
	mdl_exe._ClawJump(GetClaw(), height)
end

-- Sets a respawn point on a given x, y coordinates or, if called without arguments, on a current Claw's position.
function SetRespawnPoint(x, y)
	mdl_player.SetRespawnPoint(x, y)
end

-- Sets the time of running before the running speed activates (default: 1500).
function SetRunningSpeedTime(t)
	mdl_player.SetRunningSpeedTime(t)
end

-- Sets the damage dealt by Claw's pistol bullet (default: 8).
function SetClawsPistolDmg(dmg)
	mdl_player.SetClawProjectileDamage(0, dmg)
end

-- Sets the damage dealt by Magic Claw (default: 25).
function SetClawsMagicDmg(dmg)
	mdl_player.SetClawProjectileDamage(1, dmg)
end

-- Sets the damage dealt by the dynamite explosion (default: 15).
function SetClawsDynamiteDmg(dmg)
	mdl_player.SetClawProjectileDamage(2, dmg)
end

-- Sets Claw's normal jump height (default: 145)
function SetNormalJumpHeight(height)
	mdl_player.SetJumpHeight(0, height)
end

-- Sets Claw's jump height with the running speed (default: 170)
function SetRunningJumpHeight(height)
	mdl_player.SetJumpHeight(1, height)
end

-- Sets Claw's jump height with the catnip (default: 195)
function SetCatnipJumpHeight(height)
	mdl_player.SetJumpHeight(2, height)
end

-- Sets Claw's jump height with the MPJORDAN cheat-code (default: 195)
function SetJordanJumpHeight(height)
	mdl_player.SetJumpHeight(3, height)
end

-- Sets Claw's falling speed cap (default: 1000)
function SetClawFallSpeedCap(speed)
	PrivateCast(speed, "double*", 0x532BE8, 0)
end

-- Multiplies Claw's horizontal speed (in all cases, not just running/walking).
function MultClawSpeed(mul)
	mdl_player.MultClawSpeed(mul)
end

-- Multiplies Claw's climbing speed.
function MultClawClimbSpeed(mul)
	mdl_player.MultClawClimbSpeed(mul)
end

--[[ Returns ID number of the current powerup or 0 if no powerup in active. See 'Powerup' table in 'CrazyHookConsts' module for all 
powerups IDs.]]
function GetCurrentPowerup()
	return _CurrentPowerup[0]
end

-- Returns time left of a powerup in miliseconds or 0 if no powerup in active.
function GetCurrentPowerupTime()
    return _PowerupTime[0]
end

--[[ Gives Claw a powerup for a specified time in seconds, or 30 seconds if not given. Adds the time, if the same powerup is already 
active. See 'Powerup' table in 'CrazyHookConsts' module for the available powerups. ]]
function ClawGivePowerup(powerupID, time)
	mdl_exe._ClawGivePowerup(powerupID, time and time * 1000 or 30000)
end

-- Gives Claw a custom powerup for a specified time (in miliseconds!), or 30s if not given. First argument must be a function.
function CustomPowerup(name, time)
	mdl_cpowerup.CustomPowerup(name, time)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Music ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Sets the music track to play.
function SetMusic(name)
	mdl_exe._SetMusic(nRes(20), string.upper(name), 1)
end

-- Sets the music track speed.
function SetMusicSpeed(name, speed)
	mdl_sound.SetMusicSpeed(name, speed)
end

-- Returns the table of available music tracks.
function GetMusicTracks()
    return mdl_cmap.MusicTracks
end

-- Returns true if the specified music track is playing, otherwise false.
function GetMusicState(name)
	return mdl_sound.GetMusicState(name)
end

-- Stops the specified music track.
function StopMusic(name)
	mdl_sound.StopMusic(name)
end

-- Returns the global music volume.
function GetMusicVolume()
	return mdl_exe._GetMusicVolume()
end

-- Sets the global music volume (0-100).
function SetMusicVolume(vol)
	mdl_sound.SetMusicVolume(vol)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Sounds ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ Plays the sound. Only the sound name is required. 2nd argument sets a volume (0-100, default: global sound volume).3rd 
argument sets panning (artificial stereo sound, default: 0). 4th argument sets pitch (default: 0). 5th argument, if not 0, causes the 
sound to play in a loop (default: 0).]]
function PlaySound(name, volume, stereo, pitch, loop)
	mdl_sound.PlaySound(name, volume, stereo, pitch, loop)
end

-- Plays the sound as the Claw dialog. The speech bubble will appear above Claw, when the sound is played.
function ClawSound(name)
	mdl_exe._ClawSound(name, 0)
end

-- Sets one sound as another. This function cannot be reversed.
function ReplaceSound(name1, name2)
    mdl_sound.ReplaceSound(name1, name2)
end

-- Swaps the first and the second sound.
function SwapSound(name1, name2)
    mdl_sound.SwapSound(name1, name2)
end

-- Sets the specified sound as "GAME_NULL". This function cannot be reversed.
function RemoveSound(name)
    mdl_sound.RemoveSound(name)
end

-- Stops the sound.
function StopSound(name)
	mdl_sound.StopSound(name)
end

-- Plays the sound as the enemy dialog. The speech bubble will appear above the object, when the sound is played.
function EnemySound(object, name)
    mdl_sound.EnemySound(object, name)
end

-- Returns the global sound volume (0-100).
function GetSoundVolume()
	return mdl_exe.SoundVolume[0]
end

--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- [[ Graphics ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Returns the image by name.
function GetImage(name)
	return ffi.cast("CImage*", LoadAssetB(name))
end

-- Returns the imageset name.
function GetImgStr(image)
	return tostring(image)
end

-- Sets resolution.
function ChangeResolution(width, height)
	snRes(width, 31) snRes(height, 32)
	ffi.C.PostMessageA(nRes(1,1), 0x111, _message.ChangeResWrapper, 0)
end

-- Returns width and height of the current resolution.
function GetResolution()
	return nRes(31), nRes(32)
end

-- Sets high details.
function SetHighDetails()
    snRes(1, 105)
end

-- Sets low details.
function SetLowDetails()
    snRes(0, 105)
end

-- Returns true if high details are set, otherwise false.
function GetDetailsState()
    return nRes(105) == 1
end

--[[ Sets the image flag for the specified imageset. Doesn't work for all imagesets. See 'ImageFlag' table in 'CrazyHookConsts' for 
the available image flags.]]
function SetImgFlag(img, flag)
	mdl_images.SetImgFlag(img, flag)
end

--[[ Sets a color (or more precisely: offset to the color table) for the given imageset. 
Works only when the imageset's flag is set to 'Shadow' or 'ColorFill' (by calling the 'SetImgFlag' function).]]
function SetImgColor(img, color)
	mdl_images.SetImgColor(img, color)
end

--[[ Sets a color table for the specified imageset. Color table can be either 'Light' or 'Average'. Color tables are responsible for
the semi-transparency effects in game e.g. with invisibility powerup. Works only when the imageset's flag is set to 'Ghost' or 
'Shadow' (calling 'SetImgFlag' function after this function might reverse the changes, so always call them in order).]]
function SetImgCLT(img, clt)
	mdl_images.SetImgCLT(img, clt)
end
SetImgClt = SetImgCLT

--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- [[ Palettes ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Sets the current palette colors to black and white.
function BnW()
	ffi.C.PostMessageA(nRes(1,1), 0x111, _message.BnWWrapper, 0)
end

-- Returns new palette filled with black (#000000).
function CreatePalette()
	return ffi.new("CPalette")
end

-- Returns a copy of the first palette in the level.
function GetFirstPalette()
	local new = ffi.new("CPalette")
	mdl_pals.Copy(new, firstPalette)
	return new
end

-- Returns a copy of the current palette.
function GetCurrentPalette()
	local new = ffi.new("CPalette")
	mdl_pals.Copy(new, nRes(11,11,4,4))
	return new
end

--[[ Loads the palette file. A palette has 256 colors. The file can be in one of the formats: PAL, ACT, TXT. 
PAL and ACT are binary files in which each color has 3 bytes: red, green and blue.
The TXT text file must contain one color in html format per line.
The second argument is optional, it's the destination of the palette in virtual memory.]]
function LoadPaletteFile(filename, dest)
	return mdl_pals.LoadPalette(filename, dest)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Palette methods ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local palette = mdl_pals.Methods

-- Sets the palette to use in the game.
function palette:Set(code)
	mdl_pals.Copy(nRes(11,11,4,4), self)
    mdl_exe._SetPalette(nRes(11,11,4), 0)
	if not code then -- to avoid collision with MPALICE and MPGLOOMY.
		mdl_codes.CORG.MPGLOOMY.Toggle = 0
		mdl_codes.CNEW.MPALICE.Toggle = 0
	end
end

-- Sets the palette to use in the game.
function palette:Render()
	self:Set()
end

--[[ Sets the color at given index in the palette. Index must be a number in range 0-255 and the color either a string in hex format, a
table with elements Red, Green and Blue or a CColor type. The function returns the palette.]]
function palette:SetColor(index, color)
	return mdl_pals.SetColor(self, index, color)
end

--[[ Returns the color at given index in the palette. Index must be a number in range 0-255. The returned color is in a CColor type. 
It is not a string, but can be compared to a color string in a hex format directly and transformed to a string by using 'tostring' 
function.]]
function palette:GetColor(index)
	return mdl_pals.GetColor(self, index)
end

--[[ Inverts colors in the palette. 1st and 2nd arguments are optional and specify the range. If not given, the range will default to 
0-255, which is the entire palette. The function returns the palette.]]
function palette:InvertColors(min, max)
    return mdl_pals.Invert(self, min, max)
end

--[[ Inverts only a given color channel in the palette. The color channel can be "red", "green" or "blue". 2nd and 3rd arguments are 
optional and specify the range. If not given, the range will default to 0-255, which is the entire palette. The function returns the 
palette.]]
function palette:InvertChannel(ch, min, max)
	return mdl_pals.InvertChannel(self, ch, min, max)
end

--[[ Changes palette colors by the specified amount of red, green and blue. 4th and 5th arguments are optional and specify the range. 
If not given, the range will default to 0-255, which is the entire palette. Example:
	palette:AdjustRGB(10, -10, 0, 1, 128):Set()
It will add 10 to red value and substract 10 from green value for each color in range 1-128 in the palette. The function returns the 
palette.]]
function palette:AdjustRGB(r, g, b, min, max)
	return mdl_pals.AdjustRGB(self, r, g, b, min, max)
end

--[[ Changes palette colors by converting them to HSL format, modifing the hue, saturation and lightness and converting back to RGB.
Works similar to AdjustRGB function. 4th and 5th arguments are optional and specify the range. If not given, the range will default 
to 0-255, which is the entire palette. Example:
	palette:AdjustHSL(30, -10, 0):Set()
It will shift hue by 30 degress and reduce saturation by 10 for each color in the palette. Note that a color's hue is in the range 
0-359, while saturation and lightness in the range 0-100. The function returns the palette.]]
function palette:AdjustHSL(h, s, l, min, max)
    return mdl_pals.AdjustHSL(self, h, s, l, min, max)
end

--[[ Turns colors in the palette to grayscale (the same effect as MPGLOOMY). 1st and 2nd arguments are optional and specify the range. 
If not given, the range will default to 0-255, which is the entire palette. The function returns the palette.]]
function palette:BlackAndWhite(min, max)
	return mdl_pals.BlackAndWhite(self, min, max)
end

--[[ Swaps the color channels in the palette. Color channels can be "red", "green" or "blue". 1st and 2nd arguments are optional and 
specify the range. If not given, the range will default to 0-255, which is the entire palette. The function returns the palette.]]
function palette:SwapChannels(ch1, ch2, min, max)
	return mdl_pals.SwapChannels(self, ch1, ch2, min, max)
end

--[[ Exports the current palette to a file and returns the palette. If not specified, the palette file will be created in the game's 
main directory.]]
function palette:ExportToFile(filename)
    return mdl_pals.ExportToFile(self, filename)
end

-- Returns a copy of the palette.
function palette:Copy()
	return mdl_pals.CopyToNew(self)
end

--[[ Creates the LIGHT.CLT file based on the palette (this file is responsible for the light effects in the game). The file will be 
created in the game's main directory.]]
function palette:CreateLightCltFile()
	mdl_pals.CreateCltFile(self, 0)
end

--[[ Creates the AVERAGE.CLT file based on the palette (this file is responsible for the transparency effects in the game). The file 
will be created in the game's main directory.]]
function palette:CreateAverageCltFile()
    mdl_pals.CreateCltFile(self, 1)
end

--[[ Creates a CUSTOM.CLT file based on the palette and the provided function. The provided function needs to take 3 arguments, out of 
which two first are "CColor" type, and the 3rd is a number (index value), and it must return "CColor" type. The CLT file will be 
created in the game's main directory.]]
function palette:CreateCustomCltFile(fun)
	mdl_pals.CreateCltFile(self, fun)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ Color Lookup Tables ]] -----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Loads and sets the AVERAGE.CLT file.
function LoadAverageCLT(filename)
    mdl_pals.LoadCLT(filename, nRes(11,475,2))
end

-- Loads and sets the LIGHT.CLT file.
function LoadLightCLT(filename)
    mdl_pals.LoadCLT(filename, nRes(11,474,2))
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ Multiplayer ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ Sends up to 3 integers and sets them in a global MultiMessage variables for all other players in the multiplayer game. The last 
argument, if true, will set the MultiMessage variables also for the player that sent the message. The messages can be checked in 
MultiMessage[0], MultiMessage[1] and MultiMessage[2]. ]]
function SendMultiPlayerMessage(message0, message1, message2, affects_player)
	mdl_level.SendMPMessage(message0, message1, message2, affects_player)
end
SendMPMessage = SendMultiPlayerMessage

-- Sets the MultiMessage variables to zero.
function ResetMultiMessage()
    MultiMessage[0] = 0 MultiMessage[1] = 0 MultiMessage[2] = 0
end

-- Returns true when the curses in multiplayer game are enabled, othwerwise false.
function GetCursesState()
	return mdl_exe.EnableCurses[0] ~= 0
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ Objects ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ See the object's fields in 'CrazyHook.h' file - look for 'struct ObjectA' and 'struct ObjectV'.]]

--[[ Creates an object with a specified parameters. Parameters must be in a table. Example:
	local crown, coin = DropItem.CrownBlue, DropItem.Coin
	CreateObject{
		X = GetClaw().X+100, 
		Y = GetClaw().Y, 
		Logic = "Officer", 
		Powerup = crown, 
		UserRect1 = {coin, coin, coin, coin}, 
		UserRect2 = {0,0,0,0}
	}
	-- this will create an Officer in front of Claw, that will drop a blue crown and 4 coins upon defeat.

A parameter can be any field of ObjectA or ObjectV structure. 
See the object's fields in 'CrazyHook.h' file - look for 'struct ObjectA' and 'struct ObjectV'.
For custom logics you can create your own fields. Custom fields can be of any type.
If X or Y are not given, the central point of the screen will be used.

Only objects with "CustomLogic" can have a Name parameter. If Logic is not specified, "CustomLogic" will be used. Example:
	CreateObject{Name = "Foo"}
	-- assuming that "Foo" exists as a Lua script, this will create the object at the center of the screen.]]
function CreateObject(params)
	return mdl_objects.CreateObject(params)
end

-- Returns the number that can be used as a unique (not yet used) ID for an object.
function GetAvailableID()
	return mdl_objects.GetAvailableID()
end
GetEmptyID = GetAvailableID

--[[ Calls a function given as an argument to this function and calls it for all active objects or, if called without arguments, 
initializes all objects around the player. For the interface elements (which are also objects) use function LoopThroughInterfaces. ]]
function LoopThroughObjects(fun, arg)
    return mdl_objects.LoopThroughObjects(fun, arg)
end

--[[ Returns an object with a specified ID. Might not work as intended in older levels, because there can be multiple objects with 
the same ID.]]
function GetObject(id)
	return mdl_objects.ObjectsList[id]
end

--[[ Creates a "goodie" - an object that can be picked by Claw. The argument must be a table with these paramaters:
	X - X position (claw's X position if not specified),
	Y - Y position (claw's Y position if not specified),
	Z - Z position (1000 if not specified),
	Powerup - goodie number, look in 'DropItem' in 'CrazyHookConsts' module (coin (33) if not specified)
Example:
	CreateGoodie{Powerup = DropItem.ExtraLife}
	This will create an extra life on the Claw's position.]]
function CreateGoodie(tab)
	mdl_objects.CreateGoodie(tab)
end

--[[ Creates a HUD element - an object that doesn't move with the camera. The function takes the same arguments as CreateObject, but
additionally you can specify the X and Y params as negative integers (the position on the screen will then be counted from the 
right-down corner, instead of the left-up one).]]
function CreateHUDObject(params)
    return mdl_objects.CreateHUDObject(params)
end

--[[ The same as LoopThroughObjects, but for interface elements.]]
function LoopThroughInterfaces(fun, arg)
    return mdl_objects.LoopThroughInterfaces(fun, arg)
end

--[[ Returns the original interface object. First argument must be a string or a number. See the 'InterfaceLogics' table in the 
'CrazyHookConsts' module for the available options. The second argument is optional - a number - if specified will return the digit 
that accompanies the interface element. Examples:
	local treasureChest = GetInterface("ScoreFrame") -- will return the score's treasure chest.
	local livesDigit = GetInterface(InterfaceLogics.LivesFrame, 1) -- will return the digit for claw's lives
	local secondAmmoDigit = GetInterface("WeaponFrame", 2) -- will return the second digit for weapon's ammo
]]
function GetInterface(name, digit)
	return mdl_objects.GetInterface(name, digit)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Object's methods ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local objectA = mdl_objects.Methods

-- Destroys the object.
function objectA:Destroy()
	self.Flags.flags = 0x10000
end

--[[ Moves the object to the given x, y coordinates with the game's physics. The behavior of this function depends on the object's
PhysicsType and MoveRect. For all physics types see the 'PhysicsTypes' table in the constants module. 
The function returns a non-zero value when the object's MoveRect collides from any side with a solid tile, or lands on a ground, 
death, climb tile or other object's MoveRect that has the 'BumpFlag' set to 'Platform'.
To check for collisions, perform a bitwise AND between the result value and a flag from the 'PhysicsFlags' table (found in 
'CrazyHookConsts' module). Examples:
	local result = self:Physics(self.X + self.SpeedX, self.Y + self.SpeedY)
	local pFlags = PhysicsFlags
	local isOnDeathTile = AND(result, pFlags.DeathLand) ~= 0
	local touchesWall = AND(result, pFlags.WallHit) ~= 0
	local isOnGround = AND(result, pFlags.FloorHit) ~= 0 or AND(result, pFlags.GroundLand) ~= 0 or AND(result, pFlags.ElevatorLand) ~= 0
Important caveat: landing on any platform object sets the 'OnElevator' flag for the object and landing on a death tile sets the 
'OnDeathTile' flag. ]]
function objectA:Physics(x, y, pType)
	return mdl_exe._Physics(Game(9), self, x, y, pType or 8)
end

--[[ Returns 1 if there is no solid wall between the given x and object's X, otherwise returns 0. The second optional argument is the 
maximal wall thickness in pixels (32 by default).]]
function objectA:IsVisible(x, thickness)
	return mdl_exe._IsVisible(Game(9), self.X, self.Y, x, thickness or 32)
end

-- Places the object on the solid/ground/ladder tile below it. The object needs to have a MoveRect defined.
function objectA:AlignToGround()
	mdl_exe._AlignToGround(Game(9), self, 0)
end

-- Returns the object's address.
function objectA:GetSelf()
	return tonumber(ffi.cast("int", self))
end

-- Sets the object's imageset. 
function objectA:SetImage(name)
	mdl_exe._SetImage(self, name)
end

-- Sets the object's animation.
function objectA:SetAnimation(name, n)
	mdl_exe._SetAnimation(self, name, n or 0)
end

-- Sets the object's frame.
function objectA:SetFrame(nb)
	mdl_exe._SetImageAndI(self, GetImgStr(self.Image), nb)
end

-- Sets the object's sound.
function objectA:SetSound(name)
    mdl_exe._SetSound(self, name)
end

-- Sets the next animation step.
function objectA:AnimationStep()
	mdl_exe._AnimationStep(tonumber(ffi.cast("int",self)) + 0x1A0, mdl_exe.FrameTime[0])
end

-- Returns true if the object stands on the second object, otherwise false.
function objectA:IsBelow(secondObj)
	return secondObj.Flags.OnElevator and secondObj.ObjectBelow == self
end

-- Drops a coin on the object's position.
function objectA:DropCoin()
	CreateGoodie{x = self.X, y = self.Y, z = self.Z+1}
end

--[[ Drops the goodies from the object. The optional argument is Y coord offset (default: -30). The goodies are specified in the 
UserRect1, UserRect2 and Powerup fields of object. See the 'DropItem' table in 'CrazyHookConsts' module for the available goodies.]]
function objectA:DropGoodies(offY)
	mdl_exe._DropGoodies(self, self.X, offY and self.Y + offY or self.Y-30, self.Z+1)
end

-- Returns the table with custom data of the object.
function objectA:GetData()
	return mdl_objects.ObjectsData[tonumber(ffi.cast("int", self))]
end

-- Displays all keys of the object's custom data table in a message box.
function objectA:ShowData()
	mdl_objects.ShowData(self)
end

--[[ Creates a glitter for the object. Glitter can be one of the following: "gold", "green", "red", "purple" or any image name.
The glitter is "gold" if not specified.]]
function objectA:CreateGlitter(img)
    mdl_objects.CreateGlitter(self, img)
end

-- Destroys the object's glitter.
function objectA:DestroyGlitter()
    if self.GlitterPointer ~= nil then self.GlitterPointer:Destroy() end
end

-- Returns the object's action. Works only with complex logics, like enemies. 
function objectA:GetAction()
    return mdl_objects.GetAction(self)
end

-- Plays the sound and displays a speech bubble above the object.
function objectA:DialogSound(name)
    mdl_exe._EnemySound(self, mdl_exe._GetSoundA(Game(10), name), 0)
end

--[[ Returns true if the object is inside another object's Rect. Otherwise returns false. 2nd argument can be Rect or a string. 
Examples:
	local inHitRect = self:InRect(projectile, "Hit") 
	local inHitRect = self:InRect(object, object.HitRect)
	local clawAttacked = self:InRect(object, "Attack")]]
function objectA:InRect(secondObj, rect)
	return mdl_objects.InRect(self, secondObj, rect)
end

-- Returns true if the object is in a {XMin, YMin, XMax, YMax} rectangle of the second object.
function objectA:InMinMax(secondObj)
	return self.X > secondObj.XMin and self.Y > secondObj.YMin and self.X < secondObj.XMax and self.Y < secondObj.YMax
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Tile properties ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ Returns the pointer to the attributes of the tile with the given ID (if the tile exists, otherwise nil). The returned structure 
can be one of 3 types: "CSingleTileA", "CDoubleTileA" or "CMaskTileA" (look them up in the 'CrazyHook.h' file). Compare the 'Type' 
field with the element from 'TileType' table (found in 'CrazyHookConsts' module). Look for the available attributes in 'TileAttribute' 
table in 'CrazyHookConsts' module. Example:
local tile = GetTileA(1)
if tile ~= nil and tile.Type == TileType.Single then 
	tile.Attribute = TileAttribute.Clear
end]]
function GetTileA(id)
    return mdl_planes.GetTileA(id)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Planes ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ See the plane's fields in 'CrazyHook.h' file - look for 'struct CPlane'.]]

-- Returns the number of planes in the map.
function PlanesCount()
	return Game(9, 15)
end

-- Returns the main plane.
function GetMainPlane()
    return ffi.cast("CPlane*", Game(9, 14, Game(9, 23, 1)))
end

-- Returns the front plane.
function GetFrontPlane()
    return ffi.cast("CPlane*", Game(9, 14, PlanesCount() - 1))
end

-- Returns the plane by its index or name. See the plane's fields in 'CrazyHook.h' file - look for 'struct CPlane'.
function GetPlane(indexOrName)
	return mdl_planes.Planes.GetPlane(indexOrName)
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ Plane methods ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local plane = mdl_planes.PlanesMethods

-- Returns the tile from the x, y plane coordinates. Returns -2 if coordinates are out of bounds.
function plane:GetTile(x, y)
	return mdl_planes.Planes.GetTile(self, x, y)
end

-- Places the tile on the x, y plane coordinates.
function plane:PlaceTile(x, y, tile)
	return mdl_planes.Planes.PlaceTile(self, x, y, tile)
end

-- Fills the tile on the x, y plane coordinates with the plane's color. Change the plane's color by changing the field plane.FillColor
function plane:ColorTile(x, y)
	return mdl_planes.Planes.PlaceTile(self, x, y, mdl_planes.Color)
end

-- Clears the tile on the x, y plane coordinates.
function plane:ClearTile(x, y)
	return mdl_planes.Planes.PlaceTile(self, x, y, mdl_planes.Clear)
end

--[[ Creates a tile layer from the plane. The tile layer needs to be created with a starting position (which are the x, y plane 
coordinates), width and height. The tile layer (or simply layer) is not visible nor interactable in game unless placed on the plane 
with the layer:Place method. The newly created layer is filled with the tiles from the plane.]]
function plane:CreateTileLayer(x, y, w, h)
	return mdl_planes.Planes.CreateTileLayer(self, x, y, w, h)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ Tile Layer methods ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--[[ See the layer structure in 'CrazyHook.h' file - look for 'struct CTileLayer'.]]

local layer = mdl_planes.LayersMethods

-- Places the layer on the plane. To change the plane to place on, use the layer:SetPlane method. Returns the layer.
function layer:Place()
	return mdl_planes.Layers.Place(self)
end

-- Places the layer on the plane. To change the plane to place on, use the layer:SetPlane method. Returns the layer.
function layer:Anchor()
	return mdl_planes.Layers.Place(self)
end

-- Sets a root plane of the layer - so that using the layer:Place method will place the layer on this plane. Returns the layer.
function layer:SetPlane(_plane)
	return mdl_planes.Layers.SetPlane(self, _plane)
end

-- Returns the layer's root plane.
function layer:GetPlane()
	return self.PRoot
end

-- Returns a copy of the layer.
function layer:Clone()
	return mdl_planes.Layers.Clone(self)
end

-- Sets a new starting position on the root plane for the layer. Returns the layer.
function layer:SetPos(x, y)
	return mdl_planes.Layers.SetPos(self, x, y)
end

-- Returns the layer's x, y starting position on the root plane. 
function layer:GetPos(x, y)
	return self.X, self.Y
end

-- Returns the layer's width and height.
function layer:GetSize()
	return self.Width, self.Height
end

-- Shifts the layer by x horizontally and y vertically. Returns the layer.
function layer:Shift(x, y)
	return mdl_planes.Layers.Shift(self, x, y)
end

--[[ Shifts the content of the layer by x vertically and y horizontally. The position and size of the layer itself remain untouched. 
3rd argument is optional - it's the tile that will fill any gaps made by the method. Returns the layer.]]
function layer:Offset(offset_x, offset_y, fill)
	return mdl_planes.Layers.Offset(self, offset_x, offset_y, fill)
end

-- Returns a resized layer. 3rd argument is optional - it's the tile that will fill any gaps made by the method.
function layer:ResizeToNew(w, h, fill)
	return mdl_planes.Layers.ResizeToNew(self, w, h, fill)
end

--[[ Returns a new layer that is a resized merger of the two layers. The second layer will be placed on top of the first layer.
2rd argument is optional - it's the tile that will fill any gaps made by the method.]]
function layer:MergeToNew(second_layer, fill)
	return mdl_planes.Layers.MergeToNew(self, second_layer, fill)
end

-- Merges the layer with another layer without resizing. The second layer will be placed on top of the first layer. Returns the layer.
function layer:Merge(second_layer)
	return mdl_planes.Layers.Merge(self, second_layer)
end

--[[ General iterator method. Takes a function as an argument and calls it for each tile in the layer. The content of the layer will
be changed based on the return value. For each tile, the additional parameters in a table are passed as argument to the function. 
This table contains the following fields:
	LayerTile - the current tile on the layer,
	LayerX - X coordinate on the layer,
	LayerY - Y coordinate on the layer,
	PlaneTile - the tile on the plane,
	PlaneX - X coordinate on the plane,
	PlaneY - Y coordinate on the plane
Example:
	local roca_wall = 12
	local roca_window = 926
	local function createWindows(params)
		if math.floor(20) == 1 and params.PlaneTile == roca_wall then
			return roca_window
		end
	end
	layer:MapContent(createWindows):Place()
Returns the layer.]]
function layer:MapContent(fun, args)
	return mdl_planes.Layers.Map(self, fun, args)
end

-- Fills the layer with a specific tile. Returns the layer.
function layer:Fill(tile)
	return mdl_planes.Layers.Fill(self, tile)
end

--[[ Clears the layer (fills the content with the "wildcard" tile, that doesn't change a tile on the plane when placed).
Returns the layer.]]
function layer:Clear()
	return mdl_planes.Layers.Fill(self, -2)
end

-- Sets the content of the layer. The argument should be a table. Returns the layer.
function layer:SetContent(content)
	return mdl_planes.Layers.SetContent(self, content)
end

-- Returns a copy of the layer's content as a table.
function layer:GetContentCopy()
	return mdl_planes.Layers.GetContentCopy(self)
end

-- Sets the tile on the layer. Returns the layer.
function layer:SetTile(tile, x, y)
	return mdl_planes.Layers.SetTile(self, tile, x, y)
end

--[[ Clears the tile on the layer (sets it as the "wildcard" tile, that doesn't change a tile on the plane when placed). 
Returns the layer.]]
function layer:ClearTile(x, y)
	return mdl_planes.Layers.SetTile(self, -2, x, y)
end

-- Returns the tile from the layer.
function layer:GetTile(x, y)
	return mdl_planes.Layers.GetTile(self, x, y)
end

--[[ Sets the row on the layer - fills it with one tile when the argument is a number, or with a sequence when the argument is a table.
Returns the layer.]]
function layer:SetRow(content, row)
	return mdl_planes.Layers.SetRow(self, content, row)
end

--[[ Sets the column on the layer - fills it with one tile when the argument is a number, or with a sequence when the argument is a 
table. Returns the layer.]]
function layer:SetColumn(content, column)
	return mdl_planes.Layers.SetColumn(self, content, column)
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Other ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

-- Returns true if the given key-value table contains the given value, otherwise false.
function table.contain(tab,val)
	return mdl_gen.TableContains(tab, val)
end

-- Returns true if the given indexed table contains the given value, otherwise false.
function table.icontain(tab,val)
	return mdl_gen.ITableContains(tab, val)
end

-- Returns key such that table[key] == value.
function table.key(tab, value)
	return mdl_gen.GetTableKey(tab, value)
end

-- Returns index such that table[index] == value.
function table.index(tab, value)
	return mdl_gen.GetITableKey(tab, value)
end

-- Clears table:
function table.clear(tab)
	mdl_gen.ClearTable(tab)
end

-- Returns a number rounded to the nearest integer.
function math.round(n)
	return math.floor(n + 0.5)
end

-- Returns string with escaped magic characters:
function EscapeMagicChars(str)
	return mdl_gen.EscapeMagicChars(str)
end

-- Returns path to the main folder.
function GetClawPath()
	return mdl_cmap.GetClawPath()
end

-- Returns null-terminated C-style string from Lua string.
function GetASCIIZ(str)
	return mdl_gen.GetCStr(str)
end

-- Simple message box. Useful for debugging.
function MessageBox(text, title)
	ffi.C.MessageBoxA(nil, tostring(text), title or "", 0)
end

-- Loads a module using require, but returns nil if not successful, instead of throwing an error.
function SafeRequire(moduleName)
	return mdl_gen.SafeRequire(moduleName)
end

-- Activates the MPTEXT. Change the displayed text by changing the debug_text table.
function ActivateDebugText()
	if InfosDisplay[0].DebugText == false then ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPTEXT, 0) end
end

-- Returns true if the directory exists, otherwise false.
function DirExists(filepath)
	return lfs.attributes(filepath, "mode") == "directory"
end

-- Returns true if the file exists, otherwise false.
function FileExists(filepath)
	return lfs.attributes(filepath, "mode") == "file"
end

-- Returns the file size, in bytes.
function GetFileSize(filepath)
    return lfs.attributes(filepath, "size")
end

-- Returns the plugin by name.
function GetPlugin(name)
	return mdl_plugins.Table[name]
end

-- Exits the level.
function ExitLevel()
	ffi.C.PostMessageA(nRes(1,1), 0x111, _message.ExitLevel, 0)
end

-- Binary OR
OR  = bit.bor

-- Binary AND
AND = bit.band

-- Binary NOT
NOT = bit.bnot

-- Binary XOR
XOR = bit.bxor

-- Returns hexadecimal representation of a number as string.
HEX = bit.tohex

-- Private casting and private copy casting - use below functions to modify game's machinecode for your custom level's sake.
-- Any change made will be automatically reversed in the main menu or on the start of a next level.

PrivateCast = mdl_privc.PrivateCast -- works similarly to ffi.cast (value, ctype, address[, index])

PrivateCopyCast = mdl_privc.PrivateCopyCast -- (string, address[, (bool)force])

PrivateChamAdd = mdl_privc.PrivateChamAdd -- (address, bytestream)

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[[[ Executive part ]]]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

mdl_exe.SkipTitleScreen[0] = mdl_exe._GetValueFromRegister(nRes(14), "Skip Title Screen", 0)
mdl_exe.SkipLogoMovies[0] = mdl_exe._GetValueFromRegister(nRes(14), "Skip Logo Movies", 0)
mdl_cmd.Execute()
mdl_plugins.Load()
mdl_logics.LoadFolder("Assets\\GAME\\LOGICS", true)
