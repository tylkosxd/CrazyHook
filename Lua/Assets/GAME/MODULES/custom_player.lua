--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Player module ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
-- Functions related to the player (Claw) and the definition of the player's data type which pointer is returned by the PlayerData().

ffi.cdef[[
    typedef struct CPlayerData {
		int Direction;
		int Attack;
		int Throw;
		int Lift;
		int ProjectileUse;
		int _f_14;
		int Death;
		int Attack2;
		int Attack3;
		int LoadedFromSavePoint;
		int _f_28;
		int ClimbDir;
		int ActiveSecondWeapon;
		int _f_34;
		int _f_38;
		int AttackType;
		int FallHeight;
		int SpawnScore;
		int SpawnHealth;
		int SpawnPointX;
		int SpawnPointY;
		int AttackOffsetX;
		int AttackOffsetY;
		int JumpHeight;
		int JumpStartY;
		int JumpPeakY;
		int ClimbPeakY;
		int Attack4;
		int PistolAmmo;
		int MagicAmmo;
		int DynamiteAmmo;
		int Lives;
		int AttemptNb;
		int ConveyorBeltForce;
		int CollectedCoin;
        int CollectedGoldbar;
        int CollectedRing;
        int CollectedChalice;
        int CollectedCross;
        int CollectedScepter;
        int CollectedGecko;
        int CollectedCrown;
        int CollectedSkull;
        int _f_AC;
        int GameCollectedCoin;
        int GameCollectedGoldbar;
        int GameCollectedRing;
        int GameCollectedChalice;
        int GameCollectedCross;
        int GameCollectedScepter;
        int GameCollectedGecko;
        int GameCollectedCrown;
        int GameCollectedSkull;
        int _f_D4;
        Rect LiftRect;
        int AttackCount;
        int ScoreToExtraLife;
        int LiftTime;
        int ThrowTime;
        int _f_F8;
        int LookUpTime;
        int DynThrowTime;
        int DynThrowMinTime;
        int DynThrowMaxTime;
        int JumpTime;
        int LookDownTime;
        int RunningSpeedTime;
		int JumpPressTime;
		int _f_11C;
		int AFKTime;
		int _f_124;
		int _f_128;
		struct ObjectA* Lifted;
		struct ObjectA* CatnipGlitter;
	} CPlayerData;
]]

-- Old PlayerData (needs to stay for the backward compatibility):
ffi.cdef[[
    typedef struct PData {
	    int Dir;
	    int _unkn2;
	    int _unkn3;
	    int _unkn4;
	    int _unkn5;
	    int _unkn6;
	    int _unkn7;
	    int _unkn8;
	    int _unkn9;
	    int _unkn10;
	    int _unkn11;
	    int _unkn12;
	    int _unkn13;
	    int _unkn14;
	    int _unkn15;
	    int _unkn16;
	    int _unkn17;
	    int _unkn18;
	    int _unkn19;
	    int SpawnPointX;
	    int SpawnPointY;
	    int _unkn22;
	    int _unkn23;
	    int _unkn24;
	    int _unkn25;
	    int _unkn26;
	    int _unkn27;
	    int _unkn28;
	    int PistolAmmo;
	    int MagicAmmo;
	    int TNTAmmo;
	    int Lives;
	    int AttemptNb;
	    int _unkn34;
	    int _unkn35;
	    int _unkns[35];
	    int _unkn71;
	    int _unkn72;
	    int _unkn73;
	    int _unkn74;
	    int _unkn75;
	    int _unkn76;
	    int _CGlit;
    } PData;
]]

-- the metatype that links both old and new PData:
ffi.metatype("PData",
	{
		__index = function(self, key)
			local good, result = pcall(function()
				return ffi.cast("CPlayerData*", self)[key]
			end)
			if good then
				return result
			end
		end,
		__newindex = function(self, key, val)
			local good = pcall(function()
				return ffi.cast("CPlayerData*", self)[key]
			end)
			if good then
				ffi.cast("CPlayerData*", self)[key] = val
				return
			end
			if self[key] then
				self[key] = val
				return
			end
			error("PData __newindex")
		end
	}
)

local PLAY = {}

PLAY.GetClawAttackType = function(str)
    local attackType = AttackString[1+PlayerData().AttackType]
    return not str and attackType or attackType:match(tostring(str):lower())
end

PLAY.BlockClaw = function()
	mdl_exe._BlockClaw()
	GetClaw().Flags.NoHit = true
	GetClaw().Flags.Safe = true
end

PLAY.UnblockClaw = function()
	GetClaw().State = ClawStates.Stand
	GetClaw().Flags.NoHit = false
	GetClaw().Flags.Safe = false
end

PLAY.TeleportClaw = function(x,y)
    if InMapBoundaries(x,y) then
        mdl_exe.TeleportX[0] = x
        mdl_exe.TeleportY[0] = y
        ffi.C.PostMessageA(nRes(1,1), 0x111, _message.Teleport, 0);
    else
        MessageBox("TeleportClaw - coordinates out of main plane boundaries")
    end
end

PLAY.KillClaw = function()
	GetClaw().Health = 0
	mdl_exe._KillClaw(GetClaw(), GetClaw()._v, PData(), 0)
end

PLAY.ClawTakeDamage = function(damage)
    local afterHealth = GetClaw().Health - damage
	GetClaw().Health = afterHealth > 0 and afterHealth or 0
	if GetClaw().Health == 0 then
		KillClaw()
	end
end

PLAY.SetRespawnPoint = function(x,y)
    if not x and not y then
        snRes(GetClaw().X, 11, 17)
	    snRes(GetClaw().Y, 11, 18)
		return
    end
	if ffi.istype("Point", x) then
		y = x.y
		x = x.x
	end
    if InMapBoundaries(x, y) then
        snRes(x, 11, 17)
        snRes(y, 11, 18)
    else
        MessageBox("SetRespawnPoint - coordinates out of main plane boundaries")
    end
end

PLAY.SetRunningSpeedTime = function(miliseconds)
    local at = {0x417AB4, 0x417AF6, 0x41842F, 0x418547, 0x41866D, 0x418F9F, 0x4190F3, 0x419203, 0x4192A3, 0x419730, 0x419B00,
    0x419CC3, 0x419CF9, 0x419FF7, 0x41A09D, 0x41AC4B, 0x41ACFE, 0x41AD8F, 0x41B0C2, 0x41B2D6, 0x41B791, 0x41BB54, 0x41BC14, 0x41BC98,
    0x41C6FD, 0x41C9A5, 0x41CBBE, 0x41CBF0, 0x41D60C, 0x421108, 0x4212ED, 0x42158E, 0x421637, 0x421A1D}
    for _, addr in ipairs(at) do
        ffi.cast("int*", addr)[0] = miliseconds
    end
end

PLAY.SetJumpHeight = function(jump, height)
	local addr1 = jump == 0 and 0x50D400 or jump == 1 and 0x50D404 or 0x50D408
	local addr2 = jump == 0 and 0x41CB33 or jump == 1 and 0x41CAF7 or jump == 2 and 0x41CAC1 or jump == 3 and 0x41CA87
	-- 0 - normal, 1 - running, 2 - Catnip, 3 - MPJORDAM
	local multiplier = ffi.cast("float*", addr1)[0]
	PrivateCast(math.floor(height/multiplier), "int*", addr2)
end

PLAY.SetClawProjectileDamage = function(proj, damage)
	local addr1 = proj == 0 and 0x41DB0B or proj == 1 and 0x41DBB3 or proj == 2 and 0x41DCAC
	local addr2 = proj == 0 and 0x41DE4D or proj == 1 and 0x41DF09 or proj == 2 and 0x41E012
	-- 0 - pistol, 1 - magic, 2 - Dynamite
	PrivateCast(damage, "int*", addr1)
	PrivateCast(damage, "int*", addr2)
end

PLAY.OriginalClawSpeedsTable = {
	tonumber(ffi.cast("int*", 0x41CBC8)[0]),

}

PLAY.MultClawSpeed = function(mul)
	local addresses = {
		0x41CBC8, -- jump right move
		0x41CBFA, -- jump left move
		0x4198FB, -- left normal move
		0x419902, -- left catnip move
		0x41991B, -- left run move
		0x419932, -- left turbo move
		0x41952B, -- right normal move
		0x419532, -- right catnip move
		0x41954B, -- right run move
		0x419562, -- right turbo move
		0x419CCD, -- fall right move
		0x419D03 -- fall left move
	}
	if not PLAY.OriginalSpeedValues then
		PLAY.OriginalSpeedValues = {}
		for _, addr in ipairs(addresses) do
			local value = ffi.cast("int*", addr)[0]
			table.insert(PLAY.OriginalSpeedValues, value)
		end
	end
	for index, addr in ipairs(addresses) do
		local value = PLAY.OriginalSpeedValues[index]
		PrivateCast(math.round(mul*value), "int*", addr, 0)
	end
end

PLAY.MultClawClimbSpeed = function(mul)
	local addresses = {
		0x41D119, -- climb down
		0x41D12F, -- catnip climb down
		0x41D167, -- climb up
		0x41D17D -- catnip climb up
	}
	if not PLAY.OriginalClimbSpeedValues then
		PLAY.OriginalClimbSpeedValues = {}
		for _, addr in ipairs(addresses) do
			local value = ffi.cast("int*", addr)[0]
			table.insert(PLAY.OriginalClimbSpeedValues, value)
		end
	end
	for index, addr in ipairs(addresses) do
		local value = PLAY.OriginalClimbSpeedValues[index]
		PrivateCast(math.round(mul*value), "int*", addr, 0)
	end
end

return PLAY