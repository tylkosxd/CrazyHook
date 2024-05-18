local _dbg = {}


_dbg.DebugRects = function(ptr)
	if InfosDisplay[0].DebugRects == true then
		if ptr then 
			hdc = tonumber(ffi.cast("int",ptr)) 
		end
		winobtab = {
			brush = ffi.C.CreateSolidBrush(0),
			brusha = ffi.C.CreateHatchBrush(3,0xFF0000),
			brushb = ffi.C.CreateHatchBrush(4,0x00FFFF),
			brushd = ffi.C.CreateHatchBrush(5,0x00FF00),
			pen = ffi.C.CreatePen(5,0,0),
			pena = ffi.C.CreatePen(0,2,0xFF0000),
			penc = ffi.C.CreatePen(0,2,0x00FF00),
			pend = ffi.C.CreatePen(0,2,0x00FFFF)
		}
		ffi.C.SelectObject(hdc, winobtab.pen)
		ffi.C.SelectObject(hdc, winobtab.brush)
		LoopThroughObjects(_dbg.DrawRects)
		local topblack = tonumber(ffi.cast("int&",0x535844))
		local botblack = tonumber(ffi.cast("int&",0x53584C))
		ffi.C.SelectObject(hdc, winobtab.pen)
		ffi.C.SelectObject(hdc, winobtab.brush)
		ffi.C.Rectangle(hdc, {0,0,nRes(31)+1,topblack+1})
		ffi.C.Rectangle(hdc, {0,botblack,nRes(31)+1,nRes(32)+1})
		for _,v in pairs(winobtab) do 
			ffi.C.DeleteObject(v) 
		end
		winobtab = nil
	end
end

_dbg.DrawRects = function(object)

	local screenx, screeny = Game(9,23,16), Game(9,23,17)
	
	if  object.Logic ~= CaptainClawScreenPosition 
	and object.Logic ~= PowerupGlitter 
	and object.Logic ~= GlitterMother
	and object.Logic ~= GlitterBaby	
	and object.Logic ~= DoNothing 
	and object.Logic ~= DoNothingNormal 
	and object.Logic ~= BehindAniCandy
	and object.Logic ~= FrontAniCandy 
	and object.Logic ~= BehindCandy 
	and object.Logic ~= FrontCandy 
	and object.Logic ~= AniCycle
    and object.Logic ~= MultiStats
	then
	
		local osx, osy = object.X-screenx, object.Y-screeny+tonumber(ffi.cast("int&",0x535844))
		ffi.C.SetBkMode(hdc, 1)
		ffi.C.SelectObject(hdc, winobtab.penc)
		ffi.C.SelectObject(hdc, winobtab.brushd)
		ffi.C.Rectangle(hdc,{osx+object.MoveRect.Left,osy+object.MoveRect.Top,osx+object.MoveRect.Right,osy+object.MoveRect.Bottom})
		ffi.C.SelectObject(hdc, winobtab.pend)
		ffi.C.SelectObject(hdc, winobtab.brushb)
		ffi.C.Rectangle(hdc,{osx+object.AttackRect.Left,osy+object.AttackRect.Top,osx+object.AttackRect.Right,osy+object.AttackRect.Bottom})
		if (object.HitTypeFlags>1 or object.ObjectTypeFlags>1) then
			ffi.C.SelectObject(hdc, winobtab.pena)
			ffi.C.SelectObject(hdc, winobtab.brusha)
			ffi.C.Rectangle(hdc,{osx+object.HitRect.Left,osy+object.HitRect.Top,osx+object.HitRect.Right,osy+object.HitRect.Bottom})
		end
		if InfosDisplay[0].DebugRectsPlus == true then
			local str = "#"
			if object.IsGameplayObject <= 0 then 
				str = str..object.EditorID
			elseif object.Logic==CaptainClaw then 
				str = str.."CLAW"
			else 
				str = str.."G" 
			end
			str = str.."\nZ: "..object.Z.." I: "..object.I.." State:"..object.State 
			ffi.C.SetTextColor(hdc, 0xFFFFFF)
			if object.OnScreen >=0 then
				local ost = object.MoveRect.Top
				if ost==0 then ost = object.AttackRect.Top end
				if ost==0 then ost = object.HitRect.Top end
				local rct = ffi.new("Rect",{osx-#str*5, osy+ost-10, osx+#str*5, osy+ost+25})
				local lprct = ffi.new("Rect[1]",rct)
				ffi.C.DrawTextA(hdc, str,#str, lprct, 1)
			end
		end
	end
end

_dbg.DebugText = function (ptr)
	if InfosDisplay[0].DebugText == true then
		if ptr then 
			hdc = tonumber(ffi.cast("int",ptr)) 
		end
		ffi.C.SetTextColor(hdc, 0xFFB0B0)
		for i, str in ipairs(debug_text) do
			str = tostring(str)
			if #str > 0 and tonumber(i) then
				if tonumber(i) > 0 and tonumber(i) <= 12 then
					local rect = ffi.new("Rect",{8, 44+24*i, 8+#str*10, 64+24*i})
					local lprect = ffi.new("Rect[1]", rect)
					ffi.C.DrawTextA(hdc, str ,#str, lprect, 20)
				end
			end
		end
	end
end

return _dbg
