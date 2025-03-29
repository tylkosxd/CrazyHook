--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- [[ Private Casting module ]] ----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ Private casting allows to modify game's machinecode for the custom level's sake. Do not use if you don't know what you're doing.
Any change made with these functions is reversed when the player exits/finishes the current level. ]]

local PRIV = {}

PRIV.Table = {} -- the original bytes will be stored here.

local function isValidPointerType(ctype)
	return type(ctype) == "string" and ctype:sub(1,4) ~= "void" and ctype:sub(-1) == "*" and ctype:sub(-2) ~= "**"
end

local function isValidAddress(addr)
	return type(addr) == "number" and addr >= 0x401000 and addr < 0x5AF000
end

PRIV.AddToPrivateCastTable = function(addr, index)
	if not PRIV.Table[addr+index] then
        PRIV.Table[addr+index] = ffi.cast("char*", addr)[index]
    end
end

PRIV.PrivateCast = function(value, ctype, addr, index)
    index = index or 0
	-- set many:
	if type(value) == "table" then
		for i, v in ipairs(value) do
			PrivateCast(v, ctype, addr, i+index)
		end
	end
	-- set single:
    if isValidPointerType(ctype) and isValidAddress(addr) then
        local temp = ffi.new(ctype:sub(1,-2).."[1]")
        temp[0] = value
        local size = ffi.sizeof(temp)
        addr = addr + size*index
        for i = 0, size-1 do
			PRIV.AddToPrivateCastTable(addr, i)
        end
        ffi.cast(ctype, addr)[0] = value
    else
        error("PrivateCast - wrong C type or address")
    end
end

PRIV.PrivateCopyCast = function(str, addr, force)
    if isValidAddress(addr) then
        str = tostring(str)
        local cstr = ffi.cast("char*", addr)
        for index = 0, #str do
			PRIV.AddToPrivateCastTable(addr, index)
            if not force and index > #ffi.string(cstr) and cstr[index] ~= 0 then
                error("PrivateCopyCast - string ".. str .. " has too many characters!")
            end
        end
        ffi.copy(cstr, str)
    else
        error("PrivateCopyCast - wrong address")
    end
end

PRIV.PrivateChamAdd = function(addr, code)
	local i = 0
	for v in string.gmatch(code, "([^ ]+)") do
		PrivateCast(tonumber(v, 16), "char*", addr, i)
		i = i+1
	end
end

PRIV.RestoreGamesCode = function() -- this function is only called when the player finishes/exits the current level
    for a, v in pairs(PRIV.Table) do
        ffi.cast("char*", a)[0] = v
    end
	table.clear(PRIV.Table)
end

return PRIV