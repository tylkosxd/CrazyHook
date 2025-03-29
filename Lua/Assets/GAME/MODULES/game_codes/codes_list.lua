--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ Crazy cheats module ]] -----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
-- This module contains two lists: CNEW with new cheats and CORG with pre-CrazyHook cheats. The lists are mapped in the codes_main.lua

local CNEW, CORG = {}, {}

CNEW.MPZAX = {
	Name = "mpzax",
	ID = 0x1000,
	Type = 1,
	Text = "Zax37 is a programming god too!"
}

CNEW.MPARTUR = {
	Name = "mpartur",
	ID = 0x1001,
	Type = 0,
	Toggle = 0,
	Text = "Artur mode",
	Enable = function()
		CNEW.MPNDJ.Toggle = 0
		CNEW.MPNDJ.Disable()
		ffi.cast("unsigned int*", 0x41D4B8)[0] = 0
		ffi.cast("unsigned int*", 0x41D4CD)[0] = 0
	end,
	Disable = function()
		ffi.cast("unsigned int*", 0x41D4B8)[0] = 0xFDFFFFFF
		ffi.cast("unsigned int*", 0x41D4CD)[0] = 0xFEFFFFFF
	end,
	MenuReset = true
}

CNEW.MPFLY = {
	Name = "mpfly",
	ID = 0x1002,
	Type = 0,
	Text = "Fly mode",
	Toggle = 0,
	Enable = function()
		if GetClaw().Health > 0 then
			-- disable bearhug
			PrivateCast(0xC3, "char*", 0x420FC0)
			PrivateCast(0xC3, "char*", 0x40AF50)
			PrivateCast(0xC3, "char*", 0x40ADE0)
			PrivateCast(0xC3, "char*", 0x4972A0)
			PrivateCast(0xC3, "char*", 0x497190)
			local claw = GetClaw()
			claw.State = ClawStates.Bearhug
			claw.DrawFlags.Invert = true
			claw:SetAnimation"GAME_NULL"
			claw:SetFrame(401)
			claw.PhysicsType = PhysicsTypes.Fly
			claw.Flags.flags = OR(claw.Flags.flags, 0x80)
		end
	end,
	Disable = function()
		local claw = GetClaw()
		claw.DrawFlags.Invert = false
		if _CurrentPowerup[0] ~= Powerup.Vader then
			claw.HitTypeFlags = 0x1B50544 -- claw not invulnerable
		end
		if claw.Health > 0 then
			claw.PhysicsType = 1
			ClawJump(0)
			-- enable bearhug:
			ffi.cast("char*", 0x420FC0)[0] = 0x55
			ffi.cast("char*", 0x40AF50)[0] = 0xA1
			ffi.cast("char*", 0x40ADE0)[0] = 0xA1
			ffi.cast("char*", 0x4972A0)[0] = 0xA1
			ffi.cast("char*", 0x497190)[0] = 0xA1
		end
	end,
	Gameplay = function()
		local claw = GetClaw()
		if claw.Health <= 0 then
			CNEW.MPFLY.Disable()
			CNEW.MPFLY.Toggle = 0
			return
		end
		local getInput = GetInput
		local input = InputFlags
		local pdata = claw._p
		local speed = getInput(input.Jump) and 18 or 9
		local speedX, speedY = 0, 0
		if getInput(input.Left) and not getInput(input.Right) then
			pdata.Dir = 0
			claw.DrawFlags.Mirror = true
			speedX = -speed
		end
		if getInput(input.Right) and not getInput(input.Left) then
			pdata.Dir = 1
			claw.DrawFlags.Mirror = false
			speedX = speed
		end
		if not getInput(input.Left) and not getInput(input.Right) then
			speedX = 0
		end
		if getInput(input.Up) and not getInput(input.Down) then
			speedY = -speed
		end
		if getInput(input.Down) and not getInput(input.Up) then
			speedY = speed
		end
		if not getInput(input.Up) and not getInput(input.Down) then
			speedY = 0
		end
		claw.X, claw.Y = claw.X + speedX, claw.Y + speedY
		claw.HitTypeFlags = 0xB50500 -- makes claw invulnerable
		claw.PhysicsType = PhysicsTypes.Fly
		claw.State = ClawStates.Bearhug
	end,
	LevelReset = function()
		CNEW.MPFLY.Toggle = 0
	end,
	ClawDeath = function()
		CNEW.MPFLY.Disable()
		CNEW.MPFLY.Toggle = 0
	end
}

CNEW.MPKIJAN = {
	Name = "mpkijan",
	ID = 0x1003,
	Type = 1,
	Toggle = 0,
	Object = nil,
	Init = function()
		if CNEW.MPKIJAN.Toggle == 1 then
			CNEW.MPKIJAN.Object = CreateObject{name="_Disco"}
		end
	end,
	Enable = function()
		TextOut("All hail the king!")
		CNEW.MPKIJAN.Object = CreateObject{name="_Disco"}
	end,
	Disable = function()
		TextOut("Thanks for WapMap!")
		if CNEW.MPKIJAN.Object ~= nil then
			CNEW.MPKIJAN.Object:Destroy()
			CNEW.MPKIJAN.Object = nil
		end
	end,
	LevelReset = function()
		CNEW.MPKIJAN.Object = nil
	end
}

CNEW.MPRECTS = {
	Name = "mprects",
	ID = 0x1004,
	Type = 0,
	Toggle = 0,
	InfosFlags = "DebugRects",
	Text = "Rects display"
}

CNEW.MPMOREDI = {
	Name = "mpmoredi",
	ID = 0x1005,
	Type = 3,
	Toggle = 0,
	Enable = function()
		if InfosDisplay[0].DebugRects == true then
			TextOut"More debug info"
			PlaySound"GAME_MINORCHEAT"
			InfosDisplay[0].DebugRectsPlus = true
		else
			CNEW.MPMOREDI.Toggle = 0
		end
	end,
	Disable = function()
		if InfosDisplay[0].DebugRects == true then
			TextOut"Less debug info"
			PlaySound"GAME_MINORCHEAT"
			InfosDisplay[0].DebugRectsPlus = false
		end
	end,
	LevelReset = function()
		InfosDisplay[0].DebugRectsPlus = false
		CNEW.MPMOREDI.Toggle = 0
	end
}

CNEW.MPTEXT = {
	Name = "mptext",
	ID = 0x1006,
	Type = 1,
	Toggle = 0,
	InfosFlags = "DebugText",
	Text = "Debug text"
}

CNEW.MPSPEEDRUN = {
	Name = "mpspeedrun",
	ID = 0x1007,
	Type = 1,
	Toggle = 0,
	InfosFlags = "RealStopwatch"
}

CNEW.MPAZZAR = {
	Name = "mpazzar",
	ID = 0x1008,
	Type = 2,
	Toggle = 0,
	Text = "HD Mode",
	Object = nil,
	Enable = function()
		CNEW.MPAZZAR.Object = CreateObject{name="_HD", Width = 864, Height = 486}
	end,
	Disable = function()
		if CNEW.MPAZZAR.Object ~= nil then
			CNEW.MPAZZAR.Object.State = 4
			CNEW.MPAZZAR.Object = nil
		end
	end,
	LevelReset = function()
		CNEW.MPAZZAR.Object = nil
	end
}

CNEW.MPBUTTER = {
	Name = "mpbutter",
	ID = 0x1009,
	Type = 0,
	Toggle = 0,
	Text = "No Block Mode",
	Enable = function()
		--Redtail's pirate:
		--ffi.cast("char*", 0x486358)[0] = 8 -- 8 level number sword
		ffi.cast("char*", 0x48635D)[0] = 0 -- 25 sword
		--ffi.cast("char*", 0x48636F)[0] = 8 -- 8 level number shot
		ffi.cast("char*", 0x486378)[0] = 0 -- 25 shot
		ffi.cast("char*", 0x48638B)[0] = 0 -- 50 lvl13 sword
		ffi.cast("char*", 0x48641B)[0] = 0 -- 75 lvl13 shot
		--Town guard:
		--ffi.cast("char*", 0x49B438)[0] = 6 -- 6 level number sword
		ffi.cast("char*", 0x49B451)[0] = 0 -- 25 lvl6 sword
		--Town guard 2:
		--ffi.cast("char*", 0x49B5D6)[0] = 5 -- level number sword
		ffi.cast("char*", 0x49B5E8)[0] = 0 -- 25 lvl5 sword
		ffi.cast("char*", 0x49B607)[0] = 0 -- 50 lvl6 sword
		--Crazy hook:
		ffi.cast("char*", 0x436B5A)[0] = 15 -- 9 level number sword
		--Mercat:
		ffi.cast("char*", 0x4630D1)[0] = 8 -- 5 physics type sword
		--ffi.cast("char*", 0x462F67)[0] = 11 -- level number shot
		ffi.cast("char*", 0x462F6C)[0] = 0 -- 25 lvl11 shot
		ffi.cast("char*", 0x462FAD)[0] = 0 -- 50 lvl12 shot
		-- Pistol will work like magic:
		ffi.cast("char*", 0x43FA32)[0] = 0x50
		-- Crabs (it won't check crab's animation frame):
		ffi.cast("char*", 0x44D31C)[0] = 0xE9 -- jump
		ffi.cast("int*", 0x44D31D)[0] = 0xBB
		-- Raux:
		ffi.cast("short*", 0x4818B8)[0] = 0x1CEB
		-- Kath:
		ffi.cast("short*", 0x456208)[0] = 0x3BEB
		-- Marrow:
		ffi.cast("short*", 0x45BDAF)[0] = 0x13EB
		-- Red Tail:
		ffi.cast("short*", 0x484CC0)[0] = 0x2EEB
	end,
	Disable = function()
		ffi.cast("char*", 0x48635D)[0] = 25
		ffi.cast("char*", 0x486378)[0] = 25
		ffi.cast("char*", 0x48638B)[0] = 50
		ffi.cast("char*", 0x48641B)[0] = 75
		ffi.cast("char*", 0x49B451)[0] = 25
		ffi.cast("char*", 0x49B5E8)[0] = 25
		ffi.cast("char*", 0x49B607)[0] = 50
		ffi.cast("char*", 0x436B5A)[0] = 9
		ffi.cast("char*", 0x4630D1)[0] = 5
		ffi.cast("char*", 0x462F6C)[0] = 25
		ffi.cast("char*", 0x462FAD)[0] = 50
		ffi.cast("char*", 0x43FA32)[0] = 0x4C
		local crabs = ffi.cast("char*", 0x44D31C)
		crabs[0] = 0x8B crabs[1] = 0x82 crabs[2] = 0x90 crabs[3] = 1 crabs[4] = 0
		ffi.cast("short*", 0x4818B8)[0] = 0x868B
		ffi.cast("short*", 0x456208)[0] = 0x868B
		ffi.cast("short*", 0x45BDAF)[0] = 0x868B
		ffi.cast("short*", 0x484CC0)[0] = 0x918B
	end,
	MenuReset = true
}

CNEW.MPBORIS = {
	Name = "mpboris",
	ID = 0x1010,
	Type = 0,
	Toggle = 0,
	Text = "Boris Mode",
	Attract = function(obj, distance)
		if obj.State == 5 and (obj.Logic == TreasurePowerup or obj.Logic == GlitterlessPowerup) then
			local dx = (GetClaw().X - obj.X)/distance
			local dy = (GetClaw().Y - obj.Y)/distance
			obj.X = obj.X + 9*dx
			obj.Y = obj.Y + 9*dy
			if obj.GlitterPointer ~= nil then
				obj.GlitterPointer.X, obj.GlitterPointer.Y = obj.X, obj.Y
			end
		end
		if obj.Logic == BouncingGoodie then
			obj.PhysicsType = 1
		end
	end,
	Magnet = function(object)
		local limitSquare = 50000
		if object.ObjectTypeFlags == 0x40000 then -- also correct as 'if object.BumpFlags.Treasure == true then'
			local distanceSquare = (GetClaw().X - object.X)^2 + (GetClaw().Y - object.Y)^2
			if distanceSquare < limitSquare then
				CNEW.MPBORIS.Attract(object, math.sqrt(distanceSquare))
			end
		end
	end,
	Gameplay = function()
		LoopThroughObjects(CNEW.MPBORIS.Magnet)
	end
}

CNEW.MPPAPPY = {
	Name = "mppappy",
	ID = 0x1011,
	Type = 0,
	Toggle = 0,
	Text = "Pappy Mode",
	Enable = function()
		SetRunningSpeedTime(0)
		PData().RunningSpeedTime = 0
	end,
	Disable = function()
		SetRunningSpeedTime(1500)
	end,
	MenuReset = true
}

CNEW.MPPEJTI = {
	Name = "mppejti",
	ID = 0x1012,
	Type = 0,
	Enable = function()
		TextOut("Plasma sword rules...")
		ClawGivePowerup(Powerup.PlasmaSword, 20)
	end
}

CNEW.MPWISZTOM = {
	Name = "mpwisztom",
	ID = 0x1013,
	Type = 0,
	Enable = function()
		TextOut("Respawn point set")
		SetRespawnPoint(GetClaw().X, GetClaw().Y)
	end
}

CNEW.MPTHANOS = {
	Name = "mpthanos",
	ID = 0x1014,
	Type = 2,
	Text = "Health Bars Display",
	Toggle = 0,
	InfosFlags = "HealthBars"
}

CNEW.MPGONZALO = {
	Name = "mpgonzalo",
	ID = 0x1015,
	Type = 1,
	Toggle = 0,
	Text = "One HP Mode",
	Enable = function()
		local pickups = BasePickupsVals()
		pickups.Food = 0
		pickups.BigPotion = 0
		pickups.SmallPotion = 0
		pickups.MediumPotion = 0
		ffi.cast("int*", 0x42ABD5)[0] = 1 -- MPAPPLE hp restore cap
		ffi.cast("int*", 0x4940BF)[0] = 50000000 -- value for the next extra live
	end,
	Disable = function()
		local pickups = BasePickupsVals()
		pickups.Food = 5
		pickups.BigPotion = 25
		pickups.SmallPotion = 10
		pickups.MediumPotion = 15
		ffi.cast("int*", 0x42ABD5)[0] = 100
		ffi.cast("int*", 0x4940BF)[0] = 500000
	end,
	Gameplay = function()
		if mdl_exe.Cheats[0] ~= 0 then -- turn off if mpkfa
			CNEW.MPGONZALO.Disable()
			CNEW.MPGONZALO.Toggle = 0
		end
		if GetClaw().Health > 1 then
			GetClaw().Health = 1
		end
		if PlayerData().Lives > 1 then
			PlayerData().Lives = 1
		end
	end,
	MenuReset = true
}

CNEW.MPALICE = {
	Name = "mpalice",
	ID = 0x1016,
	Type = 1,
	Toggle = 0,
	Init = function()
		CNEW.MPALICE.LastPal = GetFirstPalette()
		CORG.MPGLOOMY.LastPal = GetFirstPalette()
		if CNEW.MPALICE.Toggle == 1 then
			local src, dst = GetFirstPalette():AdjustHSL(math.random(30,329), 0, 0), nRes(11)+0x360
			dst, src = ffi.cast("int*", dst), ffi.cast("int*", src)
			for x = 0, 255 do
				dst[x] = src[x]
			end
		end
	end,
	Enable = function()
		TextOut("Not all who wander are lost")
		local pal;
		if CORG.MPGLOOMY.Toggle == 1 then
			CNEW.MPALICE.LastPal = CORG.MPGLOOMY.LastPal:Copy()
			pal = CORG.MPGLOOMY.LastPal:Copy()
			CORG.MPGLOOMY.Toggle = 0
		else
			pal = GetCurrentPalette()
			CNEW.MPALICE.LastPal = GetCurrentPalette()
		end
		pal:AdjustHSL(math.random(30,329), 0, 0):Set(true)
	end,
	Disable = function()
		CNEW.MPALICE.LastPal:Set()
	end
}

CNEW.MPNDJ = {
	Name = "mpndj",
	ID = 0x1017,
	Type = 1,
	Toggle = 0,
	Text = "No Double Jump Mode",
	Enable = function()
		CNEW.MPARTUR.Toggle = 0
		CNEW.MPARTUR.Disable()
		ffi.cast("char*", 0x4384BC)[0] = 2 -- see CrazyPatches.lua - "Double jump fix"
	end,
	Disable = function()
		ffi.cast("char*", 0x4384BC)[0] = 16
	end,
	MenuReset = true
}

CNEW.MPSIMPSON = {
	Name = "mpsimpson",
	ID = 0x1018,
	Type = 0,
	Text = "Double Jump Feedback display",
	Toggle = 0,
	InfosFlags = "JumpSignal"
}

CNEW.MPTILES = {
	Name = "mptiles",
	ID = 0x1019,
	Type = 0,
	Toggle = 0,
	InfosFlags = "DebugTiles",
	Text = "Debug Tiles"
}

--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Original cheats ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

ffi.cast("short*", 0x42BC30)[0] = 0x0DEB -- skip BnW function on MPGLOOMY
ffi.cast("char*", 0x423F9F)[0] = 1 -- register MPCULTIST as a minor cheat
ffi.cast("int*", 0x42B80A)[0] = 0x523FA8 -- play GAME_MINORCHEAT for MPCULTIST

CORG.MPCULTIST = {
	Toggle = 0,
	Enable = function()
		local factor = 5
		local addr = {
			0x48ED0A,
			0x43A2BA,
			0x48928A,
			0x4A4947,
			0x433BEB,
			0x4474FF,
			0x46BD2A,
			0x45C1CA,
			0x463516,
			0x483D0A,
			0x483527,
			0x46723B,
			0x415B4F,
			0x4964B1
		}
		for _, a in ipairs(addr) do
			ffi.cast("int*", a)[0] = ffi.cast("int*", a)[0]*factor
		end
	end,
	Disable = function()
		ffi.cast("int*", 0x48ED0A)[0] = 10 -- Soldier bullet damage
		--ffi.cast("int*", 0x4803B8)[0] = 15 -- Rat bomb damage
		ffi.cast("int*", 0x43A2BA)[0] = 10 -- CutThroat knife damage
		ffi.cast("int*", 0x48928A)[0] = 10 -- RobberThief arrow damage
		ffi.cast("int*", 0x4A4947)[0] = 5 -- Wolvington magic damage
		ffi.cast("int*", 0x433BEB)[0] = 5 -- Crab bomb damage
		ffi.cast("int*", 0x4474FF)[0] = 5 -- Gabriel bomb damage
		ffi.cast("int*", 0x46BD2A)[0] = 10 -- PegLeg bullet damage
		ffi.cast("int*", 0x45C1CA)[0] = 20 -- Marrow bullet damage
		ffi.cast("int*", 0x463516)[0] = 20 -- Mercat trident damage
		ffi.cast("int*", 0x483D0A)[0] = 15 -- RedTail bullet damage
		ffi.cast("int*", 0x483527)[0] = 5 -- RedTail knife damage
		ffi.cast("int*", 0x46723B)[0] = 15 -- Omar magic damage
		ffi.cast("int*", 0x415B4F)[0] = 10 -- Cannonball damage
		--ffi.cast("int*", 0x458DAA)[0] = 10 -- LavaHand bomb damage
		ffi.cast("int*", 0x4964B1)[0] = 5 -- Tentacle damage
	end,
	MenuReset = function()
		ffi.cast("int*", 0x5359A0)[0] = 0 -- built-in toggle
		CORG.MPCULTIST.Disable()
	end,
	CarryOver = function()
		mdl_exe.DamageFactor[0] = 5
		mdl_exe.HealthFactor[0] = 5
		mdl_exe.SmartsFactor[0] = 5
	end
}

CORG.MPWILDWACKY = {
	Toggle = 0,
	CarryOver = function()
		GetClaw().DrawFlags.Invert = true
	end
}

CORG.MPSHADOW = {
	Toggle = 0,
	Enable = function()
		CORG.MPSPOOKY.Toggle = 0
		ffi.cast("char*", 0x420E1D)[0] = 3 -- coming back from invisibility/invulnerability
	end,
	Disable = function()
		ffi.cast("char*", 0x420E1D)[0] = 1
	end,
	MenuReset = function()
		CORG.MPSHADOW.Disable()
	end,
	CarryOver = function()
		SetImgFlag(GetClaw().Image, ImageFlag.Shadow)
	end
}

CORG.MPSPOOKY = {
	Toggle = 0,
	Enable = function()
		CORG.MPSHADOW.Toggle = 0
		ffi.cast("char*", 0x420E1D)[0] = 2 -- coming back from invisibility/invulnerability
	end,
	Disable = function()
		ffi.cast("char*", 0x420E1D)[0] = 1
	end,
	MenuReset = function()
		CORG.MPSPOOKY.Disable()
	end,
	CarryOver = function()
		SetImgFlag(GetClaw().Image, ImageFlag.Ghost)
	end
}

CORG.MPGLOOMY = {
	Toggle = 0,
	Enable = function()
		local pal;
		if CNEW.MPALICE.Toggle == 1 then
			CNEW.MPALICE.Toggle = 0
			CORG.MPGLOOMY.LastPal = CNEW.MPALICE.LastPal:Copy()
			pal = CNEW.MPALICE.LastPal:Copy()
		else
			CORG.MPGLOOMY.LastPal = GetCurrentPalette()
			pal = GetCurrentPalette()
		end
		pal:BlackAndWhite():Set(true)
	end,
	Disable = function()
		CORG.MPGLOOMY.LastPal:Set()
	end,
	CarryOver = function()
		local src, dst = GetFirstPalette():BlackAndWhite(), nRes(11)+0x360
		dst, src = ffi.cast("int*", dst), ffi.cast("int*", src)
		for x = 0, 255 do
			dst[x] = src[x]
		end
	end
}

CORG.MPHAUNTED = {
	Toggle = 0,
	Enable = function()
		TextOut"This place is haunted!"
		PlaySound"GAME_MINORCHEAT"
	end,
	Disable = function()
		TextOut"Nothing to be scared about anymore!"
		PlaySound"GAME_MINORCHEAT"
	end,
	CarryOver = function()
		mdl_exe._Haunted(nRes())
	end
}

return {CNEW = CNEW, CORG = CORG}