local savePointState = mdl_exe.CSavePoint

local _tab, _str = table, string
local concat, match, find, gmatch = _tab.concat, _str.match, _str.find, _str.gmatch

local CSFILE = require"game_csaves.csaves_file"

CSSTR = {}

CSSTR.GetEntryValues = function(data, n)
    local t = {}
    local i = 1
	local strToMatch = concat{
		'saves%["',
		EscapeMagicChars(GetLevelName()),
		'"%]%[',
		n,
		'%] = {(.-)}'
	}
    local vals = match(data, strToMatch)
    for val in gmatch(vals, "%d+") do
        t[i] = tonumber(val)
        i = i + 1
    end
    return t
end

CSSTR.CreateSaveEntry = function()
	local values = {
		GetClaw().Score,
		GetClaw().Health,
		GetClaw().X,
		GetClaw().Y,
		PData().PistolAmmo,
		PData().MagicAmmo,
		PData().DynamiteAmmo,
		PData().Lives,
		PData().CollectedCoin,
		PData().CollectedGoldbar,
		PData().CollectedRing,
		PData().CollectedChalice,
		PData().CollectedCross,
		PData().CollectedScepter,
		PData().CollectedGecko,
		PData().CollectedCrown,
		PData().CollectedSkull
	}
    local level = GetLevelName()
	return concat{
		'saves["',
		level,
		'"][',
		savePointState[0],
		'] = {',
		concat(values, ","),
		",",
		CSFILE.GetSaveSum(level, values),
		"}"
	}
end

CSSTR.FirstSaveFileContent = function(entry)
	return concat{
		'saves = {}\n',
		entry,
		'\nreturn saves'
	}
end

CSSTR.NewSaveFileContent = function(fileContent, entry)
	local savesReturn = "\nreturn saves"
	local returnIndex = find(fileContent, savesReturn, 1, true)
	return concat{
		fileContent:sub(1, returnIndex),
		entry,
		savesReturn
	}
end

return CSSTR