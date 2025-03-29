--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Palettes module ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module handles the stuff related to color lookup tables. CLTs are responsible for mitigating the effects of semi-transparency
of graphics in the game.]]

local CLTS = {}
local COLORS = require'custom_palettes.palettes_colors'

local function clampToByte(min, max)
	min = math.max(0, tonumber(min) or 0)
	max = math.min(255, tonumber(max) or 255)
    return min, max
end

CLTS.LoadCLT = function(filename, clt)
    if type(filename) ~= "string" then
        MessageBox"LoadCLT - invalid first argument (path to the file)."
        return
    end
	if not filename:match"^(%a:)" then -- gets full path if relative is given
		filename = GetMapFolder() .. "\\PALETTES\\" .. filename
	end
	local ptrCLT = ffi.cast("unsigned char*", clt)
	if not FileExists(filename) then
		MessageBox"LoadCLT - file not found."
		return
	end
	local fileExt = filename:upper():sub(-4)
	-- original CLT binary file:
	if fileExt == ".CLT" then
		local input = assert(io.open(filename, "rb"))
		local data = input:read("*all")
		input:close()
		for i = 0, 0xFFFF do
			ptrCLT[i] = string.byte(data, i+5) -- skipping first 4 bytes + indexing in Lua starts with 1
		end
	elseif fileExt == ".TXT" then -- text file (one number in range 0-255 per line):
		local input = assert(io.open(filename, "r"))
		for i = 0, 0xFFFF do
			local colorIndex = tonumber(input:read()) -- reads one line per call by default
			if not colorIndex then return end
			ptrCLT[i] = clampToByte(colorIndex)
		end
		input:close()
	else
		MessageBox("LoadCLT - provided file is not a valid CLT file nor a text file.")
	end
end

local function GetPalLUV(pal)
	local palLuv = {}
	for i = 0, 255 do
		table.insert(palLuv, COLORS.RgbToLuv(pal[i]))
	end
	return palLuv
end

local calcChannelLIGHT = function(cp, i)
	return math.min(math.round(cp+(i+32)/4), 255) -- values 32 and 4 came from testing, you can probably find better ones
end

local calcChannelAVERAGE = function(c1, c2)
	return math.round(math.sqrt((c1*c1+c2*c2*0.5)/1.5)) -- values 0.5 and 1.5 came from testing, you can probably find better ones
end

-- function for LIGHT (not the same as in game, but IMO good enough):
local function calcLIGHT(color, dummy, index)
	local r = calcChannelLIGHT(color.Red, index)
	local g = calcChannelLIGHT(color.Green, index)
	local b = calcChannelLIGHT(color.Blue, index)
	return ffi.new("CColor", {r, g, b})
end

-- function for AVERAGE (this too isn't the same as in game, but I think similar enough):
local function calcAVERAGE(color1, color2, dummy)
	local r = calcChannelAVERAGE(color1.Red, color2.Red)
	local g = calcChannelAVERAGE(color1.Green, color2.Green)
	local b = calcChannelAVERAGE(color1.Blue, color2.Blue)
	return ffi.new("CColor", {r, g, b})
end

local function getMostSimilarLuvColor(c, luvPal)
	local diffs = {}
	local dist, cp
	for i = 2, 256 do -- skipping the index 0, which works as transparency
		cp = luvPal[i]
		dist = (c.L - cp.L)^2 + (c.u - cp.u)^2 + (c.v - cp.v)^2 -- square of euclidean distance
		if dist == 0 then return i - 1 end
		table.insert(diffs, i - 1, dist)
	end
	local min = math.min(unpack(diffs))
	for i, v in ipairs(diffs) do
		if v == min then
			return i
		end
	end
end

CLTS.CreateCltFile = function(pal, fun)
	if type(fun) == "number" then
		fun = fun == 0 and calcLIGHT or fun == 1 and calcAVERAGE
	end
	if type(fun) ~= "function" then
		MessageBox("CreateCltFile - no function given")
		return
	end
	local cltType = fun == calcLIGHT and "_LIGHT" or fun == calcAVERAGE and "_AVERAGE" or "_CUSTOM"
	local filename = GetLevelName() .. "_" .. os.time() .. cltType ..".CLT"
	MessageBox("Generating the color lookup table should take a few seconds... press enter to continue")
	local bytes = string.char(0, 0, 1, 0) -- as 0x10000 - length of clt array
	local result, color, colorLuv
	local palLuv = GetPalLUV(pal)
	for n = 0, 255 do
		for m = 0, 255 do
			color = fun(pal[n], pal[m], m)
			colorLuv = COLORS.RgbToLuv(color)
			result = getMostSimilarLuvColor(colorLuv, palLuv)
			bytes = bytes .. string.char(result)
		end
	end
	local output = assert(io.open(filename, "wb"))
	output:write(bytes)
	output:close()
	MessageBox("The CLT file has been successfully created!")
end

return CLTS