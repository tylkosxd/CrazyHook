--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ Debug tools module ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local hdc;
local DBG = {}

DBG.CreateDrawingTools = function()
	if not DBG.CrossBrushes then
		DBG.CrossBrushes = {
			ffi.C.CreateHatchBrush(5,0xFF0000),
			ffi.C.CreateHatchBrush(5,0x00FF00),
			ffi.C.CreateHatchBrush(5,0x00FFFF),
			ffi.C.CreateHatchBrush(5,0x0000FF),
			ffi.C.CreateHatchBrush(5,0xFFFFFF),
			ffi.C.CreateHatchBrush(5,0x808080)
		}
	end
	if not DBG.Brushes then
		DBG.Brushes = {
			Blue = ffi.C.CreateHatchBrush(3,0xFF0000),
			Yellow = ffi.C.CreateHatchBrush(4,0x00FFFF),
			Green = ffi.C.CreateHatchBrush(5,0x00FF00),
			Cyan = ffi.C.CreateHatchBrush(3, 0xFFFF00)
		}
	end
	if not DBG.Pens then
		DBG.Pens = {
			Blue = ffi.C.CreatePen(0,2,0xFF0000),
			Green = ffi.C.CreatePen(0,2,0x00FF00),
			Yellow = ffi.C.CreatePen(0,2,0x00FFFF),
			Red = ffi.C.CreatePen(0,2,0x0000FF),
			Cyan = ffi.C.CreatePen(0,2,0xFFFF00),
			Black = ffi.C.CreatePen(0,2,0),
			Hollow = ffi.C.CreatePen(5,1,0)
		}
	end
end

DBG.DeleteDrawingTools = function()
	if DBG.Brushes then
		for k,v in pairs(DBG.Brushes) do
			ffi.C.DeleteObject(v)
			DBG.Brushes[k] = nil
		end
		DBG.Brushes = nil
	end
	if DBG.Pens then
		for k,v in pairs(DBG.Pens) do
			ffi.C.DeleteObject(v)
			DBG.Pens[k] = nil
		end
		DBG.Pens = nil
	end
	if DBG.CrossBrushes then
		for k,v in ipairs(DBG.CrossBrushes) do
			ffi.C.DeleteObject(v)
			DBG.CrossBrushes[k] = nil
		end
		DBG.CrossBrushes = nil
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ [[ MPRECTS & MPMOREDI ]] ------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

DBG.DrawObjectsRect = function(onScreenX, onScreenY, rect, color)
	local rectToDraw = ffi.new("Rect", {
		onScreenX + rect.Left,
		onScreenY + rect.Top,
		onScreenX + rect.Right,
		onScreenY + rect.Bottom
	})
	ffi.C.SelectObject(hdc, DBG.Pens[color])
	ffi.C.SelectObject(hdc, DBG.Brushes[color])
	ffi.C.Rectangle(hdc, rectToDraw)
end

DBG.DrawRects = function(object)
	local coords = ffi.cast("CPlane*", Game(9,23)).ScreenA -- map coordinates Rect

	if object.X > coords.Right + 300
	or object.X < coords.Left - 300
	or object.Y > coords.Bottom + 300
	or object.Y < coords.Top - 300
	or object.Logic == CaptainClawScreenPosition
	or object.Logic == PowerupGlitter
	or object.Logic == GlitterMother
	or object.Logic == GlitterBaby
	or object.Logic == DoNothing
	or object.Logic == DoNothingNormal
	or object.Logic == BehindAniCandy
	or object.Logic == FrontAniCandy
	or object.Logic == BehindCandy
	or object.Logic == FrontCandy
	or object.Logic == AniCycle
    or object.Logic == MultiStats
	then return end

	local onScreenX = object.X - coords.Left
	local onScreenY = object.Y - coords.Top

	ffi.C.SetBkMode(hdc, 1)

	-- drawing move, attack and hit rects:
	DBG.DrawObjectsRect(onScreenX, onScreenY, object.MoveRect, "Green")
	DBG.DrawObjectsRect(onScreenX, onScreenY, object.AttackRect, "Yellow")
	if object.ObjectTypeFlags == CollisionFlags.Sound then
		DBG.DrawObjectsRect(onScreenX, onScreenY, object.HitRect, "Cyan")
	elseif object.HitTypeFlags > 1 or object.ObjectTypeFlags > 1 then
		DBG.DrawObjectsRect(onScreenX, onScreenY, object.HitRect, "Blue")
	end

	-- drawing min-max of enemies:
	if object.ObjectTypeFlags == ObjectType.Enemy and
	(math.abs(object.XMax - object.XMin) > 10 or math.abs(object.YMax - object.YMin) > 10) then -- difference of 10pxs (made-up)
		local horizontal = ffi.new("Rect", {
			object.XMin - coords.Left,
			onScreenY - 1,
			object.XMax - coords.Left,
			onScreenY + 1
		})
		local vertical = ffi.new("Rect", {
			onScreenX - 1,
			object.YMin - coords.Top,
			onScreenX + 1,
			object.YMax - coords.Top
		})
		ffi.C.SelectObject(hdc, DBG.Pens.Red)
		ffi.C.Rectangle(hdc, horizontal)
		ffi.C.Rectangle(hdc, vertical)
	end

	-- drawing additional info:
	if InfosDisplay[0].DebugRectsPlus == true and object.OnScreen >= 0 then
		ffi.C.SetTextColor(hdc, 0xFFFFFF)
		local info = object.IsGameplayObject <= 0 and "ID: " .. object.ID or object.Logic == CaptainClaw and "CLAW" or "."
		local objectInfo = table.concat{info, "\nZ: ", object.Z, " I: ", object.I, " State:", object.State}
		local objectTop = math.min(object.HitRect.Top, object.MoveRect.Top)
		local ptrRect = ffi.new("Rect[1]")
		ptrRect[0] = {
			onScreenX - #objectInfo*5,
			onScreenY + objectTop - 10,
			onScreenX + #objectInfo*5,
			onScreenY + objectTop + 25
		}
		ffi.C.DrawTextA(hdc, objectInfo, #objectInfo, ptrRect, 1)
	end

end

DBG.DebugRects = function()
	if InfosDisplay[0].DebugRects == true then
		DBG.CreateDrawingTools()
		LoopThroughObjects(DBG.DrawRects)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ MPTEXT ]] ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local DrawOneLineOfDebugText = function(lineNumber, text)
	text = tostring(text)
	lineNumber = tonumber(lineNumber)
	if #text > 0 and lineNumber and lineNumber > 0 and lineNumber <= 12 then
		local ptrRect = ffi.new("Rect[1]")
		ptrRect[0] = {
			8,
			44 + 24*lineNumber,
			8 + #text*10,
			64 + 24*lineNumber
		}
		ffi.C.DrawTextA(hdc, text ,#text, ptrRect, 20)
	end
end

DBG.DebugText = function ()
	if InfosDisplay[0].DebugText == true then
		ffi.C.SetTextColor(hdc, 0xFFB0B0)
		for index, text in ipairs(debug_text) do
			DrawOneLineOfDebugText(index, text)
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- [[ MPTHANOS ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

DBG.EnemiesMaxHpList = {}

DBG.DrawHealthBars = function(object)
    if object.Health <= 0 or object.BumpFlags.Enemy == false or object.Logic == Tentacle or object.Logic == Parrot then
		if DBG.EnemiesMaxHpList[object:GetSelf()] then
			DBG.EnemiesMaxHpList[object:GetSelf()] = nil
		end
		return
	end
	local coords = ffi.cast("CPlane*", Game(9,23)).ScreenA -- map coordinates Rect
	local onScreenX = object.X - coords.Left
	local onScreenY = object.Y - coords.Top
	-- Save original max health of the enemy:
	if not DBG.EnemiesMaxHpList[object:GetSelf()] then
		DBG.EnemiesMaxHpList[object:GetSelf()] = object.Health
	end
	local maxHealth = DBG.EnemiesMaxHpList[object:GetSelf()]
	-- return if the enemy had originally less than 3 hp (small enemies) or more than 100 (bosses)
	if maxHealth <= 2 or maxHealth >= 100 then return end
	-- draw the amount of hp:
	local pen = ffi.C.CreatePen(5,0,0)
	ffi.C.SelectObject(hdc, pen)
	ffi.C.SetTextColor(hdc, 0xFFFFFF)
	local objectsTop = math.min(object.HitRect.Top, object.MoveRect.Top)
	local str = tostring(object.Health)
	local ptrRect = ffi.new("Rect[1]")
	ptrRect[0] = {
		onScreenX - #str + 24,
		onScreenY + objectsTop - 32,
		onScreenX + #str*10 + 48,
		onScreenY + objectsTop + 22
	}
	ffi.C.DrawTextA(hdc, str, #str, ptrRect, 1)
	-- draw the hp bar:
	local increase = 64 - 64*object.Health/maxHealth
	local top = math.min(object.HitRect.Top, object.MoveRect.Top)
	local brush = ffi.C.CreateSolidBrush(0x0000FF)
	local hpBar = ffi.new("Rect", {
		onScreenX - 32 + increase,
		onScreenY + top - 18,
		onScreenX + 32,
		onScreenY + top - 26
	})
	ffi.C.SelectObject(hdc, brush)
	ffi.C.Rectangle(hdc, hpBar)

	ffi.C.DeleteObject(brush)
	ffi.C.DeleteObject(pen)
end

DBG.HealthBars = function()
    if InfosDisplay[0].HealthBars == true then
        LoopThroughObjects(DBG.DrawHealthBars)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ MPSIMPSON ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local jumpInputTime = nil
local djFrameTime, djFrameIncoming = nil, nil -- "dj" is abbreviation of "double jump"

local ClawCanJump = function()
	local cs = GetClaw().State
	return cs == ClawStates.MoveRight or cs == ClawStates.MoveLeft or cs == ClawStates.Stand or cs == ClawStates.Climb or
	cs == ClawStates.LookUp or cs == ClawStates.OnEdge or cs == ClawStates.Swing
end

local GetFramesCountFromTime = function(dtime)
	local frameTime = 1000/60
	local frameDiff = dtime/frameTime
	return frameDiff < -21 and " " or frameDiff > 21 and " " or tostring(math.round(frameDiff))
end

local GetJumpInputTimeDiff = function()
	local claw = GetClaw()
	local clawsPhysics = GetClaw().PhysicsType
	if AND(GetGameControls().InputState1, InputFlags.Jump) ~= 0 then
		jumpInputTime = GetTime()
	end
	if claw.State == ClawStates.Hit and (clawsPhysics == 3 or clawsPhysics == 4) and not djFrameIncoming then
		djFrameTime = nil
		djFrameIncoming = true
	end
	if djFrameIncoming and claw.State == ClawStates.Stand then
		djFrameTime = GetTime() + mdl_exe.FrameTime[0]
		djFrameIncoming = false
	end
	if jumpInputTime and djFrameTime then
		local dtime = jumpInputTime - djFrameTime
		return GetFramesCountFromTime(dtime)
	else
		return ""
	end
end

DBG.JumpSignal = function ()
	if InfosDisplay[0].JumpSignal == true then
		local screen = ffi.cast("CPlane*", Game(9,23)).Screen
		local centerX, centerY = math.round(screen.Right/2), math.round(screen.Bottom/2)
		local color = ClawCanJump() and 0x00FF00 or 0x0000FF
		local brush = ffi.C.CreateSolidBrush(color)
		ffi.C.SelectObject(hdc, brush)
		ffi.C.Ellipse(hdc, {centerX-16, centerY-16, centerX+16, centerY+16})
		local str = GetJumpInputTimeDiff()
		local ptrRect = ffi.new("Rect[1]")
		ptrRect[0] = {centerX-16, centerY-8, centerX+16, centerY+12}
		ffi.C.DrawTextA(hdc, str, #str, ptrRect, 1)
		ffi.C.DeleteObject(brush)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- [[ MPSPEEDRUN ]] ----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

DBG.StopWatchStart = 0

local function PrefixZeroMaybe(p)
	p = tostring(p)
	return #p == 1 and "0"..p or p
end

DBG.FormatTime = function(t)
    local msPart = string.sub(t, -3, -2)
    local secPartFull = tonumber(string.sub(t, 1, -4)) or 0
    local secPart = PrefixZeroMaybe(secPartFull%60)
    local minPartFull = math.floor(secPartFull/60)
    local minPart = PrefixZeroMaybe(minPartFull%60)
    local hourPart = math.floor(minPartFull/60)
    return hourPart .. ":" .. minPart .. ":" .. secPart .. "." .. msPart
end

DBG.StopWatch = function()
    if InfosDisplay[0].RealStopwatch == true then
        ffi.C.SetTextColor(hdc, 0xFFFFFF)
        local timeDiff = mdl_exe.RealTime[0] - DBG.StopWatchStart
        local timeString = DBG.FormatTime(timeDiff)
        local screen = ffi.cast("CPlane*", Game(9,23)).Screen -- the game's resolution
        local x, y = screen.Right, screen.Bottom
        local rect = ffi.new("Rect", { -- rect in down-right corner
			x - 8 - #timeString*10,
			y - 27,
			x,
			y
		})
        local ptrRect = ffi.new("Rect[1]", rect)
        ffi.C.DrawTextA(hdc, timeString ,#timeString, ptrRect, 2)
    end
end

--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ [[ MPTILES ]] -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

DBG.DrawTileRect = function(tool, rect)
	if not tool then return end
	ffi.C.SelectObject(hdc, tool)
	ffi.C.SelectObject(hdc, DBG.Pens.Hollow)
	ffi.C.Rectangle(hdc, rect)
end

DBG.DrawDoubleTile = function(tileA, rect)
	local brushInner = DBG.CrossBrushes[tileA.RectAttribute]
	if brushInner and tileA.Attribute == tileA.RectAttribute then
		DBG.DrawTileRect(brushInner, rect)
		return
	end
	local rectInner = ffi.new("Rect[1]")
	rectInner[0].Left = rect.Left + tileA.TileRect.Left
	rectInner[0].Top = rect.Top + tileA.TileRect.Top
	rectInner[0].Right = rectInner[0].Left + tileA.TileRect.Right
	rectInner[0].Bottom = rectInner[0].Top + tileA.TileRect.Bottom
	if brushInner then
		DBG.DrawTileRect(brushInner, rectInner[0])
	end
	local brushOuter = DBG.CrossBrushes[tileA.Attribute]
	if brushOuter then
		local rectOuter = ffi.new("Rect[1]", rect)
		local substractedRgn = ffi.C.CreateRectRgn(0, 0, 0, 0)
		local innerRectRgn = ffi.C.CreateRectRgnIndirect(rectInner)
		local outerRectRgn = ffi.C.CreateRectRgnIndirect(rectOuter)
		ffi.C.CombineRgn(substractedRgn, outerRectRgn, innerRectRgn, 4)
		ffi.C.FillRgn(hdc, substractedRgn, brushOuter)
		ffi.C.DeleteObject(substractedRgn)
		ffi.C.DeleteObject(innerRectRgn)
		ffi.C.DeleteObject(outerRectRgn)
	end
end

DBG.DrawTiles = function()
	if InfosDisplay[0].DebugTiles == false then return end
	DBG.CreateDrawingTools()
	local action = GetMainPlane()
	if not action then return end
	local coords = action.ScreenA
	local tileSize = action.DefTileRect
	local x, y = coords.Left/tileSize.Right, coords.Top/tileSize.Bottom
	local offx, offy = coords.Left % tileSize.Right, coords.Top % tileSize.Bottom

	if not DBG.ScreenTileLayer then
		local w, h = math.ceil(coords.Right/tileSize.Right - x + 1), math.ceil(coords.Bottom/tileSize.Bottom - y + 1)
		DBG.ScreenTileLayer = GetMainPlane():CreateTileLayer(x, y, w, h)
	else
		DBG.ScreenTileLayer.X = x
		DBG.ScreenTileLayer.Y = y
	end

	DBG.ScreenTileLayer:MapContent(function(params)
		local tileA = GetTileA(params.PlaneTile)
		if not tileA then return end

		local rect = ffi.new("Rect")
		rect.Left = tileSize.Right * params.LayerX - offx
		rect.Top = tileSize.Bottom * params.LayerY - offy
		rect.Right = rect.Left + tileSize.Right
		rect.Bottom = rect.Top + tileSize.Bottom

        if tileA.Type == TileType.Single then
			DBG.DrawTileRect(DBG.CrossBrushes[tileA.Attribute], rect)
		elseif tileA.Type == TileType.Mask then
			DBG.DrawTileRect(DBG.CrossBrushes[6], rect)
		elseif tileA.Type == TileType.Double then
			DBG.DrawDoubleTile(tileA, rect)
        end
	end)
end


--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- [[ Main ]] -------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

DBG.Main = function(ptr)
	if ptr then hdc = tonumber(ffi.cast("int",ptr)) end
	DBG.StopWatch() -- MPSPEEDRUN
	DBG.DebugRects() -- MPRECTS and MPMOREDI
	DBG.DebugText() -- MPTEXT
	DBG.HealthBars() -- MPTHANOS
	DBG.JumpSignal() -- MPSIMPSON
	DBG.DrawTiles() -- MP
end

return DBG
