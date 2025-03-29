local CSFILE = {}

local function GetCustomSavePath()
    return GetClawPath() .. "\\CustomSaves.lua"
end

CSFILE.GetSaveSum = function(level, t)
	local sum = t[1]*1.16 + t[2]*2.4 + t[3]*0.73 + t[4]*0.48 - t[5]*t[6]*0.5 - t[7]*t[8] - t[9]*0.6 - t[10]*0.79 - t[11]*1.25 -
	t[12]*0.84 - t[13]*t[14]*0.07 - t[15]*t[16]*0.14 - t[17]*3.12 + 788529152
	local cstr = GetASCIIZ(level)
	return math.floor(cstr[0]*cstr[#level-1] + sum*cstr[0]/50)
end

CSFILE.GetCompletionSum = function(level, gathered, total)
	local cstr = GetASCIIZ(level)
	return gathered*cstr[0] + total*cstr[#level-1] + cstr[0]*cstr[0] + 729
end

CSFILE.ReadSaveFile = function()
	local file = assert(io.open(GetCustomSavePath(), "r"))
	local data = file:read("*all")
	file:close()
	return data
end

CSFILE.WriteSaveFile = function(content)
	local file = assert(io.open(GetCustomSavePath(), "w"))
	file:write(content)
	file:close()
end

CSFILE.SaveFileExists = function()
	return lfs.attributes(GetCustomSavePath(), "mode") == "file"
end

return CSFILE