local _GetClawPath = ffi.cast("int (*__cdecl)(int, int)", 0x4AF5E4)
local _DoOnlyOnce3 = false
local _saves = nil
local _find = nil
local s = nil
local timeDelay = 0
local sp = mdl_exe.CSavePoint
local stl = ffi.cast("int*", 0x4940F9) -- extra life score
local save_now = false

local function _chamAdd(addr, code) 	
	local cham_exe = ffi.cast("char*",addr) 	
	local i = 0 	
	for v in string.gmatch(code, "([^ ]+)") do 		
		cham_exe[i] = tonumber(v, 16) 		
		i = i+1 	
	end 
end

function GetCustomSavePath()
    return GetClawPath() .. "\\CustomSaves.lua"
end

local function GetSaveVals(data, n)
    local t = {}
    local i = 1
    local vals = data:match('saves%["'.. _mapname ..'"%]%[' .. n .. '%] = {(.-)}')
    for val in string.gmatch(vals, "%d+") do
        t[i] = tonumber(val)
        i = i + 1
    end
    return t
end

local function CheckSum(t)
	local sum = t[1] + t[2] + t[3] + t[4] - t[5] - t[6] - t[7] - t[8] - t[9] - t[10] - t[11] - t[12] - t[13] - t[14] - t[15] - t[16] - t[17] + 788529152
	return tonumber(ffi.cast("unsigned int", tonumber(NOT(sum)))) == t[18]
end

local function CalcSum()
	local claw = GetClaw()
	local player = PData()
	local sum = claw.Score + claw.Health + claw.X + claw.Y - player.PistolAmmo - player.MagicAmmo - player.DynamiteAmmo - player.Lives - player.CollectedCoin - player.CollectedGoldbar - player.CollectedRing - player.CollectedChalice - player.CollectedCross - player.CollectedScepter - player.CollectedGecko - player.CollectedCrown - player.CollectedSkull + 788529152
	return tonumber(ffi.cast("unsigned int", tonumber(NOT(sum))))
end

local function GetCurPlayerStats()
	return 'saves["'.._mapname..'"]['..sp[0]..'] = {' ..GetClaw().Score..","..GetClaw().Health..","..GetClaw().X..","..GetClaw().Y..","..PData().PistolAmmo..","..PData().MagicAmmo..","..
    PData().DynamiteAmmo..","..PData().Lives..","..PData().CollectedCoin..","..PData().CollectedGoldbar..","..PData().CollectedRing..","..PData().CollectedChalice..","..
    PData().CollectedCross..","..PData().CollectedScepter..","..PData().CollectedGecko..","..PData().CollectedCrown..","..PData().CollectedSkull..","..CalcSum().."}"
end

local _csave = {}

_csave.Save = function()

    if GetTime() < 300 then
        -- SuperCheckpoint - jne to je change:
        PrivateCast(0x84, "char*", 0x4247AC)
        -- SuperCheckpoint - set checkpoint state on trigger:
        PrivateCast(0x89, "char*", 0x4247F0)
        PrivateCast(0x35, "char*", 0x4247F1)
        PrivateCast(0x424859, "int*", 0x4247F2)
        PrivateCast(0xEB, "char*", 0x4247F6)
        PrivateCast(0x3B , "char*", 0x4247F7)
    end
	
    if  _mappath ~= "" and GetTime() > 10000 and not _FileExists(_mappath.."\\LOGICS\\SaveSystem.lua") then
        -- 10s time delay before next possible save:
        if timeDelay == 0 then
            -- if supercheckpoint has been triggered:
            if sp[0] > 0 and sp[0] <= 2 then
                -- save data:
                local saveStr = GetCurPlayerStats()
                -- save file does exist:
                if _FileExists(GetCustomSavePath()) then
                    local file = assert(io.open(GetCustomSavePath(), "r"))
                    local data = file:read("*all")
                    file:close()
                    -- find if there is a save for this level already:
                    local _find = string.find(data, '["'.._mapname..'"]', 1, true)
                    -- no:
                    if not _find then
                        saveStr = string.sub(data, 1, -13).. 'saves["'.._mapname..'"] = {}\n'..saveStr..'\nreturn saves'
						save_now = true
                    -- yes:
                    else
                        -- find if there is a save for this checkpoint:
                        _find = string.find(data, '["'.._mapname..'"]['..sp[0]..']', 1, true)
                        -- no:
                        if not _find then
                            saveStr = string.sub(data, 1, -13) ..saveStr..'\nreturn saves'
							save_now = true
                        -- yes:
                        else
                            -- check if the player gathered more points or has more lives:
                            local t = GetSaveVals(data, sp[0])
                            -- yes:
                            if GetClaw().Score > t[1] or (GetClaw().Score == t[1] and PData().Lives >= t[8]) then
                                local patt = 'saves%["'.. _mapname ..'"%]%[' .. sp[0] .. '%] = {.-}'
                                local s, _ = string.gsub(data, patt, saveStr)
                                saveStr = s
								save_now = true
                            -- no (don't save):
                            else
                                save_now = false
								sp[0] = 0
                            end
                        end
                    end
                -- save file doesn't exist:
                else
                    saveStr = 'saves = {}\n'..'saves["'.._mapname..'"] = {}\n'..saveStr..'\nreturn saves'
                    save_now = true
                end
				-- save the game:
                if save_now then
                    local file = assert(io.open(GetCustomSavePath(), "w"))
                    file:write(saveStr)
                    file:close()
                    TextOut("Your game has been saved!")
					timeDelay = GetTime()
					save_now = false
					sp[0] = 0
                end
            end

        -- reset time delay after 10s:
        elseif GetTime() >= timeDelay + 10000 then
            timeDelay = 0
            sp[0] = 0
			save_now = false
        end
	else
		if sp[0] ~= 0 then
			sp[0] = 0
		end
    end
end

_csave.Load = function()
    if _mappath ~= "" and GetGameType() == GameType.SinglePlayer then -- if custom level and singleplayer
        if sp[0] > 0 then
            if _chameleon[0] == chamStates.LoadingAssets then
                if _FileExists(GetCustomSavePath()) then
                     local _file = assert(io.open(GetCustomSavePath(), "r"))
                    _saves = _file:read("*all")
                    io.close(_file)
                end
                if _saves then
                    _find = string.find(_saves, '["'.._mapname..'"]['..sp[0]..']', 1, true)
                end
                if _find then
                    s = GetSaveVals(_saves, sp[0])
                end
                if s then
					if s[1] >= stl[0] then
						PrivateCast(0xEB, "char*", 0x49404D) -- jmp on level start to not get extra live
					end
					if not CheckSum(s) then
						_DoOnlyOnce3 = true
					else
						_DoOnlyOnce3 = false
					end
                end
            end

            if _chameleon[0] == chamStates.LoadingObjects and s then
                if _DoOnlyOnce and not _DoOnlyOnce3 then
                    PData().ScoreToExtraLife = math.floor(s[1]/stl[0])*stl[0] + stl[0]
				    PlayerData().SpawnPointX = s[3]
				    PlayerData().SpawnPointY = s[4]
                    GetClaw().State = 23
                    PData().SpawnScore = s[1]
                    GetClaw().Score = s[1]
                    PData().SpawnHealth = s[2]
                    GetClaw().Health = s[2]
                    PData().SpawnPointX = s[3]
                    PData().SpawnPointY = s[4]
                    PData().PistolAmmo = s[5]
                    PData().MagicAmmo = s[6]
                    PData().TNTAmmo = s[7]
                    PData().Lives = s[8]
                    PData().CollectedCoin = s[9]
                    PData().CollectedGoldbar = s[10]
                    PData().CollectedRing = s[11]
                    PData().CollectedChalice = s[12]
                    PData().CollectedCross = s[13]
                    PData().CollectedScepter = s[14]
                    PData().CollectedGecko = s[15]
                    PData().CollectedCrown = s[16]
                    PData().CollectedSkull = s[17]
                    PData().GameCollectedCoin = s[9]
                    PData().GameCollectedGoldbar = s[10]
                    PData().GameCollectedRing = s[11]
                    PData().GameCollectedChalice = s[12]
                    PData().GameCollectedCross = s[13]
                    PData().GameCollectedScepter = s[14]
                    PData().GameCollectedGecko = s[15]
                    PData().GameCollectedCrown = s[16]
                    PData().GameCollectedSkull = s[17]
                    PData().LoadedFromSavePoint = 1
                    mdl_exe.GameLoadedFromSP[0] = 1
                    LoopThroughObjects()
                    _DoOnlyOnce3 = true
                end
                
            end

            if _chameleon[0] == chamStates.Gameplay and GetTime() > 500 and GetTime() < 1000 then
                _saves, _find, s = nil, nil, nil
                ffi.cast("char*", 0x49404D)[0] = 0x7D
                sp[0] = 0
            end
        end
    end
end

return _csave
