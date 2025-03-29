--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Assets module ]] --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module loads the custom assets for the custom levels, except the custom logics.]]

local CMAP = {
	MapName = "",
	MapPath = "",
	FullMapPath = "",
	MusicTracks = {}
}

CMAP.GetClawPath = function()
	local str = ffi.new("char[255][1]")
	mdl_exe._GetClawPath(ffi.cast("int", str), 254)
	return ffi.string(ffi.cast("const char*", str[0]))
end

CMAP.LoadAsset = function(num, name)
	local asset = ffi.new("void*[1]")
	mdl_exe._LoadAsset(Game(num)+16, name, asset)
	return asset[0]
end

CMAP.IncludeAssets = function(path)
	local inst = ffi.cast("char*",0x4B720F)
    local oper = ffi.cast("unsigned int*", 0x4B7210)
    inst[0] = 0xE8 -- CALL
    oper[0] = 0xFFFFEEDC -- 004B60F0
	local ret = mdl_exe._IncludeAssets(nRes(13), path, 0)
	return ret
end

CMAP.MapMusicFile = function(address,name)
	local mus = LoadSingleFile(address, name, 0x584D49)
	if not mus then return end
	local var = ffi.cast("int*", mus)[3]
	mus = mdl_exe._GetMusicAddr(mus)
	if mus then
		table.insert(CMAP.MusicTracks, name)
		mdl_exe._MapMusicFile(nRes(20), mus, var, name)
	end
end

CMAP.MapFolder = function(mappath, folder)
	if not DirExists(mappath .. "\\" .. folder) then return end
	local fun =	(folder == "IMAGES" or folder == "TILES") and MapImagesFolder or folder == "SOUNDS" and MapSoundsFolder or
	folder == "ANIS" and MapAnisFolder or folder == "LEVEL" or error("bad name passed to map_folder")
	if folder == "LEVEL" then
		local lf = LoadFolder(folder)
		MapImagesFolder(lf,"LEVEL")
        MapSoundsFolder(lf,"LEVEL")
        MapAnisFolder(lf,"LEVEL")
	elseif folder == "TILES" then
        fun(LoadFolder(folder), "")
	else
        fun(LoadFolder(folder), "CUSTOM")
    end
end

CMAP.LoadBackground = function()
	local _customscreen = 0
	if DirExists(CMAP.MapPath .. "\\SCREENS") and FileExists(CMAP.MapPath .. "\\SCREENS\\LOADING.PCX") then
		local temp = nRes(11,8)
		local str = ffi.cast("char*", 0x52719C)
		--local original = ffi.string(str)
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
	if DirExists(CMAP.MapPath .. "\\IMAGES\\SPLASH") then
		if LoadAssetB("CUSTOM_SPLASH") ~= nil then
			PrivateCast(0x50BE60, "int*", 0x463B5D) -- custom splasher
		end
	end
end

CMAP.LoadPalettes = function()
	local palpath = CMAP.MapPath .. "\\PALETTES"
	if DirExists(palpath) then
		for filename in lfs.dir(palpath) do
			filename = filename:upper()
			if filename == 'MAIN.PAL' or filename == 'MAIN.ACT' or filename == "MAIN.TXT" then
				LoadPaletteFile(filename, nRes(11)+0x360)
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
	if CMAP.MapPath == "" then return end
	local musicspath = CMAP.MapPath .. "\\MUSIC"
	if DirExists(musicspath) then
		for filename in lfs.dir(musicspath) do
			if filename:sub(-4):upper() == ".XMI" then
				local trackname = filename:sub(1,-5)
				MapMusicFile(LoadFolder("MUSIC"), trackname)
			end
		end
	end
end

CMAP.CustomMusicFix = function()
	if FileExists(CMAP.MapPath .. "\\MUSIC\\LEVEL.XMI") or FileExists(CMAP.MapPath .. "\\MUSIC\\LEVEL.xmi") then
		PrivateCast(0x523734, "int*", 0x46D904) -- set LEVEL music as PLAY
        CMAP.MusicTracks[1] = "PLAY"
	end
end

CMAP.Main = function()
	local cham = _chameleon[0]
	if cham == chamStates.LoadingStart then
        CMAP.MapPath = ""
        CMAP.MapName = ""
        CMAP.FullMapPath = GetFullMapPath()
		CMAP.MusicTracks = {"LEVEL", "POWERUP", "MONOLITH"}
		if CMAP.FullMapPath == "" then
			-- set loading background for retail:
			mdl_exe._GetBgImage(nRes(11), "LOADING", 1, 1, 1, 0)
			-- set perfect image as "BOOTY_PERFECT":
			ffi.cast("char*", 0x52BA1D)[0] = 0
		else
			CMAP.MapName =  CMAP.FullMapPath:match'.*\\(.*)%.'
			assert(CMAP.MapName, "Could not match the map name in string '" ..  CMAP.FullMapPath .. "'.")
			CMAP.MapPath =  CMAP.FullMapPath:match'^(.*)%.'
			assert(CMAP.MapPath, "Could not match the map path in string '" ..  CMAP.FullMapPath .. "'.")
			if DirExists(CMAP.MapPath) then
				CMAP.IncludeAssets(CMAP.MapPath)
			end
			CMAP.LoadBackground()
			-- set perfect image as "BOOTY_PERFECTC":
			ffi.cast("char*", 0x52BA1D)[0] = 0x43
		end
    end
	if cham == chamStates.LoadingAssets and CMAP.MapPath ~= "" then
		CMAP.MapFolder(CMAP.MapPath, "TILES")
		CMAP.MapFolder(CMAP.MapPath, "IMAGES")
		CMAP.MapFolder(CMAP.MapPath, "SOUNDS")
		CMAP.MapFolder(CMAP.MapPath, "ANIS")
		CMAP.MapFolder(CMAP.MapPath, "LEVEL")
		CMAP.LoadSplash()
		CMAP.LoadPalettes()
		CMAP.CustomMusicFix()
	end
	if cham == chamStates.LoadingEnd then
		CMAP.LoadMusic()
    end
end

return CMAP
