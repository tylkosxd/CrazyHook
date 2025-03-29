-- This module handles the colors transformations.

local COLORS = {}

COLORS.RgbToHsl = function(color)
    local R, G, B = color.Red/255, color.Green/255, color.Blue/255
    local minimum, maximum = math.min(R, G, B), math.max(R, G, B)
    local chroma = maximum-minimum
	local hue = chroma==0 and 0 or R==maximum and (G-B)/chroma or G==maximum and (B-R)/chroma+2 or B==maximum and (R-G)/chroma+4
	hue = hue < 0 and (hue + 6)*60 or hue*60
    local saturation = maximum == 0 and 0 or chroma/maximum
    local lightness = (maximum+minimum)/2
    return hue, saturation, lightness
end

COLORS.HueToRGB = function(p, q, t)
    local ret = 0
    t = t < 0 and t + 1 or t > 1 and t - 1 or t
    if t < 1/6 then
        ret = p + (q - p)*6*t
    elseif t < 1/2 then
        ret =  q
    elseif t < 2/3 then
        ret = p + (q - p)*(2/3 - t)*6
    else
        ret = p
    end
    ret = 255*ret
    return ret < 0 and 0 or ret > 255 and 255 or ret
end

COLORS.HslToRgb = function(H, S, L)
    if S == 0 then
        local ch = math.min(L*255, 255)
        return ffi.new("CColor", {ch, ch, ch})
    else
        local q = L < 0.5 and L*(1 + S) or L + S - L*S
        local p = 2*L - q
        local color = ffi.new("CColor")
        color.Red = COLORS.HueToRGB(p, q, H + 1/3)
        color.Green = COLORS.HueToRGB(p, q, H)
        color.Blue = COLORS.HueToRGB(p, q, H - 1/3)
        return color
    end
end

local function colorToLinear(color)
    local c
    local result = {}
    local colhack = ffi.new("unsigned char[3]", {color.Red, color.Green, color.Blue})
    for x = 1,3 do
        c = tonumber(colhack[x-1])/255
        if c <= 0.04045 then
            result[x] = c/12.92
        else
            result[x] = ((c + 0.055)/1.055)^2.4
        end
    end
    return result
end

local rgbToXyzMatrix = {
    {0.4124564, 0.3575761, 0.1804375},
    {0.2126729, 0.7151522, 0.0721750},
    {0.0193339, 0.1191920, 0.9503041}
}

COLORS.RgbToXyz = function(rgb)
    local linRgb = colorToLinear(rgb)
    local result = {}
    local matrix = rgbToXyzMatrix
    result.X = matrix[1][1]*linRgb[1] + matrix[1][2]*linRgb[2] + matrix[1][3]*linRgb[3]
    result.Y = matrix[2][1]*linRgb[1] + matrix[2][2]*linRgb[2] + matrix[2][3]*linRgb[3]
    result.Z = matrix[3][1]*linRgb[1] + matrix[3][2]*linRgb[2] + matrix[3][3]*linRgb[3]
    return result
end

local Xn = 0.950489
local Yn = 1.000000
local Zn = 1.088840

COLORS.RgbToLuv = function(col)
    local xyz = COLORS.RgbToXyz(col)
	local luv = {L = 0, u = 0, v = 0}
    if xyz.X == 0 and xyz.Y == 0 and xyz.Z == 0 then return luv end
	-- lightness:
	local y = xyz.Y/Yn
	luv.L = y > 0.008856 and 116 * y^(1/3) - 16 or 903.3*y
	-- u chromaticity:
	local up = 4 * xyz.X / (xyz.X + 15*xyz.Y + 3*xyz.Z)
	local urp = 4 * Xn / (Xn + 15*Yn + 3*Zn)
	luv.u = 13 * luv.L * (up - urp)
	-- v chromaticity:
	local vp = 9 * xyz.Y / (xyz.X + 15*xyz.Y + 3*xyz.Z)
	local vrp = 9 * Yn / (Xn + 15*Yn + 3*Zn)
	luv.v = 13 * luv.L * (vp - vrp)
	return luv
end

COLORS.GetHtmlColor = function(color)
	if not ffi.istype("CColor", color) then
		MessageBox("GetHtmlColor - CColor expected!")
        return
	end
	local red = bit.tohex(color.Red, 2)
	local green = bit.tohex(color.Green, 2)
	local blue = bit.tohex(color.Blue, 2)
	return "#" .. red .. green .. blue
end

return COLORS