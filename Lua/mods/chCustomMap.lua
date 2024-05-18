local _fullmapname = ""
local _mapname = ""
local _mappath = ""

local function map_folder(mappath, folder)
	if not _DirExists(mappath .. "\\" .. folder) then return end
	local fn =	(folder == "IMAGES" or folder == "TILES") and MapImagesFolder or
				folder == "SOUNDS" and MapSoundsFolder or
				folder == "ANIS" and MapAnisFolder or
				folder == "LEVEL" or
				error("bad name passed to map_folder")
	if folder == "LEVEL" then
		local lf = LoadFolder(folder)
		MapImagesFolder(lf,"LEVEL") 
        MapSoundsFolder(lf,"LEVEL") 
        MapAnisFolder(lf,"LEVEL")
	elseif folder == "TILES" then 
        fn(LoadFolder(folder), "")
	else 
        fn(LoadFolder(folder), "CUSTOM") 
    end
end

local _cm = {}

_cm.LoadCustomAssets = function()
	-- The level is selected and the loading starts:
	if _chameleon[0] == chamStates.LoadingStart then

		_fullmapname = GetMapName()
		if #_fullmapname == 0 then
			mdl_exef._SetBgImage(nRes(11), "LOADING", 1, 1, 1, 0) 
		else
			_mapname = _fullmapname:match'^%a:*\\(.*)%.'
			assert(_mapname, "Could not match the map name in string '" .. _fullmapname .. "'.")
			_mappath = _fullmapname:match'^(.*)%.'
			assert(_mappath, "Could not match the map path in string '" .. _fullmapname .. "'.")
			--
			local cscreen = 0
			if _DirExists(_mappath) then
				IncludeAssets(_mappath)
				if _DirExists(_mappath.."\\SCREENS") then
					local temp = nRes(11,8)
					local str = ffi.cast("char*", 0x52719C)
					local cpy = ffi.cast("char*","%s")
					for i=0,3 do
						str[i] = cpy[i]
					end
					snRes(ffi.cast("int",LoadFolder("SCREENS")),11,8)
					cscreen = mdl_exef._SetBgImage(nRes(11),"LOADING",1,1,1,0)
					cpy = ffi.cast("char*","\\SCREENS\\%s")
					for i=0,12 do
						str[i] = cpy[i]
					end
					snRes(temp,11,8)
				end
			end
			if cscreen == 0 then	
				mdl_exef._SetBgImage(nRes(11),"LOADING",1,1,1,0) 
			end
		end
        
	elseif _chameleon[0] == chamStates.LoadingAssets then
		if #_fullmapname > 0 then
			map_folder(_mappath,"TILES")
			map_folder(_mappath,"IMAGES")
			map_folder(_mappath,"SOUNDS")
			map_folder(_mappath,"ANIS")
			map_folder(_mappath,"LEVEL")
			local palpath = _mappath .. "\\PALETTES"
			if _DirExists(palpath) then
				for filename in lfs.dir(palpath) do
					if string.upper(filename):match'MAIN%....' then
						LoadPalette(filename)
					end
                    if string.upper(filename) == 'AVERAGE.CLT' then
                        LoadAverageCLT(filename)
                    end
                    if string.upper(filename) == 'LIGHT.CLT' then
                        LoadLightCLT(filename)
                    end
				end
			end
		end
		
	elseif _chameleon[0] == chamStates.LoadingEnd then
		if #_fullmapname > 0 then 
			local musicspath = _mappath .. "\\MUSIC"
			if _DirExists(musicspath) then
				for filename in lfs.dir(musicspath) do
					if _FileExists(musicspath.."\\"..filename) then
						MapMusicFile(LoadFolder("MUSIC"),filename:match('(.*)%.'))
					end
				end
			end
		end
    end
end

return _cm
