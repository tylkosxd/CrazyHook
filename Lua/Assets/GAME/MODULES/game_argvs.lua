--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Commandline module ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module handles the arguments for running Claw from Windows CLI. The available arguments are:
	RL:[1-14] - will start the game from the retail level (1-14)
	CL:[path_to_custom_level] - will start the game from the custom level
	POS:[X]x[Y] - sets the spawn point of Claw for the given RL or CL, e.g. POS:1000x1000
	RES:[width]x[height] - sets the game resolution
	-NOALIGN - do not align Claw to ground during the spawn/respawn
	-TIME - shows the time counter
	-FPS - shows the fps counter
	-DEBUGINFOS - shows the time counter, fps counter, world position and number of active objects
	-SPEEDRUN - shows the precise time counter
	-GOD - activates the God Mode
	-ARMOR - activates the Anti Death-Tile Mode
	-FLY - activates the Fly mode
	-HD - activates the HD mode
]]

local function setCheatFlag()
	snRes(1,18,74)
end

local function showParsingResults(args)
	local result = {}
	for k, v in pairs(args) do
		if type(v) ~= "table" then
			table.insert(result, k .. " = " .. v)
		else
			table.insert(result, k .. ":")
			for flag, _ in pairs(v) do
				table.insert(result, flag)
			end
			table.insert(result, "")
		end
	end
	ffi.C.MessageBoxA(nil, tostring(table.concat(result, "\n")), "Parsing results", 0)
end

-- get full path to custom level, if relative is given:
local function relPathToFull(path)
	if not path:match"^[A-Za-z]:[\\/]" then
		path =  lfs.currentdir() .. "\\Custom\\" .. path
	end
	if path:sub(-4):upper() ~= ".WWD" then
		path = path .. ".wwd"
	end
	if lfs.attributes(path, "mode") ~= "file" then
		return nil
	end
	return path
end

local function ParseArgs()
	local argv = ffi.string(ffi.C.GetCommandLineA())
	local ARGS = {runflags = {} }
    -- retail:
	ARGS.retail = tonumber(argv:match'RL:(%d+)')
    -- custom level:
    if argv:match'(%sCL:)' then
		local inQu = argv:match'CL:%b""'
        ARGS.custom = inQu and inQu:sub(5,-2) or argv:match'CL:(%S+)'
		ARGS.custom = relPathToFull(ARGS.custom)
    end
    -- starting position:
	local pos = argv:match'POS:%b""'
	if pos then
		ARGS.start_x = tonumber(pos:match'"(%d+)x')
		ARGS.start_y = tonumber(pos:match'x(%d+)"')
    end
    -- resolution:
	local res = argv:match'RES:%b""'
	if res then
		ARGS.res_w = tonumber(res:match'"(%d+)x')
		ARGS.res_h = tonumber(res:match'x(%d+)"')
    end
    --runflags:
	local lastEXE = argv:find('%.[Ww][Ww][Dd][%s"]') or 0
	local lastWWD = argv:find('%.[Ee][Xx][Ee][%s"]')
	local cut = argv:sub(math.max(lastEXE, lastWWD)):upper()
	for flag in string.gmatch(cut, "%s%-(%a+)") do
		ARGS.runflags[flag] = 1
	end
	return ARGS
end

local ARGVS = ParseArgs()

local CMD = {}

CMD.Main = function(ptr)

	local FLAGS = ARGVS.runflags

	if _chameleon[0] == chamStates.LoadingObjects and not CMD.DoOnlyOnce then
		if FLAGS["NOALIGN"] == 1 then
			ffi.cast("short*", 0x417303)[0] = 0x05EB -- jmp 0x41730A
			setCheatFlag()
		end
		if (ARGVS.retail or ARGVS.custom) and ARGVS.start_x and ARGVS.start_y then
			PlayerData().SpawnPointX = ARGVS.start_x
			PlayerData().SpawnPointY = ARGVS.start_y
			GetClaw().State = 23
			setCheatFlag()
			LoopThroughObjects()
		end
		if ARGVS.res_w and ARGVS.res_h then
			if nRes(31) ~= ARGVS.res_w or nRes(32) ~= ARGVS.res_h then
				ChangeResolution(ARGVS.res_w, ARGVS.res_h)
			end
			setCheatFlag()
		end
		if FLAGS["TIME"] == 1 then
			InfosDisplay[0].Watch = true
		end
		if FLAGS["FPS"] == 1 then
			InfosDisplay[0].FPS = true
		end
		if FLAGS["DEBUGINFOS"] == 1 then
			InfosDisplay[0].Watch = true
			InfosDisplay[0].FPS = true
			InfosDisplay[0].Pos = true
			InfosDisplay[0].Objects = true
		end
		if FLAGS["SPEEDRUN"] == 1 then
			InfosDisplay[0].LiveClock = true
			InfosDisplay[0].Watch = true
			InfosDisplay[0].FPS = true
		end
		CMD.DoOnlyOnce = true
	end

	if _chameleon[0] == chamStates.LoadingEnd then
		if FLAGS["GOD"] == 1 then
			ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPKFA, 0)
		end
		if FLAGS["ARMOR"] == 1 then
			ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPARMOR, 0)
		end
		if FLAGS["FLY"] == 1 then
			ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPFLY, 0)
		end
		if FLAGS["HD"] == 1 then
			ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPAZZAR, 0)
		end
		CMD.DoOnlyOnce = nil
		mdl_exe.NoEffects[0] = 0
	end

	if _chameleon[0] == chamStates.OnPostMessage then
		local id = tonumber(ffi.cast("int",ptr))
		local message = _message
		if id == message.ArgvsResNoperReset then -- noper reset
			local noper = ffi.cast("char*",0x42C760)
			noper[0] = 0x81
			noper[1] = 0x79
		end
		if ARGVS.res_w and ARGVS.res_h then
			if id == message.ArgvsChangeRes and nRes(31) ~= ARGVS.res_w or nRes(32) ~= ARGVS.res_h then
				ChangeResolution(ARGVS.res_w, ARGVS.res_h)
			elseif id == message.RunGame then
				ffi.C.PostMessageA(nRes(1,1), 0x111, message.ArgvsChangeRes, 0)
			end
		end
	end
end

CMD.Execute = function()
	if ARGVS.custom or ARGVS.retail then
		mdl_exe.SkipTitleScreen[0] = 1
		mdl_exe.SkipLogoMovies[0] = 1
		mdl_exe.TestExit[0] = 1
		mdl_exe.NoEffects[0] = 1
		mdl_exe.IntroSound[0] = 0
		if ARGVS.custom then
			snRes(ffi.cast("int", ARGVS.custom), 49)
		end
		ffi.cast("char*", 0x427D69)[1] = ARGVS.retail or 0
		if ARGVS.res_w and ARGVS.res_h then
			local noper = ffi.cast("char*", 0x42C760)
			noper[0] = 0xEB -- jmp short
			noper[1] = 0x13
		end
		ffi.C.PostMessageA(nRes(1,1), 0x111, _message.LevelStart, 0)
		ffi.C.PostMessageA(nRes(1,1), 0x111, _message.ArgvsResNoperReset, 0)
	end
end

return CMD
