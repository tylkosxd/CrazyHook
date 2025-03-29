--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ Palettes module ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local PALS = require'custom_palettes.palettes_clts'
local COLORS = require'custom_palettes.palettes_colors'

ffi.cdef[[
    typedef struct CColor {
        uint8_t Red;
        uint8_t Green;
        uint8_t Blue;
        uint8_t Alpha;
    } CColor;

    typedef struct CPalette {
        struct CColor Color[256];
    } CPalette;
]]

PALS.Methods = {}

ffi.metatype("CColor", {
    __tostring = function(self)
        return table.concat{"#", HEX(self.Red, 2), HEX(self.Green, 2), HEX(self.Blue, 2)}
    end,
    __eq = function(self, other)
        if type(other) == "string" then
            return tostring(self) == other:lower()
        end
    end
})

ffi.metatype("CPalette", {
    __index = function(self, key)
        if type(key) == "number" and key >= 0 and key < 256 then
            return self.Color[key]
        end
        if PALS.Methods[key] then
            return PALS.Methods[key]
        end
    end,
    __newindex = function(self, key, val)
        if type(key) == "number" and key >= 0 and key < 256 then
            if type(val) == "string" then
                local hex = assert(val:match"(#%x%x%x%x%x%x)", "CPalette __newindex - could not match color to the hex format")
                self.Color[key].Red = tonumber(hex:sub(2, 3), 16)
                self.Color[key].Green = tonumber(hex:sub(4, 5), 16)
                self.Color[key].Blue = tonumber(hex:sub(6, 7), 16)
                return
            elseif type(val) == "table" then
                self.Color[key].Red = val[1] or val["Red"] or self.Color[key].Red
                self.Color[key].Green = val[2] or val["Green"] or self.Color[key].Green
                self.Color[key].Blue = val[3] or val["Blue"] or self.Color[key].Blue
                self.Color[key].Alpha = val[4] or val["Alpha"] or self.Color[key].Alpha
                return
            elseif ffi.istype("CColor", val) then
                self.Color[key].Red = val.Red or self.Color[key].Red
                self.Color[key].Green = val.Green or self.Color[key].Green
                self.Color[key].Blue = val.Blue or self.Color[key].Blue
                self.Color[key].Alpha = val.Alpha or self.Color[key].Alpha
                return
            end
        end
        error("CPalette __newindex")
    end
})

local function clampToByte(min, max)
	min = math.min(255, math.max(0, tonumber(min) or 0))
	max = math.max(0, math.min(255, tonumber(max) or 255))
    return min, max
end

local function formatChannelName(ch)
    if type(ch) ~= "string" then return end
    ch = ch:lower()
    if ch == "red" then
        return "Red"
    elseif ch == "green" then
        return "Green"
    elseif ch == "blue" then
        return "Blue"
    end
    return nil
end

PALS.LoadPalette = function(filename, pal)
    if type(filename) ~= "string" then
        MessageBox"LoadPalette - invalid first argument (path to the file)."
        return
    end
	if not filename:match"^(%a:)" then -- gets full path if relative is given
		filename = GetMapFolder() .. "\\PALETTES\\" .. filename
	end
    if not FileExists(filename) then
        MessageBox("LoadPalette - no file named " .. filename .. " found.")
        return
    end
	pal = not pal and ffi.new"CPalette" or ffi.cast("CPalette*", pal)[0]
    local fileExt = filename:upper():sub(-4)
    -- binary PAL or ACT file:
    if fileExt == ".PAL" or fileExt == ".ACT" then
        local input = assert(io.open(filename, "rb"))
        local data = input:read("*all")
        input:close()
        for i = 0, 255 do
            pal[i].Red = string.byte(data, i*3+1)
            pal[i].Green = string.byte(data, i*3+2)
            pal[i].Blue = string.byte(data, i*3+3)
        end
    elseif fileExt == ".TXT" then -- text file with one color per line in format #RRGGBB:
        local input = assert(io.open(filename, "r"))
        for i = 0, 255 do
            local colorHex = input:read() -- it reads one line per call by default
            if not colorHex or not colorHex:match("#%x%x%x%x%x%x") then break end
            pal[i] = colorHex
        end
        input:close()
    else
        MessageBox("LoadPalette - file ".. filename .. " is not a valid palette file nor text file.")
    end
    return pal
end

PALS.Copy = function(dst, src)
	dst, src = ffi.cast("int*", dst), ffi.cast("int*", src)
	for x = 0, 255 do
        dst[x] = src[x]
    end
end

PALS.CopyToNew = function(src)
    local new = ffi.new"CPalette"
	PALS.Copy(new, src)
    return new
end

PALS.SetColor = function(pal, index, set)
    if type(index) ~= "number" then return pal end
    index = index < 0 and 0 or index > 255 and 255 or index
    pal[index] = set
    return pal
end

PALS.GetColor = function(pal, index)
    if type(index) ~= "number" then return pal end
    index = index < 0 and 0 or index > 255 and 255 or index
    return pal[index]
end

PALS.Invert = function(pal, min, max)
    min, max = clampToByte(min, max)
    for x = min, max do
        pal[x].Red = 255 - pal[x].Red
        pal[x].Green = 255 - pal[x].Green
        pal[x].Blue = 255 - pal[x].Blue
    end
    return pal
end

PALS.InvertChannel = function(pal, ch, min, max)
    min, max = clampToByte(min, max)
    ch = formatChannelName(ch)
    if not ch then
        MessageBox"palette:InvertChannel - wrong channel name. Use 'Red', 'Green' or 'Blue'."
        return pal
    end
    for x = min, max do
        pal[x][ch] = 255 - pal[x][ch]
    end
    return pal
end

PALS.AdjustRGB = function(pal, r, g, b, min, max)
    min, max = clampToByte(min, max)
    for x = min, max do
        pal[x].Red = clampToByte(pal[x].Red + r)
        pal[x].Green = clampToByte(pal[x].Green + g)
        pal[x].Blue = clampToByte(pal[x].Blue + b)
    end
    return pal
end

PALS.AdjustHSL = function(pal, h, s, l, min, max)
    min, max = clampToByte(min, max)
    for x = min, max do
        local H, S, L = COLORS.RgbToHsl(pal[x])
        H = ((H + h) % 360)/360
        S = math.max(math.min(1, S+s/100), 0)
        L = math.max(math.min(1, L+l/100), 0)
        pal[x] = COLORS.HslToRgb(H, S, L)
    end
    return pal
end

PALS.BlackAndWhite = function(pal, min, max)
	min, max = clampToByte(min, max)
    for x = min, max do
        pal[x].Red = clampToByte(pal[x].Red*0.3 + pal[x].Green*0.59 + pal[x].Blue*0.11)
        pal[x].Green = pal[x].Red
        pal[x].Blue = pal[x].Red
    end
    return pal
end

PALS.SwapChannels = function(pal, ch1, ch2, min, max)
    min, max = clampToByte(min, max)
    ch1, ch2 = formatChannelName(ch1), formatChannelName(ch2)
    if not ch1 or not ch2 then
        MessageBox"palette:SwapChannels - wrong channel name. Use 'Red', 'Green' or 'Blue'."
        return pal
    end
    local temp;
    for x = min, max do
        temp = pal[x][ch1]
        pal[x][ch1] = pal[x][ch2]
        pal[x][ch2] = temp
    end
    return pal
end

PALS.ExportToFile = function(pal, filename)
	if not filename then
		filename = GetLevelName() .. " - pal export " ..os.time() ..".PAL"
	end
    if type(filename) ~= "string" then
        MessageBox"Palette:ExportToFile - invalid second argument (path to the file)."
        return
    end
	if not filename:match"^(%a:)" then -- gets full path if relative is given
		filename = GetClawPath() .. "\\" .. filename
	end
	local bytes = ""
	for x = 0, 255 do
		bytes = bytes .. string.char(pal[x].Red, pal[x].Green, pal[x].Blue)
	end
	local output = assert(io.open(filename, "wb"))
	output:write(bytes)
	output:close()
    return pal
end

return PALS