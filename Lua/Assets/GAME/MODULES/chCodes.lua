local ccnopera = ffi.cast("char*", 0x41D4B6)
local ccnoperb = ffi.cast("char*", 0x41D4CB)
local kijan_mode = nil
local HD_mode = nil
local plasma_handler = nil
local InitCheatsOnce = false

local CODES = { }

CODES.CustomList = {}

CODES.List = {
	mparmor = {Name = "mparmor", ID = 0x8072, Type = 0}, -- exists in exe, but registered here
	
	mpzax = {
		Name = "mpzax",
		ID = 666, 
		Type = 1,
		Text = "Zax37 is programming god too!"
	},
	
	mpartur = {
		Name = "mpartur",
		ID = 667, 
		Type = 0,
		Toggle = 0,
		Text = "Artur mode",
		Enable = function()
			for i=2,5 do 
				ccnopera[i] = 0x00 
				ccnoperb[i] = 0x00 
			end
		end,
		Disable = function()
			for i=2,4 do 
				ccnopera[i] = 0xFF 
				ccnoperb[i] = 0xFF 
			end
			ccnopera[5] = 0xFD
			ccnoperb[5] = 0xFE
		end,
		MenuReset = true
	},
	
	mpfly = {
		Name = "mpfly",
		ID = 668, 
		Type = 0, 
		Text = "Fly mode",
		Toggle = 0,
		Enable = function()
			do -- disable bearhug
				PrivateCast(0xC3, "char*", 0x420FC0)
				PrivateCast(0xC3, "char*", 0x40AF50)
				PrivateCast(0xC3, "char*", 0x40ADE0)
				PrivateCast(0xC3, "char*", 0x4972A0)
				PrivateCast(0xC3, "char*", 0x497190)
			end
			local claw = GetClaw()
			claw.State = 5008
		    claw.DrawFlags.Invert = true
		    claw.HitTypeFlags = 0xB50500 -- claw invulnerable
		    claw:SetAnimation"GAME_NULL"
		    claw:SetFrame(401)
		    claw.PhysicsType = 8 -- claw won't interact with any tile
            claw.Flags.flags = OR(claw.Flags.flags,0x80)
		end,
		Disable = function()
			local claw = GetClaw()
			claw.DrawFlags.Invert = false
            if claw.Health > 0 then
	            claw.HitTypeFlags = 0x1B50544 -- claw not invulnerable
                claw.PhysicsType = 1
                ClawJump(0)
				do -- enable bearhug
					ffi.cast("char*", 0x420FC0)[0] = 0x55
					ffi.cast("char*", 0x40AF50)[0] = 0xA1
					ffi.cast("char*", 0x40ADE0)[0] = 0xA1
					ffi.cast("char*", 0x4972A0)[0] = 0xA1
					ffi.cast("char*", 0x497190)[0] = 0xA1
				end
            end
		end,
		Gameplay = function()
			local speed = GetInput"Jump" and 18 or 9
			local speedX, speedY = 0, 0
			local claw = GetClaw()
			if GetInput"Left" and not GetInput"Right" then 
			    PlayerData().Dir = 0 
			    claw.DrawFlags.Mirror = true
                speedX = -speed
		    end
		    if GetInput"Right" and not GetInput"Left" then 
			    PlayerData().Dir = 1 
			    claw.DrawFlags.Mirror = false 
                speedX = speed
		    end
            if not GetInput"Left" and not GetInput"Right" then
                speedX = 0
            end
		    if GetInput"Up" and not GetInput"Down" then 
                speedY = -speed
		    end
		    if GetInput"Down" and not GetInput"Up" then 
                speedY = speed
		    end
            if not GetInput"Up" and not GetInput"Down" then
                speedY = 0
            end
		    claw.X, claw.Y = claw.X + speedX, claw.Y + speedY
            if claw.HitTypeFlags ~= 0x50500 then
                claw.HitTypeFlags = 0x50500
            end
			if claw.PhysicsType ~= 8 then
				claw.PhysicsType = 8
			end
			if claw.State ~= 5008 then
				claw.State = 5008
			end
		end,
		LevelReset = function()
			CODES.List.mpfly.Toggle = 0
		end,
		ClawDeath = function()
			CODES.List.mpfly.Disable()
			CODES.List.mpfly.Toggle = 0
		end
	},
	
	mpkijan = {
		Name = "mpkijan",
		ID = 669, 
		Type = 1,
		Toggle = 0,
		Enable = function()
			TextOut("All hail the king!")
			kijan_mode = CreateObject {x=GetClaw().X, y=GetClaw().Y, z=0, logic="CustomLogic", name="_Disco"}
		end,
		Disable = function()
			TextOut("Thanks for WapMap!")
			kijan_mode:Destroy()
			kijan_mode = nil
		end,
		LevelReset = function()
			kijan_mode = nil
		end
	},
	
	mprects = {
		Name = "mprects",
		ID = 672,
		Type = 0,
		InfosFlags = "DebugRects",
		Text = "Rects display"
	},
	
	mpmoredi = {
		Name = "mpmoredi",
		ID = 673, 
		Type = 1,
		Enable = function()
			if InfosDisplay[0].DebugRects == true and InfosDisplay[0].DebugRectsPlus == false then 
				TextOut("Showing more debug info")
                InfosDisplay[0].DebugRectsPlus = true
			end
		end
	},
	
	mplessdi = {
		Name = "mplessdi",
		ID = 674, 
		Type = 1,
		Enable = function()
			if InfosDisplay[0].DebugRects == true and InfosDisplay[0].DebugRectsPlus == true then 
				TextOut("Showing less debug info")
                InfosDisplay[0].DebugRectsPlus = false
			end
		end
	},
	
	mptext = {
		Name = "mptext",
		ID = 771, 
		Type = 1,
		InfosFlags = "DebugText",
		Text = "Debug text"
	},
	
	mpspeedrun = {
		Name = "mpspeedrun",
		ID = 772, 
		Type = 1,
		InfosFlags = "LiveClock"
	},
	
	mpazzar = {
		Name = "mpazzar",
		ID = 773, 
		Type = 2,
		Toggle = 0,
		Text = "HD mode",
		Enable = function()
			HD_mode = CreateObject {name="_HD", Width = 864, Height = 486}
		end,
		Disable = function()
			HD_mode.State = 4
			HD_mode = nil
		end,
		LevelReset = function()
			HD_mode = nil
		end
	},
	
	mpbutter = {
		Name = "mpbutter",
		ID = 774, 
		Type = 0,
		Toggle = 0,
		Text = "No block mode",
		Enable = function()
			--RTP:
			--ffi.cast("char*", 0x486358)[0] = 8 -- 8 level number sword
			ffi.cast("char*", 0x48635D)[0] = 0 -- 25 sword
			--ffi.cast("char*", 0x48636F)[0] = 8 -- 8 level number shot
			ffi.cast("char*", 0x486378)[0] = 0 -- 25 shot
			ffi.cast("char*", 0x48638B)[0] = 0 -- 50 lvl13 sword
			ffi.cast("char*", 0x48641B)[0] = 0 -- 75 lvl13 shot
			--TG:
			--ffi.cast("char*", 0x49B438)[0] = 6 -- 6 level number sword
			ffi.cast("char*", 0x49B451)[0] = 0 -- 25 lvl6 sword
			--TG2:
			--ffi.cast("char*", 0x49B5D6)[0] = 5 -- level number sword
			ffi.cast("char*", 0x49B5E8)[0] = 0 -- 25 lvl5 sword
			ffi.cast("char*", 0x49B607)[0] = 0 -- 50 lvl6 sword
			--CH:
			ffi.cast("char*", 0x436B5A)[0] = 15 -- 9 level number sword
			--Mercat:
			ffi.cast("char*", 0x4630D1)[0] = 8 -- 5 physics type sword
			--ffi.cast("char*", 0x462F67)[0] = 11 -- level number shot
			ffi.cast("char*", 0x462F6C)[0] = 0 -- 25 lvl11 shot
			ffi.cast("char*", 0x462FAD)[0] = 0 -- 50 lvl12 shot
			-- Pistol:
			ffi.cast("char*", 0x43FA32)[0] = 0x50
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
		end,
		MenuReset = true
	},
	
	mpboris = {
		Name = "mpboris",
		ID = 775, 
		Type = 0,
		Toggle = 0,
		Text = "Boris mode",
		Gameplay = function()
			LoopThroughObjects(function(obj)
				local claw = GetClaw()
				local dMax = 240
				local limit = 200
				local dMaxSq = dMax*dMax
				local magnetF = 540000
				if obj.ObjectTypeFlags == 0x40000 then
					local d = math.sqrt(math.abs(GetClaw().X - obj.X)^2 + math.abs(GetClaw().Y - obj.Y)^2)
					if d < limit then
						if obj.Logic == TreasurePowerup or obj.Logic == GlitterlessPowerup then
							local dx = (GetClaw().X - obj.X)/d
							local dy = (GetClaw().Y - obj.Y)/d
							obj.X, obj.Y = math.ceil(obj.X + magnetF*dx/dMaxSq), math.ceil(obj.Y + magnetF*dy/dMaxSq)
							if tonumber(ffi.cast("int", obj.GlitterPointer)) ~= 0 then
								obj.GlitterPointer.X, obj.GlitterPointer.Y = obj.X, obj.Y
							end
							if obj.State > 5 then
								obj.DrawFlags.NoDraw = true
							end
						end
						if obj.Logic == BouncingGoodie then
							obj.PhysicsType = 1
						end
					end
				end
			end)
		end
	},
	
	mppappy = {
		Name = "mppappy",
		ID = 776, 
		Type = 0,
		Toggle = 0,
		Text = "Running mode",
		Enable = function()
			SetRunningSpeedTime(0)
		end,
		Disable = function()
			SetRunningSpeedTime(1500)
		end,
		MenuReset = true    
	},
	
	mppejti = {
		Name = "mppejti",
		ID = 777, 
		Type = 0,
		Init = function()
            plasma_handler = CreateObject {name="_PlasmaSwordPower", ID=2000000001}
		end,
		Enable = function()
		    TextOut("Plasma sword rules...")
            ClawGivePowerup(Powerup.PlasmaSword, 20)
		end,
		LevelReset = function()
			plasma_handler = nil
		end
	},
	
	mpwisztom = {
		Name = "mpwisztom",
		ID = 778, 
		Type = 0,
		Enable = function()
		    TextOut("Respawn point set")
            SetRespawnPoint(GetClaw().X, GetClaw().Y)
		end
	},
	
	mpthanos = {
		Name = "mpthanos",
		ID = 779, 
		Type = 2,
		Text = "Health bars display",
		InfosFlags = "HealthBars",
		LevelReset = function()
			InfosDisplay[0].HealthBars = false
		end
	},
	
	mpgonzalo = {
		Name = "mpgonzalo",
		ID = 780, 
		Type = 1,
		Toggle = 0,
		Text = "One HP mode",
		Enable = function()
			for i = 5,8 do
                mdl_exe.Pickups[i] = 0 -- food and health potions hp restore value
            end
			ffi.cast("int*", 0x42ABD5)[0] = 1 -- MPAPPLE hp restore cap
            ffi.cast("int*", 0x4940BF)[0] = 50000000 -- value for the next extra live
		end,
		Disable = function()
			mdl_exe.Pickups[5] = 5
			mdl_exe.Pickups[6] = 25
			mdl_exe.Pickups[7] = 10
			mdl_exe.Pickups[8] = 15
			ffi.cast("int*", 0x42ABD5)[0] = 100
			ffi.cast("int*", 0x4940BF)[0] = 500000
		end,
		Gameplay = function()
			if mdl_exe.Cheats[0] ~= 0 then -- turn off if mpkfa
                CODES.List.mpgonzalo.Disable()
                CODES.List.mpgonzalo.Toggle = 0
            end
            if GetClaw().Health > 1 or PData().Lives > 1 then
                GetClaw().Health = 1
                PData().Lives = 1
            end
		end,
		MenuReset = true
	},
	
	mpalice = {
		Name = "mpalice",
		ID = 781, 
		Type = 1,
		Toggle = 0,
		Enable = function()
			TextOut("Not all who wander are lost")
			local pal = GetCurrentPalette()
			pal[0] = "#505050"
			pal:AdjustHSL(math.random(30,329), 0, 0):Set()
		end,
		Disable = function()
			GetFirstPalette():Set()
		end
	}
	
}

CODES.MenuReset = function()
	for name, params in pairs(CODES.CustomList) do
		if CODES.List[params.Name] then
			CODES.List[params.Name] = nil
			CODES.CustomList[params.Name] = nil
		end
	end
	for _, params in pairs(CODES.List) do
		if params.MenuReset then
			if type(params.MenuReset) == "function" then
				params.MenuReset()
			else
				if type(params.Disable) == "function" then
					params.Disable()
				end
			end
		end
		if params.Toggle then
			params.Toggle = 0
		end
	end
end

CODES.Activation = function(id)
	for _, params in pairs(CODES.List) do
		if params.ID == id then
		
			if params.Type == 0 then
				PlaySound"GAME_MAJORCHEAT"
			elseif params.Type == 1 then
				PlaySound"GAME_MINORCHEAT"
			elseif params.Type == 2 then
				if _mappath == "" then
					PlaySound"GAME_MAJORCHEAT"
					snRes(1,18,74)
				else
					PlaySound"GAME_MINORCHEAT"
				end
			end
			
			if params.Toggle then
				if params.Toggle == 0 then
					if type(params.Enable) == "function" then
						params.Enable()
					end
					if params.Text then
						TextOut(params.Text .. " On")
					end
					params.Toggle = 1
				else
					if type(params.Disable) == "function" then
						params.Disable()
					end
					if params.Text then
						TextOut(params.Text .. " Off")
					end
					params.Toggle = 0
				end
				
			elseif params.InfosFlags then
				if InfosDisplay[0][params.InfosFlags] == false then
					if type(params.Enable) == "function" then
						params.Enable()
					end
					if params.Text then
						TextOut(params.Text .. " On")
					end
					InfosDisplay[0][params.InfosFlags] = true
				else
					if type(params.Disable) == "function" then
						params.Disable()
					end
					if params.Text then
						TextOut(params.Text .. " Off")
					end
					InfosDisplay[0][params.InfosFlags] = false
				end
				
			else
				if type(params.Enable) == "function" then
					params.Enable()
				end
				if params.Text then
					TextOut(params.Text)
				end
			end

		elseif id == _message.Teleport then
			if type(params.Teleport) == "function" then
				params.Teleport()
			end
		elseif id == _message.ClawDeath then
			if type(params.ClawDeath) == "function" then
				params.ClawDeath()
			end
		end
	end
end

CODES.RegisterSingleCheat = function(name, id, save)
	if save == 2 then save = 1 end
	mdl_exe._RegisterCheat(nRes(18), CODES.EncodeCode(name), id, save)
end

CODES.RegisterCustomCheat = function(params)
	if type(params) == "table" then
		assert(type(params.ID) == "number", "RegisterCheat - ID must be an integer")
		assert(type(params.Name) == "string", "RegisterCheat - Name must be a string")
		params.Name = params.Name:lower()
		params.Type = params.Type or 0 
		for _, d in pairs(CODES.List) do
			if d.ID == params.ID then
				error("RegisterCheat - ID " .. params.ID .. " is already taken by " .. d.Name:upper())
			end
		end
		if CODES.List[params.Name] then
			error("RegisterCheat - Name '" .. params.Name .. "' is already taken!")
		end
		for k, v in pairs(_message) do
			if params.ID == v then
				error("RegisterCheat - ID " .. params.ID .. " is taken by " .. k)
			end
		end
		CODES.RegisterSingleCheat(params.Name, params.ID, params.Type)
		CODES.List[params.Name] = params
		CODES.CustomList[params.Name] = params
	else
		error("RegisterCheat - argument must be a table")
	end
end

CODES.EncodeCode = function(str)
	local encoded = ""
	for i=1,#str do
		encoded = encoded..string.char(string.byte(string.sub(str,i,i))-15)
	end
	return encoded
end

CODES.Registration = function(ptr)
	for _, params in pairs(CODES.List) do
		CODES.RegisterSingleCheat(params.Name, params.ID, params.Type)
		if type(params.LevelReset) == "function" then
			params.LevelReset()
		end
	end
end

CODES.Init = function()
	for _, params in pairs(CODES.List) do
		if type(params.Init) == "function" then
			params.Init()
		end
	end
end

CODES.Gameplay = function()
	for _, params in pairs(CODES.List) do
		if params.Toggle == 1 and type(params.Gameplay) == "function" then
			params.Gameplay()
		end
	end
	
end

return CODES
