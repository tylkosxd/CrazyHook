local _cmdDoOnlyOnce = false
local CMD = { }

CMD.Get = function()
	local argv = ffi.string(ffi.C.GetCommandLineA())
    local rel = ""
	local argvs = {
        retail = 0,
        custom = "",
        start_x = 0,
        start_y = 0,
        res_w = 0,
        res_h = 0,
        runflags = {}
    }
    -- get retail:
	argvs.retail = tonumber(argv:match'RL:(%d+)') or 0
    -- get custom level:
    if argv:match'(%sCL:)' then
        argvs.custom = argv:match'CL:%b""':sub(5,-2) or argv:match'CL:(%S+)'
    end
    -- get starting position:
	if argv:match'(%sPOS:)' then
        local pos = argv:match'POS:%b""'
	    argvs.start_x, argvs.start_y = pos:sub(6,-2):match'(%d+)x(%d+)'
        argvs.start_x = tonumber(argvs.start_x)
        argvs.start_y = tonumber(argvs.start_y)
    end
    -- get resolution:
	if argv:match'(%sRES:)' then
        local res = argv:match'RES:%b""'
		argvs.res_w, argvs.res_h = res:sub(6,-2):match'(%d+)x(%d+)'
		argvs.res_w = tonumber(argvs.res_w)
		argvs.res_h = tonumber(argvs.res_h)
    end
    -- get runflags:
    local rever = argv:reverse()
    local last = rever:find"[%s\"]%d[%d:]" or rever:upper():find"[%s\"]DWW%." or rever:upper():find"[%s\"]EXE%."
    if last then
        local runflags = argv:sub(-last, -1)
	    for flag in string.gmatch(runflags, "%-(%a+)") do
            argvs.runflags[flag:upper()] = 1
        end
    end
    -- get full path to custom level, if relative is given:
	if argvs.custom ~= "" and not argvs.custom:match"^(%a:)" and not argvs.custom:match"^(\"%a:)" then
		argvs.custom = ExePath .. "\\" .. argvs.custom 
	end
	
	return argvs
end


CMD.Map = function(argvs)
	if _chameleon[0] == chamStates.LoadingStart then
		_cmdDoOnlyOnce = false
	end
	if _chameleon[0] == chamStates.LoadingObjects then
		if GetGameType() == GameType.SinglePlayer and not _cmdDoOnlyOnce then
			if argvs.start_x > 0 and argvs.start_y > 0 then
				PlayerData().SpawnPointX = argvs.start_x
				PlayerData().SpawnPointY = argvs.start_y
				GetClaw().State = 23
                snRes(1,18,74)
                LoopThroughObjects()
			end
			if argvs.res_w ~= 0 and argvs.res_h ~= 0 then 
                if nRes(31) ~= argvs.res_w or nRes(32) ~= argvs.res_h then
					ChangeResolution(argvs.res_w, argvs.res_h) 
				end
                snRes(1,18,74)
			end
			if argvs.runflags["NOALIGN"] == 1 then 
				for i=0,6 do 
					ffi.cast("char*",0x417303)[i] = 0x90 
				end 
				snRes(1,18,74)
			end
			if argvs.runflags["TIME"] == 1 then 
				InfosDisplay[0].Watch = true
			end
			if argvs.runflags["FPS"] == 1 then 
				InfosDisplay[0].FPS = true
			end
			if argvs.runflags["DEBUGINFOS"] == 1 then 
				InfosDisplay[0].Watch = true
				InfosDisplay[0].FPS = true
				InfosDisplay[0].Pos = true
				InfosDisplay[0].Objects = true
			end
			if argvs.runflags["SPEEDRUN"] == 1 then
				InfosDisplay[0].LiveClock = true
				InfosDisplay[0].Watch = true
				InfosDisplay[0].FPS = true
			end 
            _cmdDoOnlyOnce = true
		end
	end
	
	if _chameleon[0] == chamStates.LoadingEnd then
		if GetGameType() == GameType.SinglePlayer then
			if argvs.runflags["GOD"] == 1 then 
				ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8043, 0) 
			end
			if argvs.runflags["ARMOR"] == 1 then 
				ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8072, 0) 
			end
			if argvs.runflags["FLY"] == 1 then 
				ffi.C.PostMessageA(nRes(1,1), 0x111, 668, 0) 
			end
			if argvs.runflags["HD"] == 1 then
				ffi.C.PostMessageA(nRes(1,1), 0x111, 773, 0)
			end
		end
	end
		
	if _chameleon[0] == chamStates.OnPostMessage then
		local id = tonumber(ffi.cast("int",ptr))
		if id == 665 then -- noper reset
			local noper = ffi.cast("char*",0x42C760)
			noper[0] = 0x81
			noper[1] = 0x79
		elseif id == 670 then
			if argvs.res_w ~= 0 and argvs.res_h ~= 0 then 
				if nRes(31) ~= argvs.res_w or nRes(32) ~= argvs.res_h then
					ChangeResolution(argvs.res_w, argvs.res_h) 
				end
			end
		elseif id==0x8036 then
			ffi.C.PostMessageA(nRes(1,1), 0x111, 670, 0)
		end
	end	
end


CMD.Execute = function(argvs)
	if argvs.custom ~= "" or (argvs.retail > 0 and argvs.retail < 15) then
		mdl_exe.SkipTitleScreen[0] = 1
		mdl_exe.SkipLogoMovies[0] = 1
		mdl_exe.TestExit[0] = 1
		mdl_exe.NoEffects[0] = 1
		mdl_exe.IntroSound[0] = 0
		if argvs.custom ~= "" then
			snRes(ffi.cast("int", argvs.custom), 49)
		else
			ffi.cast("char*", 0x427D69)[1] = argvs.retail
		end
		if argvs.res_w ~= 0 and argvs.res_h ~= 0 then
			local noper = ffi.cast("char*", 0x42C760)
			noper[0] = 0xEB
			noper[1] = 0x13
		end
		ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8005, 0) --RunGame
		ffi.C.PostMessageA(nRes(1,1), 0x111, 665, 0) -- noper reset
	else
		argvs.start_x = 0
		argvs.start_y = 0
		argvs.res_w = 0
		argvs.res_h = 0
	end
end

return CMD
