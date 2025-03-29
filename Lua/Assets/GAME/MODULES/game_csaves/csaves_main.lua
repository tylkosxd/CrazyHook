--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- [[ Custom save system module ]] --------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local CSSTR = require"game_csaves.csaves_strings"
local CSFILE = require"game_csaves.csaves_file"

local scoreToExtraLife = ffi.cast("int*", 0x4940F9)
local savePointState = mdl_exe.CSavePoint

local _tab = table
local concat = _tab.concat

local function countTreasures(array)
	local total = 0
	for n = 0, 8 do
		total = total + array[n]
	end
	return total
end

local CSAVE = {}

CSAVE.LevelStarted = function()
	PrivateChamAdd(0x4247F0, "89 35 59 48 42 00 EB 3B")
	-- SuperCheckpointAttack logic change:
	-- mov dword ptr ds:[0x424859], esi ; save the checkpoint number (1 or 2) in the mdl_exe.CSavePoint[0] variable
	-- jmp short 0x3B ; skip the checks, so that the checkpoint won't save to CLAW.USR file
	CSAVE.DoOnlyOnce = false
	CSAVE.DoOnlyOnce2 = true
	CSAVE.TimeDelay = 0
	local entry = concat{'saves["', GetLevelName(), '"] = {}'}
	if not CSFILE.SaveFileExists() then
		CSFILE.WriteSaveFile(CSSTR.FirstSaveFileContent(entry))
		return
	end
	local data = CSFILE.ReadSaveFile()
	if not data:find(entry, 1, true) then
		CSFILE.WriteSaveFile(CSSTR.NewSaveFileContent(data, entry))
	end
end

CSAVE.LevelCompleted = function()
	local all = countTreasures(mdl_exe.TreasuresCountTable) -- all treasures available to collect
	local coll = countTreasures(ffi.cast("int*", tonumber(ffi.cast("int", PData()) + 0x88))) -- collected treasures
	local level = GetLevelName()
	local checksum = CSFILE.GetCompletionSum(level, coll, all)
	local entryShort = concat{'saves["', level, '"]'}
	local entry = concat{ entryShort, '[0] = {', coll, ",", all, ",", checksum, '}' }
	if not CSFILE.SaveFileExists() then
		entry = concat{entryShort, ' = {}\n', entry}
		CSFILE.WriteSaveFile(CSSTR.FirstSaveFileContent(entry))
		return
	end
	local data = CSFILE.ReadSaveFile()
	if data:find(entryShort.."[0]", 1, true) then
		local previous = CSSTR.GetEntryValues(data, 0)
		local checksumCorrect = CSFILE.GetCompletionSum(level, previous[1], previous[2]) == previous[3]
		if coll > previous[1] or not checksumCorrect then
			local pattern = EscapeMagicChars(entryShort .. "[0]") .. " = {.-}"
			CSFILE.WriteSaveFile(data:gsub(pattern, entry))
		end
	else
		CSFILE.WriteSaveFile(CSSTR.NewSaveFileContent(data, entry))
	end
end

CSAVE.SavePointTriggered = function(savepoint)
	local newContent
	repeat
		if FileExists(GetMapFolder() .. "\\LOGICS\\SaveSystem.lua")
		or savepoint == 0 then
			break
		end
		local entryShortest = concat{'saves["', GetLevelName(), '"]'}
		local entryShort = concat{entryShortest, '[', savepoint, ']'}
		local entry = CSSTR.CreateSaveEntry()
		if not CSFILE.SaveFileExists() then
			entry = concat{entryShortest, " = {}\n", entry}
			newContent = CSSTR.FirstSaveFileContent(entry)
			break
		end
		local data = CSFILE.ReadSaveFile()
		if not data:find(entryShortest, 1, true) then
			entry = concat{entryShortest, " = {}\n", entry}
			newContent =  CSSTR.NewSaveFileContent(data, entry)
			break
		end
		if not data:find(entryShort, 1, true) then
			newContent = CSSTR.NewSaveFileContent(data, entry)
			break
		end
		local previous = CSSTR.GetEntryValues(data, savepoint)
		if GetClaw().Score > previous[1]
		or (GetClaw().Score == previous[1] and PData().Lives >= previous[8])
		or CSFILE.GetSaveSum(GetLevelName(), previous) ~= previous[18] then
			local pattern = EscapeMagicChars(entryShort) .. " = {.-}"
			newContent = data:gsub(pattern, entry)
		end
	until true
	if newContent then
		CSFILE.WriteSaveFile(newContent)
		TextOut("Your game has been saved!")
		CSAVE.TimeDelay = GetTime()
	end
	savePointState[0] = 0
end

CSAVE.LevelLoaded = function(savepoint)
	if not CSFILE.SaveFileExists() then return end
	local level = GetLevelName()
	local data = CSFILE.ReadSaveFile()
	local save
	local entry = concat{'["', level, '"][', savepoint, ']'}
	if data:find(entry, 1, true) then
		save = CSSTR.GetEntryValues(data, savepoint)
	end
	if not save then return end
	if CSFILE.GetSaveSum(level, save) ~= save[18] then return end
	PrivateCast(0xEB, "char*", 0x49404D) -- jmp on level start to not get extra live
	local pd = PlayerData()
	local claw = GetClaw()
	claw.Score = save[1]
	pd.ScoreToExtraLife = math.floor(save[1]/scoreToExtraLife[0])*scoreToExtraLife[0] + scoreToExtraLife[0]
	claw.Health = save[2]
	pd.SpawnScore = save[1]
	pd.SpawnHealth = save[2]
	pd.SpawnPointX = save[3]
	pd.SpawnPointY = save[4]
	pd.PistolAmmo = save[5]
	pd.MagicAmmo = save[6]
	pd.TNTAmmo = save[7]
	pd.Lives = save[8]
	pd.CollectedCoin = save[9]
	pd.CollectedGoldbar = save[10]
	pd.CollectedRing = save[11]
	pd.CollectedChalice = save[12]
	pd.CollectedCross = save[13]
	pd.CollectedScepter = save[14]
	pd.CollectedGecko = save[15]
	pd.CollectedCrown = save[16]
	pd.CollectedSkull = save[17]
	pd.GameCollectedCoin = save[9]
	pd.GameCollectedGoldbar = save[10]
	pd.GameCollectedRing = save[11]
	pd.GameCollectedChalice = save[12]
	pd.GameCollectedCross = save[13]
	pd.GameCollectedScepter = save[14]
	pd.GameCollectedGecko = save[15]
	pd.GameCollectedCrown = save[16]
	pd.GameCollectedSkull = save[17]
	pd.LoadedFromSavePoint = 1
	mdl_exe.GameLoadedFromSP[0] = 1
	claw.State = 23
	LoopThroughObjects()
	CSAVE.DoOnlyOnce2 = false
	CSAVE.DoOnlyOnce = true
end

CSAVE.LevelLoaded2 = function()
	ffi.cast("char*", 0x49404D)[0] = 0x7D -- reverse extra life jump (PrivateCast(0xEB, "char*", 0x49404D))
	savePointState[0] = 0
	CSAVE.DoOnlyOnce2 = true
end

CSAVE.Main = function(ptr)
	if not IsCustomLevel() then return end

	local cham = _chameleon[0]

	if cham == chamStates.LoadingStart then
		CSAVE.LevelStarted()
		return
	end
	if cham == chamStates.OnPostMessage then
		local id = tonumber(ffi.cast("int", ptr))
		if id == _message.LevelEnd and not CheatsUsed() then
			CSAVE.LevelCompleted()
		end
	end
	if savePointState[0] ~= 1 and savePointState[0] ~= 2 then return end -- only save points 1 and 2
	if cham == chamStates.LoadingObjects and not CSAVE.DoOnlyOnce then
		CSAVE.LevelLoaded(savePointState[0])
	end
	if cham == chamStates.Gameplay then
		if not CSAVE.DoOnlyOnce2 and GetTime() > 500 then -- after the first 500ms of gameplay if loaded from a save point.
			CSAVE.LevelLoaded2()
		end
		if GetTime() > CSAVE.TimeDelay + 2000 then -- after 2s of gameplay or the last save, the saving is possible again
			CSAVE.SavePointTriggered(savePointState[0])
		end
	end
end

return CSAVE
