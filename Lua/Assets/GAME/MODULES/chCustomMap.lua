local CMAP = {MusicTracks = {}}


CMAP.MapFolder = function(mappath, folder)
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

CMAP.LoadBackground = function()
	local _customscreen = 0
	if _DirExists(_mappath.."\\SCREENS") and _FileExists(_mappath.."\\SCREENS\\LOADING.PCX") then
		local temp = nRes(11,8)
		local str = ffi.cast("char*", 0x52719C)
		ffi.copy(str, "%s")
		snRes(ffi.cast("int",LoadFolder("SCREENS")), 11, 8)
		_customscreen = mdl_exe._GetBgImage(nRes(11), "LOADING", 1, 1, 1, 0)
		ffi.copy(str, "\\SCREENS\\%s")
		snRes(temp, 11, 8)
	end
	if _customscreen == 0 then	
		mdl_exe._GetBgImage(nRes(11), "LOADING", 1, 1, 1, 0) 
	end
end

CMAP.LoadSplash = function()
	if _DirExists(_mappath.."\\IMAGES\\SPLASH") then
		if LoadAssetB("CUSTOM_SPLASH") ~= nil then
			PrivateCast(0x50BE60, "int*", 0x463B5D) -- custom splasher
		end
	end
end

CMAP.LoadPalettes = function()
	local palpath = _mappath .. "\\PALETTES"
	if _DirExists(palpath) then
		for filename in lfs.dir(palpath) do
			filename = filename:upper()
			if filename:match'(MAIN%.%a%a%a)' then
				LoadPalette(filename)
			end
			if filename == 'AVERAGE.CLT' then
				LoadAverageCLT(filename)
			end
			if filename == 'LIGHT.CLT' then
				LoadLightCLT(filename)
			end
		end
	end
end

CMAP.LoadMusic = function()
	local lvl = nRes(11,5)
	if lvl == 2 or lvl == 4 or lvl == 6 or lvl == 8 or lvl == 10 or lvl == 12 or lvl == 13 or lvl == 14 then
		table.insert(CMAP.MusicTracks, "BOSS")
	end
	if _mappath ~= "" then 
		local musicspath = _mappath .. "\\MUSIC"
		if _DirExists(musicspath) then
			for filename in lfs.dir(musicspath) do
				if _FileExists(musicspath.."\\"..filename) then
					if filename:upper():sub(-3) == "XMI" then
						local trackname = filename:sub(1,-5)
						MapMusicFile(LoadFolder("MUSIC"), trackname)
					end
				end
			end
		end
	end
end

CMAP.CustomMusicFix = function()
	if _FileExists(_mappath.."\\MUSIC\\LEVEL.XMI") or _FileExists(_mappath.."\\MUSIC\\LEVEL.xmi") then
		PrivateCast(0x523734, "int*", 0x46D904) -- set retail's LEVEL music as PLAY
        CMAP.MusicTracks[1] = "PLAY"
	end
end

CMAP.LoadAssets = function()

	if _chameleon[0] == chamStates.LoadingStart then
        _mappath = "" 
        _mapname = ""
        _fullmapname = GetMapName()
		if _fullmapname == "" then
			-- set loading background for retail:
			mdl_exe._GetBgImage(nRes(11), "LOADING", 1, 1, 1, 0) 
		else
			-- get map name and map path:
			_mapname = _fullmapname:match'.*\\(.*)%.'
			assert(_mapname, "Could not match the map name in string '" .. _fullmapname .. "'.")
			_mappath = _fullmapname:match'^(.*)%.'
			assert(_mappath, "Could not match the map path in string '" .. _fullmapname .. "'.")
			if _DirExists(_mappath) then
				IncludeAssets(_mappath)
			end
			CMAP.LoadBackground()
		end
    end
	
	if _mappath ~= "" and _chameleon[0] == chamStates.LoadingAssets then
		CMAP.MapFolder(_mappath,"TILES")
		CMAP.MapFolder(_mappath,"IMAGES")
		CMAP.MapFolder(_mappath,"SOUNDS")
		CMAP.MapFolder(_mappath,"ANIS")
		CMAP.MapFolder(_mappath,"LEVEL")
		CMAP.LoadSplash()
		CMAP.LoadPalettes()
		CMAP.CustomMusicFix()
	end
	
	if _chameleon[0] == chamStates.LoadingEnd then
		CMAP.LoadMusic()
    end
	
end

return CMAP
