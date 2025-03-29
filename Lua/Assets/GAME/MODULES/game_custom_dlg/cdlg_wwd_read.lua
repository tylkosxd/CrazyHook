--[[ This module reads the WWD files and gets the info about them, like level number, author, date.]]

ffi.cdef[[
    typedef struct CWwdHeaderSmall {
        int offset[4];
        const char name[64];
        const char author[64];
        const char date[64];
    } CWwdHeaderSmall;
]]

local RECS = nil -- optional module

local Months = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December"
}

-- Caching functions for the max performance:
local toLnumber, Lassert = tonumber, assert
local _io, _table, _string, _math, _lfs, _ffi = io, table, string, math, lfs, ffi
local open, close = _io.open, _io.close
local cast, new, toLstring, C, copy = _ffi.cast, _ffi.new, _ffi.string, ffi.C, _ffi.copy
local concat, floor = _table.concat, _math.floor
local match, sub, upper, byte = _string.match, _string.sub, _string.upper, _string.byte
local lfsAttr, lfsDir = _lfs.attributes, _lfs.dir

local function fixDate(str)
    local first = sub(str, 1, 1)
    if byte(first) >= 0x30 and byte(first) <= 0x39 then
        local mon = Months[toLnumber(sub(str, -7, -6))]
        local day = sub(str, -10 ,-9)
		day = sub(day, 1, 1) == "0" and sub(day, -1) or day
        str = concat{mon, " ", day, ", ", sub(str, -4)}
    end
	return str
end

local function addLevelToListBox(hdlg, name)
    local str = new("char[?]", #name+1)
    copy(str, name)
    local listBox = C.GetDlgItem(hdlg, 0x3FC)
	C.SendMessageA(listBox, 0x180, 0, cast("int", str))
end

local function readWwdHeader(hdlg, path, filename)
    local fullpath = concat{path, filename}
    local wwdFile = Lassert(open(fullpath, "rb"))
    local byteStream = new("char[208]")
    byteStream = wwdFile:read(208)
    close(wwdFile)
    local header = cast("CWwdHeaderSmall*", byteStream)
    local levelNum = toLnumber(match(toLstring(header.name), "(%d+)")) -- allegedly this is how it works
    local name = sub(filename, 1,-5) -- the real name is not in the header
    levelNum = (levelNum > 14 or levelNum < 0) and 0 or levelNum
    local gameVersion = lfsAttr(concat{path, name}, "mode") == "directory" and "CLAW" or "OLDCLAW"
    local data = {
        Version = gameVersion,
        Level = levelNum,
        Author = toLstring(header.author),
        Date = fixDate(toLstring(header.date)),
        Rec = not RECS or not RECS[name] and 0 or RECS[name],
        Size = floor(lfsAttr(fullpath, "size")/1024)
    }
    addLevelToListBox(hdlg, name)
    return name, data
end

return function(hdlg, customPath)
    if not RECS then
        RECS = SafeRequire('Custom._recs') or {} -- empty table if the recommendation module does not exist
    end
    local wwdData = {}
    for filename in lfsDir(customPath) do
        if #filename > 4 and upper(sub(filename, -4)) == ".WWD" then
            local name, data = readWwdHeader(hdlg, customPath, filename)
            wwdData[name] = data
        end
    end
    return wwdData
end