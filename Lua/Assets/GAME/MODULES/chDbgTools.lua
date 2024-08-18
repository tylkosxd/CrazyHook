local DBG = {}
local hdc = ffi.new("int")
local WINOBJS = {}


DBG.DebugRects = function(ptr)
	if InfosDisplay[0].DebugRects == true then
		if ptr then 
			hdc = tonumber(ffi.cast("int",ptr)) 
		end
		WINOBJS = {
			brush = ffi.C.CreateSolidBrush(0),
			brusha = ffi.C.CreateHatchBrush(3,0xFF0000),
			brushb = ffi.C.CreateHatchBrush(4,0x00FFFF),
			brushd = ffi.C.CreateHatchBrush(5,0x00FF00),
            brushe = ffi.C.CreateHatchBrush(2,0x0000FF),
            brushf = ffi.C.CreateHatchBrush(5,0xFF8400),
			pen = ffi.C.CreatePen(5,0,0),
			pena = ffi.C.CreatePen(0,2,0xFF0000),
			penc = ffi.C.CreatePen(0,2,0x00FF00),
			pend = ffi.C.CreatePen(0,2,0x00FFFF),
            pene = ffi.C.CreatePen(0,2,0x0000FF)
		}
		ffi.C.SelectObject(hdc, WINOBJS.pen)
		ffi.C.SelectObject(hdc, WINOBJS.brush)
		LoopThroughObjects(DBG.DrawRects)
		local topblack = tonumber(ffi.cast("int&",0x535844))
		local botblack = tonumber(ffi.cast("int&",0x53584C))
		ffi.C.SelectObject(hdc, WINOBJS.pen)
		ffi.C.SelectObject(hdc, WINOBJS.brush)
		ffi.C.Rectangle(hdc, {0,0,nRes(31)+1,topblack+1})
		ffi.C.Rectangle(hdc, {0,botblack,nRes(31)+1,nRes(32)+1})
		for _,v in pairs(WINOBJS) do 
			ffi.C.DeleteObject(v) 
		end
		WINOBJS = nil
	end
end

DBG.DrawRects = function(object)

    local screen = ffi.cast("CPlane*", Game(9,23)).ScreenA
    local wndres = ffi.cast("CPlane*", Game(9,23)).Screen
	
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
	
		local osx, osy = object.X-screen.Left, object.Y-screen.Top
		ffi.C.SetBkMode(hdc, 1)

        do
            local mover = ffi.new("Rect", {osx+object.MoveRect.Left, osy+object.MoveRect.Top, osx+object.MoveRect.Right, osy+object.MoveRect.Bottom})
            if mover.Right - mover.Left <= wndres.Right + 200 and mover.Bottom - mover.Top <= wndres.Bottom + 200 then 
		        ffi.C.SelectObject(hdc, WINOBJS.penc)
		        ffi.C.SelectObject(hdc, WINOBJS.brushd)
                ffi.C.Rectangle(hdc, mover)          
            end
		end

        do
            local attr = ffi.new("Rect", {osx+object.AttackRect.Left, osy+object.AttackRect.Top, osx+object.AttackRect.Right, osy+object.AttackRect.Bottom})
            if attr.Right - attr.Left <= wndres.Right + 200 and attr.Bottom - attr.Top <= wndres.Bottom + 200 then 
		        ffi.C.SelectObject(hdc, WINOBJS.pend)
                if object.DrawFlags.NoDraw ~= true then
		            ffi.C.SelectObject(hdc, WINOBJS.brushb)
                end
		        ffi.C.Rectangle(hdc, attr)      
            end
        end


		if (object.HitTypeFlags > 1 or object.ObjectTypeFlags > 1) then
            local hitr = ffi.new("Rect", {osx+object.HitRect.Left, osy+object.HitRect.Top, osx+object.HitRect.Right, osy+object.HitRect.Bottom})
            if hitr.Right - hitr.Left <= wndres.Right + 200 and hitr.Bottom - hitr.Top <= wndres.Bottom + 200 then 
                ffi.C.SelectObject(hdc, WINOBJS.pena)
                if object.DrawFlags.NoDraw ~= true then
			        ffi.C.SelectObject(hdc, WINOBJS.brusha)
                end
                ffi.C.Rectangle(hdc, hitr)
            end
		end

        if object.ObjectTypeFlags == ObjectType.Enemy then
            if object.XMax ~= object.XMin or object.YMax ~= object.YMin then
                local tempr = ffi.new("Rect", {object.XMin, object.YMin, object.XMax, object.YMax})
                if tempr.Left == tempr.Right then
                    tempr.Left = object.X - 1
                    tempr.Right = object.X + 1
                end
                if tempr.Top == tempr.Bottom then
                    tempr.Top = object.Y - 1
                    tempr.Bottom = object.Y + 1
                end
                local mmr1 = ffi.new("Rect", {tempr.Left-screen.Left, osy-1, tempr.Right-screen.Left, osy+1})
                local mmr2 = ffi.new("Rect", {osx-1, tempr.Top-screen.Top, osx+1, tempr.Bottom-screen.Top})
                ffi.C.SelectObject(hdc, WINOBJS.pene)
                ffi.C.Rectangle(hdc, mmr1)
                ffi.C.Rectangle(hdc, mmr2)
            end
        end      

		if InfosDisplay[0].DebugRectsPlus == true then
			local str = ""
			if object.IsGameplayObject <= 0 then 
				str = "ID: "..object.EditorID
			elseif object.Logic == CaptainClaw then 
				str = "CLAW"
			else 
				str = "0x".. HEX(object:GetSelf())
			end
			str = str.."\nZ: "..object.Z.." I: "..object.I.." State:"..object.State 
			ffi.C.SetTextColor(hdc, 0x000000)
			if object.OnScreen >= 0 then
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

DBG.DebugText = function (ptr)
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

DBG.DrawHealthBars = function(obj)
    local screenx, screeny = Game(9,23,16), Game(9,23,17)
    local osx, osy = obj.X-screenx, obj.Y-screeny+tonumber(ffi.cast("int&",0x535844))
    
    if obj.Health > 0 and obj.ObjectTypeFlags == 4 and obj.Logic ~= Tentacle then
		local pen = ffi.C.CreatePen(5,0,0)
        if obj.User[4] == 0 then
			obj.User[4] = obj.Health
		end
        local maxHealth = obj.User[4]
        if maxHealth > 2 and maxHealth < 100 then
		    ffi.C.SelectObject(hdc, pen)
		    do
			    ffi.C.SetTextColor(hdc, 0xFFFFFF)
			    local lines = 1
			    local ost = math.min(obj.HitRect.Top, obj.MoveRect.Top)
			    local str = tostring(obj.Health)
			    local rct = ffi.new("Rect",{osx-#str+24, osy+ost-32, osx+#str*10+48, osy+ost+22})
			    local lprct = ffi.new("Rect[1]", rct)
			    ffi.C.DrawTextA(hdc, str, #str, lprct, 1)
		    end
		    local increase = 64-64*obj.Health/maxHealth
		    local xmin = osx-32+increase
		    local xmax = osx+32
		    local top = math.min(obj.HitRect.Top, obj.MoveRect.Top)
		    local rgn = ffi.C.CreateRectRgn(xmin,osy+4+top-22,xmax,osy-4+top-22)
		    local brush = ffi.C.CreateSolidBrush(0x0000FF)
		    ffi.C.FillRgn(hdc, rgn, brush)
		    ffi.C.DeleteObject(brush)
		    ffi.C.DeleteObject(rgn)
            ffi.C.DeleteObject(pen)
            ffi.C.DeleteObject(font)
		    rgn,brush = nil,nil
        end
    end
end

DBG.HealthBars = function (ptr)
    if InfosDisplay[0].HealthBars == true then
        if ptr then 
			hdc = tonumber(ffi.cast("int",ptr)) 
		end
        LoopThroughObjects(DBG.DrawHealthBars)
	end
end

return DBG
