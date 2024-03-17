local mdl_exev = require 'mods.chExeVars'

local _cl = { }

local _GetArgv = function(str)
	local argv = {}
    local quote = false
    local start
    for i = 0, #str do
        local c = str:sub(i, i)
        if c == " " and not quote then
            if start then
                table.insert(argv, str:sub(start, i - 1))
            end
            start = nil
        else
            if c == "\"" then
                quote = not quote
            end
            start = start or i
        end
    end
    if start then
        table.insert(argv, str:sub(start, #str))
    end
    return argv
end


_cl.Get = function()
	local argvs = _GetArgv(ffi.string(ffi.C.GetCommandLineA()))
	
	local cl_argv = {
		start_x = 0,
		start_y = 0,
		res_w = 0,
		res_h = 0,
		runflags = {},
		retail = 0,
		custom = ""
	}
	
	for _, arg in ipairs(argvs) do
		if arg:match'(.*)CLAW.EXE' then
			rel = arg:match'(.*)CLAW.EXE'
			if rel:sub(1,1) == '"' then 
				rel = rel:sub(2, #rel) 
			end
		elseif arg:match'CL:%b""' then
			cl_argv.custom = arg:sub(5, #arg-1)
		elseif arg:match'CL:' then
			cl_argv.custom = arg:sub(4, #arg)
		elseif arg:match'POS:%b""' then
			local pos = arg:sub(6, #arg-1)
			cl_argv.start_x, cl_argv.start_y = pos:match'(%d*)x(%d*)'
			cl_argv.start_x = tonumber(cl_argv.start_x)
			cl_argv.start_y = tonumber(cl_argv.start_y)
		elseif arg:match'RES:%b""' then
			local res = arg:sub(6, #arg-1)
			cl_argv.res_w, cl_argv.res_h = res:match'(%d*)x(%d*)'
			cl_argv.res_w = tonumber(cl_argv.res_w)
			cl_argv.res_h = tonumber(cl_argv.res_h)
		elseif arg:match'^RL:(%d*)$' then
			cl_argv.retail = tonumber(arg:match'^RL:(%d*)$')
		elseif arg:match'^-(.*)$' then
			local str = arg:match'^-(.*)$'
			str = str.upper(str)
			cl_argv.runflags[str] = 1
		end
	end
	
	if cl_argv.custom ~= "" and not cl_argv.custom:match'^%a:*\\(.*)%.' then 
		cl_argv.custom = rel .. cl_argv.custom 
	end
	
	return cl_argv
end


_cl.Map = function(cl_argv)
	if _chameleon[0] == chamStates.LoadingObjects then
		if GetGameType() == GameType.SinglePlayer then
			if cl_argv.start_x > 0 and cl_argv.start_y > 0 then
				PlayerData().SpawnPointX = cl_argv.start_x
				PlayerData().SpawnPointY = cl_argv.start_y
				GetClaw().State = 23
			end
			if cl_argv.res_w ~= 0 and cl_argv.res_h ~= 0 then 
				ChangeResolution(cl_argv.res_w, cl_argv.res_h) 
			end
			if cl_argv.runflags["GOD"] == 1 then 
				ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8043, 0) 
			end
			if cl_argv.runflags["ARMOR"] == 1 then 
				ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8072, 0) 
			end
			if cl_argv.runflags["NOALIGN"] == 1 then 
				for i=0,6 do 
					ffi.cast("char*",0x417303)[i] = 0x90 
				end 
				snRes(1,18,74) -- cheating set
			end
			if cl_argv.runflags["TIME"] == 1 then 
				InfosDisplayState[0] = OR(InfosDisplayState[0], InfosFlags.Watch)
			end
			if cl_argv.runflags["FPS"] == 1 then 
				InfosDisplayState[0] = OR(InfosDisplayState[0], InfosFlags.FPS)
			end
			if cl_argv.runflags["DEBUGINFOS"] == 1 then 
				InfosDisplayState[0] = OR(InfosDisplayState[0], InfosFlags.Watch)
				InfosDisplayState[0] = OR(InfosDisplayState[0], InfosFlags.FPS)
				InfosDisplayState[0] = OR(InfosDisplayState[0], InfosFlags.Pos)
				InfosDisplayState[0] = OR(InfosDisplayState[0], InfosFlags.Objects)
			end
		end
		
	elseif _chameleon[0] == chamStates.OnPostMessageA then
		local id = tonumber(ffi.cast("int",ptr))
		if id == 665 then -- noper reset
			local noper = ffi.cast("char*",0x42C760)
			noper[0] = 0x81
			noper[1] = 0x79
		elseif id == 670 then
			if cl_argv.res_w ~= 0 and cl_argv.res_h ~= 0 then 
				if nRes(31) ~= cl_argv.res_w or nRes(32) ~= cl_argv.res_h then
					ChangeResolution(cl_argv.res_w, cl_argv.res_h) 
				end
			end
		elseif id==0x8036 then
			ffi.C.PostMessageA(nRes(1,1), 0x111, 670, 0)
		end
	end	
end


_cl.Execute = function(cl_argv)
	if cl_argv.custom ~= "" or (cl_argv.retail > 0 and cl_argv.retail < 15) then
		mdl_exev.SkipTitleScreen[0] = 1
		mdl_exev.SkipLogoMovies[0] = 1
		mdl_exev.TestExit[0] = 1
		mdl_exev.NoEffects[0] = 1
		mdl_exev.IntroSound[0] = 0
		snRes(1,18,74) -- cheating set
		if cl_argv.custom ~= "" then
			snRes(ffi.cast("int", cl_argv.custom), 49)
		else
			ffi.cast("char*", 0x427D69)[1] = cl_argv.retail
		end
		if cl_argv.res_w ~= 0 and cl_argv.res_h ~= 0 then
			local noper = ffi.cast("char*", 0x42C760)
			noper[0] = 0xEB
			noper[1] = 0x13
		end
		ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8005, 0) --RunGame
		ffi.C.PostMessageA(nRes(1,1), 0x111, 665, 0) -- noper reset
	else
		cl_argv.start_x = 0
		cl_argv.start_y = 0
		cl_argv.res_x = 0
		cl_argv.res_y = 0
	end
end

return _cl
