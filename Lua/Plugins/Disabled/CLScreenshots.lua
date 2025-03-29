-- It opens all custom levels one by one and makes a screenshots of them.

local PLUGIN = {}

PLUGIN.menu = function()
	if not PLUGIN.LEVELS then
		PLUGIN.LEVELS = {}
		PLUGIN.TAKEN = {}
		PLUGIN.customDir = GetClawPath() .. "\\Custom\\"
		for filename in lfs.dir(PLUGIN.customDir) do
			if #filename > 4 and filename:sub(-4):upper() == ".WWD" then
				table.insert(PLUGIN.LEVELS, filename)
			end
		end
		local ssdir = GetClawPath().."\\Screenshots"
		if not DirExists(ssdir) then
			lfs.mkdir(ssdir)
		end
		for ss in lfs.dir(GetClawPath().."\\Screenshots") do
			if #ss > 4 and ss:sub(-4):upper() == ".BMP" then
				PLUGIN.TAKEN[ss:sub(1,-5)] = 1
			end
		end
		PLUGIN.counter = 1
	end
	repeat
		PLUGIN.level = PLUGIN.LEVELS[PLUGIN.counter]
		PLUGIN.counter = PLUGIN.counter + 1
	until (PLUGIN.level == nil or PLUGIN.TAKEN[PLUGIN.level:sub(1, -5)] == nil)
	if PLUGIN.level then
		PLUGIN.randTime = math.random(200,400)
		PLUGIN.levelPath = PLUGIN.customDir .. PLUGIN.level
		snRes(ffi.cast("int", PLUGIN.levelPath), 49)
		ffi.C.PostMessageA(nRes(1,1), 0x111, _message.LevelStart, 0)
	end
end

PLUGIN.map = function(ptr)
	local cham = _chameleon[0]
	if cham == chamStates.Gameplay and GetTime() > PLUGIN.randTime and PLUGIN.level then
		MakeScreenshot("Screenshots\\" .. PLUGIN.level:sub(1,-5) .. ".BMP")
		ExitLevel()
	end
end

return PLUGIN