-- Base level data:
ffi.cdef[[
	typedef struct LevelBasedData {
		int LevelNb;
		char SpringBoardAnimationIdle[32];
		char SpringBoardAnimationSpring[32];
		int DeathTileType;
		Rect SpringBoardDefRect;
		Rect TogglePegDefRect;
		Rect ElevatorDefRect;
		Rect CrumblingPegDefRect;
		Rect SteppingStoneDefRect;
		Rect BigElevatorDefRect;
		int BreakPlankWidth;
		int field_AC;
		int SplashY;
		int MPSkinnerPosX;
		int MPSkinnerPosY;
	} LevelBasedData;
]]

-- Base game pickups:
ffi.cdef[[
	typedef struct CBasePickups {
		int AmmoBigBag;
		int Ammo;
		int AmmoBag;
		int Catnip1;
		int Catnip2;
		int Food;
		int BigPotion;
		int SmallPotion;
		int MediumPotion;
		int MagicGlow;
		int MagicStar;
		int MagicClaw;
	} CBasePickups;
]]

local LEVEL = {}

LEVEL.SetDeathType = function(t)
    LevelBasedData[0].DeathTileType = t
    LevelBasedData[1].DeathTileType = t
end

LEVEL.SetBossFightPoint = function(x, y)
    local point = ffi.istype("Point", x) and x or ffi.new("Point", {x, y})
    if InMapBoundaries(point.x, point.y) then
        LevelBasedData[0].MPSkinnerPosX = point.x
	    LevelBasedData[0].MPSkinnerPosY = point.y
    else
        MessageBox("SetBossFightPoint - coordinates out of main plane boundaries")
    end
end

LEVEL.GetTreasuresNb = function(t)
	local countTable = mdl_exe.TreasuresCountTable
	if type(t) == "number" and t >= 0 and t <= 8 then
        return countTable[t]
	elseif type(t) == "string" and TreasureType[t] then
		return countTable[TreasureType[t]]
	else
		MessageBox("GetTreasuresNb - wrong treasure type")
    end
end

LEVEL.RegisterTreasure = function(t, nb)
	local countTable = mdl_exe.TreasuresCountTable
	nb = type(nb) == "number" and nb or 1
	if type(t) == "number" and t >= 0 and t <= 8 then
		countTable[t] = countTable[t] + nb
	elseif type(t) == "string" and TreasureType[t] then
		t = TreasureType[t]
		countTable[t] = countTable[t] + nb
	else
		MessageBox("RegisterTreasure - wrong treasure type")
    end
end

LEVEL.SendMPMessage = function(message0, message1, message2, affects_player)
    local args = ffi.new("int[5]", {0x3F2, message1 or 0, message2 or 0, message0, 0})
    if GetGameType() == GameType.MultiPlayer then
        mdl_exe._SendMultiMessage(nRes(11), args, 1)
    end
    if affects_player == true then
        MultiMessage[0] = message0
		MultiMessage[1] = message1 or 0
		MultiMessage[2] = message2 or 0
    end
end

return LEVEL