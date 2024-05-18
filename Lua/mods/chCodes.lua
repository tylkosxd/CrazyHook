
local _cheats_list = {
	mparmor         = {0x8072, 0}, -- implemented in exe
	mpzax           = {666, 1},
	mpartur         = {667, 0},
	mpfly           = {668, 0},
	mpkijan         = {669, 1},
	mprects         = {672, 1},
	mpmoredi        = {673, 1},
	mplessdi        = {674, 1},
	mptext          = {771, 1},
    mpspeedrun      = {772, 1},
    mpazzar         = {773, 0},
    mpbutter        = {774, 0},
    mpboris         = {775, 0}
	-- Add your own code here
	-- name = {id, 1|0 (minor|major cheatcode)}
	}

local function _ArturOff()
    artur_mode = false
    local ccnopera = ffi.cast("char*",0x41D4B6)
    local ccnoperb = ffi.cast("char*",0x41D4CB)
    for i=2,4 do 
		ccnopera[i] = 0xFF 
		ccnoperb[i] = 0xFF 
	end
	ccnopera[5] = 0xFD
	ccnoperb[5] = 0xFE
end

local function _NoBlockOff()
    noblock_mode = false
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
end

local _codes = {}

_codes.CrazyCheats = function(ptr)
	
	if _chameleon[0] == chamStates.LoadingStart then

        _NoBlockOff()
        _ArturOff()
        kijan_mode = false
        fly_grab = nil
        azzar_mode = false
        treasure_magnet = nil

		-- Add here if your code should reset on the start of another game
		
		for name, params in pairs(_cheats_list) do
			_codes.RegisterCheat(name, params[1], params[2])
		end

    elseif _chameleon[0] == chamStates.LoadingObjects then
        if not fly_grab then
            fly_grab = CreateObject {name="_FlyGrab"}
        end
        if not treasure_magnet then
            treasure_magnet = CreateObject {name="_TreasureMagnet"}
        end
		
	elseif _chameleon[0] == chamStates.OnPostMessageA then
		local id = tonumber(ffi.cast("int",ptr))
		
		--[[ MPZAX ]]--
		if id == 666 then
			TextOut("Zax37 is programming God too!")
			PlaySound("GAME_MINORCHEAT")
		
		-- Add here what your code will do:
		-- elseif id == "id" then

        elseif id == 775 then
            PlaySound("GAME_MAJORCHEAT")
            if treasure_magnet.State < 2000 then
                TextOut("Boris Mode On")
                treasure_magnet.State = 2000
            else
                TextOut("Boris Mode Off")
                treasure_magnet.State = 3000
            end

        elseif id == 774 then
            PlaySound("GAME_MAJORCHEAT")
            if not noblock_mode then
               TextOut("No block mode On") 
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
                noblock_mode = true
            else
                TextOut("No block mode Off")
                _NoBlockOff()
                noblock_mode = false
            end
		
		--[[ MPARTUR ]]--
		elseif id == 667 then
			PlaySound("GAME_MAJORCHEAT")
			local ccnopera = ffi.cast("char*",0x41D4B6)
			local ccnoperb = ffi.cast("char*",0x41D4CB)
			if not artur_mode then
				TextOut("Artur Mode On")
				for i=2,5 do 
					ccnopera[i] = 0x00 
					ccnoperb[i] = 0x00 
				end
				artur_mode = true
			else
				TextOut("Artur Mode Off")
				_ArturOff()
				artur_mode = false
			end
			
		--[[ MPFLY ]]--
		elseif id == 668 and GetClaw().Health >= 0 then
			PlaySound("GAME_MAJORCHEAT")
			if fly_grab.State < 2000 then
				TextOut("Fly Mode On")
				fly_grab.State = 2000
			elseif fly_grab.State ~= 3000 then
				TextOut("Fly Mode Off")
                fly_grab.State = 3000
			end
			
		--[[ MPKIJAN ]]--	
		elseif id == 669 then
			PlaySound("GAME_MINORCHEAT")
			if not kijan_mode then
				TextOut("All hail the king!")
				kijan_mode = CreateObject {x=GetClaw().X, y=GetClaw().Y, z=0, logic="CustomLogic", name="_Disco"}
			else
				TextOut("Thanks for WapMap!")
				kijan_mode:Destroy()
				kijan_mode = false
			end
			
		-- Teleport:
		elseif id == _message.Teleport then
			if fly_grab then
				fly_grab.X, fly_grab.Y = _TeleportX[0], _TeleportY[0]
			end
			
		-- Claw's death:	
		--elseif id == _message.ClawDeath then
			
		--[[ MPRECTS ]]--	
		elseif id == 672 then
			PlaySound("GAME_MINORCHEAT")
			if InfosDisplay[0].DebugRects == true then 
				TextOut("Rects display Off")
                InfosDisplay[0].DebugRects = false
			else 
				TextOut("Rects display On") 
                InfosDisplay[0].DebugRects = true
			end
			
		--[[ MPMOREDI ]]--	
		elseif id == 673 then
			if InfosDisplay[0].DebugRects == true and InfosDisplay[0].DebugRectsPlus == false then 
				TextOut("Showing more debug info") 
                PlaySound("GAME_MINORCHEAT")
                InfosDisplay[0].DebugRectsPlus = true
			end
		
		--[[ MPLESSDI ]]--
		elseif id == 674 then
			if InfosDisplay[0].DebugRects == true and InfosDisplay[0].DebugRectsPlus == true then 
				TextOut("Showing less debug info") 
                PlaySound("GAME_MINORCHEAT")
                InfosDisplay[0].DebugRectsPlus = false
			end
		
		--[[ MPTEXT ]]--
		elseif id == 771 then
			PlaySound("GAME_MINORCHEAT")
			if InfosDisplay[0].DebugText == true then 
				TextOut("Debug text Off")
                InfosDisplay[0].DebugText = false
			else 
				TextOut("Debug text On") 
                InfosDisplay[0].DebugText = true
			end

        -- [[ MPSPEEDRUN ]]--
        elseif id == 772 then
            PlaySound("GAME_MINORCHEAT")
            if InfosDisplay[0].LiveClock == true then 
				TextOut("Real time clock display Off")
                InfosDisplay[0].LiveClock = false
			else 
				TextOut("Real time clock display On") 
                InfosDisplay[0].LiveClock = true
			end

        -- [[ MPAZZAR ]]--
        elseif id == 773 then
            PlaySound("GAME_MAJORCHEAT")
			if not HD_mode then
				TextOut("HD Mode On")
				HD_mode = CreateObject {x=GetClaw().X, y=GetClaw().Y, z=0, logic="CustomLogic", name="_HD", Width = 864, Height = 486}
			else
				TextOut("HD Mode Off")
				HD_mode.State = 4
				HD_mode = false
			end
        
		end
	end
end

-- ffi.C.PostMessageA(nRes(1,1), 0x111, id, 0) 


_codes.EncodeCode = function(str)
	local encoded = ""
	for i=1,#str do
		encoded = encoded..string.char(string.byte(string.sub(str,i,i))-15)
	end
	return encoded
end

_codes.RegisterCheat = function(name, id, save)
	ffi.cast("void (*__thiscall)(int,const char*,int,int)",0x423E40)(nRes(18), _codes.EncodeCode(name), id, save)
end

return _codes
