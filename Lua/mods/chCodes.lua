local mdl_exev = require 'mods.chExeVars'

local _cheats_list = {
	mparmor = {0x8072, 0},
	mpzax = {666, 1},
	mpartur = {667, 0},
	mpfly = {668, 0},
	mpkijan = {669, 1},
	mprects = {672, 1},
	mpmoredi = {673, 1},
	mplessdi = {674, 1}
	-- Add your own code here
	-- name = {id, 1|0 (minor|major cheatcode)}
	}

_codes = {}

_codes.CrazyCheats = function(ptr)
	
	if _chameleon[0] == chamStates.LoadingStart then
		if artur_mode then artur_mode = nil end
		if kijan_mode then kijan_mode = nil end
		if fly_mode then fly_mode = nil end
		-- Add here if your code's variable needs to reset on the the start of another game
		-- if codename_mode then codename_mode = nil end
		
		for name, details in pairs(_cheats_list) do
			_codes.RegisterCheat(name, details[1], details[2])
		end
		
	elseif _chameleon[0] == chamStates.OnPostMessageA then
		local id = tonumber(ffi.cast("int",ptr))
		
		--[[ MPZAX ]]--
		if id == 666 then
			TextOut("Zax37 is programming God too!")
			PlaySound("GAME_MINORCHEAT")
		
		-- Add here what your code will do:
		-- elseif id == "id" then
		
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
				for i=2,4 do 
					ccnopera[i] = 0xFF 
					ccnoperb[i] = 0xFF 
				end
				ccnopera[5] = 0xFD 
				ccnoperb[5] = 0xFE
				artur_mode = false
			end
			
		--[[ MPFLY ]]--
		elseif id == 668 and GetClaw().Health >= 0 then
			PlaySound("GAME_MAJORCHEAT")
			if not fly_mode then
				TextOut("Fly Mode On")
				fly_mode = CreateObject {x=GetClaw().X, y=GetClaw().Y, z=0, logic="CustomLogic", name="_FlyGrab"}
			else
				TextOut("Fly Mode Off")
				fly_mode.turn_off = true
				fly_mode = nil
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
				kijan_mode = nil
			end
			
		-- Teleport hook:
		elseif id == 0x805C then
			if fly_mode then
				fly_mode.X, fly_mode.Y = mdl_exev.TeleportX[0], mdl_exev.TeleportY[0]
			end
			
		-- Claw's death:	
		elseif id == 0x803A then
			if fly_mode then
				fly_mode:Destroy()
				fly_mode = nil
			end
			
		--[[ MPRECTS ]]--	
		elseif id == 672 then
			PlaySound("GAME_MINORCHEAT")
            InfosDisplayState[0] = XOR(InfosDisplayState[0], InfosFlags.DebugRects)
			if AND(InfosDisplayState[0], InfosFlags.DebugRects) == 0 then 
				TextOut("Rects display OFF")
			else 
				TextOut("Rects display ON") 
			end
			
		--[[ MPMOREDI ]]--	
		elseif id == 673 then
			if AND(InfosDisplayState[0], InfosFlags.DebugRects) ~= 0 and AND(InfosDisplayState[0], InfosFlags.DebugRectsPlus) == 0 then 
				TextOut("Showing more debug info") 
                PlaySound("GAME_MINORCHEAT")
                InfosDisplayState[0] = XOR(InfosDisplayState[0], InfosFlags.DebugRectsPlus)
			end
		
		--[[ MPLESSDI ]]--
		elseif id == 674 then
			if AND(InfosDisplayState[0], InfosFlags.DebugRects) ~= 0 and AND(InfosDisplayState[0], InfosFlags.DebugRectsPlus) ~= 0 then 
				TextOut("Showing less debug info") 
                PlaySound("GAME_MINORCHEAT")
                InfosDisplayState[0] = XOR(InfosDisplayState[0], InfosFlags.DebugRectsPlus)
			end
		end
	end
end

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
