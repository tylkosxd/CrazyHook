local pals = {}

local function _GetPalPath(filename)
	return GetMapName():match'^(.*)%.' .."\\PALETTES\\"..filename
end

local function _SetLimit(min, max)
	min = tonumber(min)
	max = tonumber(max)
    if not min or min < 0 then min = 0
        elseif min > 255 then min = 255 end
    if not max or max > 255 then max = 255
        elseif max < 0 then max = 0 end
    return min, max
end

pals.RGB_HSL = function(color)
    local R, G, B = color.Red/255, color.Green/255, color.Blue/255
    local m, M = math.min(R, G, B), math.max(R, G, B)
    local C, H = M-m, 0
    if C == 0 then
        H = 0
    elseif R == M then
        H = ((G-B)/C)
        if H < 0 then
            H = H + 6
        end
    elseif G == M then
        H = ((B-R)/C) + 2
    elseif B == M then
        H = ((R-G)/C) + 4
    end
    H = H*60
    local S = 0
    if M > 0 then S = C/M end
    local L = (M+m)/2
    return H, S, L
end

local function hueToRGB(p, q, t)
    local ret = 0
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then
        ret = p + (q - p)*6*t
    elseif t < 1/2 then
        ret =  q
    elseif t < 2/3 then
        ret = p + (q - p)*(2/3 - t)*6
    else
        ret = p
    end
    return math.min(255*ret)
end

pals.HSL_RGB = function(H, S, L)
    local color = ffi.new("CColor")
    if S == 0 then
        color = {math.min(L*255), math.min(L*255), math.min(L*255)}
    else
        local q;
        if L < 0.5 then
            q = L*(1 + S)
        else
            q = L + S - L*S
        end 
        local p = 2*L - q
        color.Red = hueToRGB(p, q, H + 1/3)
        color.Green = hueToRGB(p, q, H)
        color.Blue = hueToRGB(p, q, H - 1/3)
    end
    return color
end

pals.LoadPalette = function(filename, pal)
	if not filename:match"^(%a:)" then
		filename = _mappath .. "\\PALETTES\\" .. filename
	end
	if not pal then
		pal = ffi.new("CPalette")
	else
		pal = ffi.cast("CPalette*", pal)[0]
	end
	if _FileExists(filename) then
        local fileExt = filename:upper():sub(-3)
		-- binary PAL or ACT file:
        if fileExt == "PAL" or fileExt == "ACT" then
		    local input = assert(io.open(filename, "rb"))
		    local data = input:read("*all")
			input:close()
		    for i = 0, 255 do
		    	pal[i].Red = string.byte(data, i*3+1)
		    	pal[i].Green = string.byte(data, i*3+2)
		    	pal[i].Blue = string.byte(data, i*3+3)
		    end
        else -- text file (one color per line in format #RRGGBB):
            local input = assert(io.open(filename, "r"))
            for i = 0, 255 do
                local colorHtml = input:read() -- reads one line per call by default
                if not colorHtml then break end
                pal[i] = colorHtml
            end
            input:close()
        end
		return pal
	else
		error("No file found")
	end 
end

pals.Copy = function(dst, src)
	dst, src = ffi.cast("int*", dst), ffi.cast("int*", src)
	for x = 0, 255 do
        dst[x] = src[x]
    end
end

pals.Invert = function(pal)
    for x = 0,255 do
        pal[x].Red = 255 - pal[x].Red
        pal[x].Green = 255 - pal[x].Green
        pal[x].Blue = 255 - pal[x].Blue
    end
end

pals.AdjustRGB = function(pal,r,g,b,min,max)
    min, max = _SetLimit(min, max)
    for x = min, max do
        pal[x].Red = _SetLimit(pal[x].Red + r)
        pal[x].Green = _SetLimit(pal[x].Green + g)
        pal[x].Blue = _SetLimit(pal[x].Blue + b)
    end
end

pals.AdjustHSL = function(pal,h,s,l,min,max)
    min, max = _SetLimit(min, max)
    for x = min, max do
        local H, S, L = pals.RGB_HSL(pal[x])
        H = ((H + h) % 360)/360
        S = math.max(math.min(1, S+s/100), 0)
        L = math.max(math.min(1, L+l/100), 0)
        pal[x] = pals.HSL_RGB(H, S, L)
    end
end

pals.BlackAndWhite = function(pal, min, max) -- MPGLOOMY effect
	min, max = _SetLimit(min, max)
    for x = min, max do
        pal[x].Red = math.floor(pal[x].Red*0.3 + pal[x].Green*0.59 + pal[x].Blue*0.11)
        pal[x].Green = pal[x].Red
        pal[x].Blue = pal[x].Red
    end
end

pals.ExportToFile = function(pal, filename)
	if not filename then
		filename = GetClawPath() .. "\\pal_export_" ..os.time() ..".PAL"
	end
	local bytes = ""
	for x = 0, 255 do
		bytes = bytes .. string.char(pal[x].Red, pal[x].Green, pal[x].Blue)
	end
	local output = assert(io.open(filename, "wb"))
	output:write(bytes)
	output:close()
end

pals.LoadCLT = function(filename, clt_ptr)
	local cltPtr = ffi.cast("unsigned char*", clt_ptr)
    local cltPath = _mappath .. "\\PALETTES\\" .. filename
	if _FileExists(cltPath) then
        local fileExt = filename:upper():sub(-3)
        -- original CLT binary file:
        if fileExt == "CLT" then
		    local input = assert(io.open(cltPath, "rb"))
		    local data = input:read("*all")
            input:close()
		    for i = 0, 0xFFFF do
		        cltPtr[i] = string.byte(data, i+5) -- skipping first 4 bytes; indexing in Lua starts with 1
		    end
        else -- text file (one number (palette's index) per line):
            local input = assert(io.open(cltPath, "r"))
            local data = input:read("*all")
            for i = 0, 0xFFFF do
                local colorIndex = input:read() -- reads one line per call by default
                if colorIndex then
                    cltPtr[i] = tonumber(colorIndex)
                end
            end
			input:close()
        end
	else
		error("No file found")
    end
end

-- Creating CLT files for the custom palette:

-- Convert RGB to CIELUV:
local function RGB_LUV(ref, col)
	local luv = {L = 0, u = 0, v = 0}
	if col.Red ~= 0 or col.Green ~= 0 or col.Blue ~= 0 then
		-- calculate lightness:
		do
			local epsilon = 0.008856
			local kappa = 903.3
			local yr = col.Green/ref.Green
			if yr > epsilon then
				luv.L = 116*(yr^(1/3)) - 16
			else
				luv.L = kappa * yr
			end
		end
		-- calculate u chromaticity:
		do
			local up = 4 * col.Red / (col.Red + 15*col.Green + 3*col.Blue)
			local urp = 4 * ref.Red / (ref.Red + 15*ref.Green + 3*ref.Blue)
			luv.u = 13 * luv.L * (up - urp)
		end
		-- calculate v chromaticity:
		do
			local vp = 9 * col.Green / (col.Red + 15*col.Green + 3*col.Blue)
			local vrp = 9 * ref.Green / (ref.Red + 15*ref.Green + 3*ref.Blue)
			luv.v = 13 * luv.L * (vp - vrp)
		end
	end
	return luv
end

local function GetPalLUV(pal)
	local pal_luv = {}
	for x = 0, 255 do
		pal_luv[x] = RGB_LUV(pal[255], pal[x])
	end
	return pal_luv
end

-- function for LIGHT (not the same as in game, but IMO good enough):
local function CalcLIGHT(color, dummy_arg, index)
	local light = function(cp, i)
		return math.min(math.round(cp+(i+32)/4), 255)
	end
	return ffi.new("CColor", {light(color.Red, index), light(color.Green, index), light(color.Blue, index)})
end

-- function for AVERAGE (this too isn't the same as in game, but I think similar enough):
local function CalcAVERAGE(color1, color2, dummy_arg)
	local average = function(c1, c2)
		return math.round(math.sqrt((c1*c1+c2*c2*0.5)/1.5))
	end
	return ffi.new("CColor", {average(color1.Red, color2.Red), average(color1.Green, color2.Green), average(color1.Blue, color2.Blue)} )
end

-- find the most similar color (get the color with the smallest difference):
local function MatchColorToPal(luv_color, luv_pal)
	local diff = {}
	-- square of euclidean distance:
	for x = 0, 255 do
		diff[x] = math.pow(luv_color.L - luv_pal[x].L , 2) + math.pow(luv_color.u - luv_pal[x].u , 2) + math.pow(luv_color.v - luv_pal[x].v , 2)
	end
	return table.key(diff, math.min(unpack(diff)))
end

pals.CreateCltFile = function(pal, fun, filename)
	if not filename then
		filename = GetClawPath() .. "\\clt_new_" ..os.time() ..".CLT"
	end
	local bytes = string.char(0, 0, 1, 0)
	local result, color, color_luv
	local pal_luv = GetPalLUV(pal)
	for n = 0, 255 do
		for m = 0, 255 do
			color = fun(pal[n], pal[m], m)
			color_luv = RGB_LUV(pal[255], color)
			result = MatchColorToPal(color_luv, pal_luv)
			bytes = bytes .. string.char(result)
		end
	end
	local output = assert(io.open(filename, "wb"))
	output:write(bytes)
	output:close()
end

pals.CreateLightCltFile = function(pal, filename)
	pals.CreateCltFile(pal, CalcLIGHT, filename)
end

pals.CreateAverageCltFile = function(pal, filename)
	pals.CreateCltFile(pal, CalcAVERAGE, filename)
end

return pals