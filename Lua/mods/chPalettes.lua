local _pals = {}

local function _GetPalPath(filename)
	return GetMapName():match'^(.*)%.' .."\\PALETTES\\"..filename
end

_pals.LoadPalette = function(filename, pal_ptr)
	pal_ptr = ffi.cast("unsigned char*", pal_ptr)
	local _palPath = _GetPalPath(filename)
	if _FileExists(_palPath) then
        local _fileExt = string.upper(string.sub(filename, -3))
		-- binary PAL or ACT file:
        if _fileExt == "PAL" or _fileExt == "ACT" then
		    local _input = assert(io.open(_palPath, "rb"))
		    local _data = _input:read("*all")
			_input:close()
		    for i = 0, 255 do
		    	pal_ptr[ i*4 ] = string.byte(_data, i*3+1)
		    	pal_ptr[i*4+1] = string.byte(_data, i*3+2)
		    	pal_ptr[i*4+2] = string.byte(_data, i*3+3)
		    end
		-- text file:
        elseif _fileExt == "TXT" then
            local _input = assert(io.open(_palPath, "r"))
            for i = 0, 255 do
                local _colorHex = _input:read() -- reads one line per call by default
                if _colorHex then
                    pal_ptr[ i*4 ] = tonumber(string.sub(colorHex, 2, 3), 16)
                    pal_ptr[i*4+1] = tonumber(string.sub(colorHex, 4, 5), 16)
                    pal_ptr[i*4+2] = tonumber(string.sub(colorHex, 6, 7), 16)
                end
            end
            _input:close()
        else
            error("Invalid palette file")
        end
	else
		error("No file found")
	end 
end

_pals.LoadCLT = function(filename, clt_ptr)
	local cltPtr = ffi.cast("uint8_t*", clt_ptr)
    local cltPath = _GetPalPath(filename)
	if _FileExists(cltPath) then
		local input = assert(io.open(cltPath, "rb"))
		local data = input:read("*all")
		for i = 0, 0xFFFF do
		    cltPtr[i] = string.byte(data, i+5)
		end
        input:close()
	else
		error("No file found")
    end
end

return _pals
