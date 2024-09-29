local TILES = { 
	PlaneMethods = {}, 
	LayerMethods = {},
	Clear = -1, -- used by Game
	Wildcard = -2, -- any tile and no tile
	Color = 0xEEEEEEEE -- used by Game, always filled with the same color (plane -> FillColor)
}

-- Check if the tile exists:
local function TheTileExists(plane, tile)
    local tileset = CastGet(plane.Tileset, 0)
    local first = CastGet(tileset, 25)
    local last = CastGet(tileset, 26)
    if tile < first or tile > last then
        return false
    else
        if CastGet(tileset, 5, tile) == 0 then
            return false
        else
            return true
        end
    end
end

-- Creates CTileLayer:
local function NewTileLayer(plane, x, y, w, h)
	local size = w*h
	return ffi.new("CTileLayer", size, {plane, x, y, w, h, size})
end

-- Get tile attributes/properties:
TILES.GetTileA = function(id)
    if Game(9) > 0 and Game(9,19) > 0 then
        if not tonumber(id) or id < 0 or not TheTileExists(ffi.cast("CPlane*", Game(9,23)), id) then
            do return end
        else
            local tile = Game(9,19,id)
	        local tType = CastGet(tile, 0)
	        if tType == TileType.Single then
                return ffi.cast("SingleTileA*", tile)
            elseif tType == TileType.Double then
                return ffi.cast("DoubleTileA*", tile)
            elseif tType == TileType.Mask then
                return ffi.cast("MaskTileA*", tile)
            end
			-- see chCdecl.lua for details of tile types
        end
    end
end

-- Plane methods:

TILES.PlaneMethods.GetTile = function(plane, x, y)
    if plane.ID >= PlanesCount() then
        error("GetTile - invalid plane")
    else
        if x >= 0 and x < plane.Width and y >= 0 and y < plane.Height then
            return plane.Tiles[x + y * plane.Width]
        else
            return TILES.Wildcard
        end
    end
end

TILES.PlaneMethods.PlaceTile = function(plane, x, y, tile)
    if plane.ID >= PlanesCount() then
        error("GetTile - invalid plane")
    elseif tile ~= TILES.Wildcard then
		if tile == TILES.Clear or tile == TILES.Color or TheTileExists(plane, tile) then
			if x >= 0 and x < plane.Width and y >= 0 and y < plane.Height then
				plane.Tiles[x + y * plane.Width] = tile
			end
		end
    end
	return plane
end

TILES.PlaneMethods.CreateTileLayer = function(plane, x, y, w, h)
	if not y and not w and not h then
		if type(x) == "table" and #x == 4 then
			x, y, w, h = x[1], x[2], x[3]-x[1]+1, x[4]-x[2]+1
		elseif ffi.istype("Rect", x) then
			x, y, w, h = x.Left, x.Top, x.Right-x.Left+1, x.Bottom-x.Top+1
		else
			error("Plane:GetTileLayer - invalid arguments")
		end
	end
	if not x or x < 0 or not y or y < 0 or not w or w < 0 or not h or h < 0 then
		error("Plane:GetTileLayer - invalid arguments")
	end
	local layer = NewTileLayer(plane, x, y, w, h)
	local count = 0
	for py = 0, h-1 do
		for px = 0, w-1 do
			if x + px >= plane.Width then
				layer.Content[count] = TILES.Wildcard 
			elseif y + py >= plane.Height then
				layer.Content[count] = TILES.Wildcard 
			else
				layer.Content[count] = plane.Tiles[x + px + (y + py)*plane.Width]
			end
			count = count + 1
		end
	end
	return layer
end

-- TileLayer methods:

-- Anchors the layer to the plane:
TILES.LayerMethods.Anchor = function(layer)
	local count = 0
	for m = 0, layer.Height-1 do
		for n = 0, layer.Width-1 do
			layer.PRoot:PlaceTile(layer.X + n, layer.Y + m, layer.Content[count])
			count = count+1
		end
	end
end

-- Returns the copy of the layer:
TILES.LayerMethods.Clone = function(layer)
	local clone = NewTileLayer(layer.PRoot, layer.X, layer.Y, layer.Width, layer.Height)
	for n = 0, clone.ContentSize-1 do
		clone.Content[n] = layer.Content[n]
	end
	return clone
end

-- The below functions are immutable, which means they copy the layer and modify the copy:

TILES.LayerMethods.SetPos = function(layer, x, y)
	if not y then y = layer.Y end
	local clone = TILES.LayerMethods.Clone(layer)
	clone.X = x
	clone.Y = y
	return clone
end

TILES.LayerMethods.Shift = function(layer, x, y)
	if not y then y = 0 end
	local clone = TILES.LayerMethods.Clone(layer)
	clone.X = clone.X + x
	clone.Y = clone.Y + y
	return clone
end

TILES.LayerMethods.Offset = function(layer, offx, offy, fill)
	if not offy then offy = 0 end
	if not fill then fill = TILES.Wildcard end
	if offx ~= 0 or offy ~= 0 then
		local clone = TILES.LayerMethods.Clone(layer)
		clone = TILES.LayerMethods.Fill(clone, fill)
		for n = 0, layer.ContentSize-1 do
			local nx = n%clone.Width + offx
			local ny = math.floor(n/clone.Width) + offy
			if ny >= 0 and ny < clone.Height and nx >= 0 and nx < clone.Width then
				clone.Content[nx + ny*layer.Width] = layer.Content[n]
			end
		end
		return clone
	end
	return layer
end

TILES.LayerMethods.Resize = function(layer, w, h, fill)
	if not fill then fill = TILES.Wildcard end
	local clone = NewTileLayer(layer.PRoot, layer.X, layer.Y, w, h)
	clone = TILES.LayerMethods.Fill(clone, fill)
	local count = 0
	for py = 0, layer.Height-1 do
		for px = 0, layer.Width-1 do
			clone.Content[px + py*clone.Width] = layer.Content[px + py*layer.Width]
		end
	end
	return clone
end

TILES.LayerMethods.SetPlane = function(layer, plane)
	if ffi.istype("CPlane*", plane) then
		local clone = TILES.LayerMethods.Clone(layer)
		clone.PRoot = plane
		return clone
	elseif type(plane) == "number" then
		local clone = TILES.LayerMethods.Clone(layer)
		layer.PRoot = GetPlane(index)
		return clone
	else
		error("CTileLayer:SetPlane invalid argument!")
	end
end

TILES.LayerMethods.Merge = function(L1, L2, fill)
	if not fill then fill = TILES.Wildcard end
	local posx, posy = math.min(L1.X, L2.X), math.min(L1.Y, L2.Y)
	local new_w = math.max(L1.X+L1.Width, L2.X+L2.Width) - math.min(L1.X, L2.X)
	local new_h = math.max(L1.Y+L1.Height, L2.Y+L2.Height) - math.min(L1.Y, L2.Y)
	local clone = TILES.LayerMethods.Clone(L1)
	do
		TILES.LayerMethods.SetPos(clone, posx, posy)
		TILES.LayerMethods.Resize(clone, new_w, new_h, fill)
		TILES.LayerMethods.Offset(clone, posx - L1.X, posy - L1.Y, fill)
	end
	local clone2 = TILES.LayerMethods.Clone(L2)
	do
		TILES.LayerMethods.SetPos(clone2, posx, posy)
		TILES.LayerMethods.Resize(clone2, new_w, new_h, TILES.Wildcard)
		TILES.LayerMethods.Offset(clone2, posx - L2.X, posy - L2.Y, TILES.Wildcard)
	end
	for n = 0, clone.ContentSize-1 do
		if clone2.Content[n] ~= TILES.Wildcard then
			clone.Content[n] = clone2.Content[n]
		end
	end	
	return clone
end

TILES.LayerMethods.Map = function(layer, fun, args)
	if type(fun) == "function" then
		local clone = TILES.LayerMethods.Clone(layer)
		local count = 0
		local params = {}
		for py = 0, clone.Height-1 do
			for px = 0, clone.Width-1 do
				params.LayerX = px
				params.LayerY = py
				params.LayerTile = clone.Content[px + py*clone.Width] 
				params.PlaneX = clone.X + px
				params.PlaneY = clone.Y + py
				params.PlaneTile = clone.PRoot.Tiles[clone.X + px + (clone.Y + py)*clone.PRoot.Width]
				clone.Content[count] = fun(params, args) or clone.Content[count]
				count = count+1
			end
		end
		return clone
	else
		error("Layer:MapContent - invalid argument")  
	end
end

TILES.LayerMethods.SetContent = function(layer, content)
	local clone = TILES.LayerMethods.Clone(layer)
	if type(content) == "table" then
		for n = 0, clone.ContentSize-1 do
			if content[n+1] then
				clone.Content[n] = content[n+1]
			end
		end
	end
	return clone
end

TILES.LayerMethods.SetTile = function(layer, content, x, y)
	local clone = TILES.LayerMethods.Clone(layer)
	if x >= 0 and x < clone.X and y >= 0 and y < clone.Y then
		if type(content) == "number" then
			clone.Content[x + y*clone.Width] = content
		elseif type(content) == "function" then
			local params = {
				LayerX = x,
				LayerY = y,
				LayerTile = clone.Content[x + y*clone.Width],
				PlaneX = clone.X + x,
				PlaneY = clone.Y + y,
				PlaneTile = clone.PRoot.Tiles[clone.X + x + (clone.Y + y)*clone.PRoot.Width]
			}
			local res = content(params)
			clone.Content[x + y*clone.Width] = res
		end
	end
	return clone
end

TILES.LayerMethods.SetRow = function(layer, content, row)
	if row >= 0 and row < clone.Y then
		local clone = TILES.LayerMethods.Clone(layer)
		if type(content) == "table" then
			for x = 0, clone.Width-1 do
				if content[x+1] then
					clone.Content[x + row*clone.Width] = content[x+1]
				end
			end
		end
		return clone
	else
		error"Layer:SetRow - invalid row number"
	end
end

TILES.LayerMethods.SetColumn = function(layer, content, column)
	if column >= 0 and column < clone.X then
		local clone = TILES.LayerMethods.Clone(layer)
		if type(content) == "table" then
			for y = 0, clone.Height-1 do
				if content[y+1] then
					clone.Content[column + y*clone.Width] = content[y+1]
				end
			end
		end
		return clone
	else
		error"Layer:SetRow - invalid column number"
	end
end

TILES.LayerMethods.GetTile = function(layer, x, y)
	if x >= 0 and x < layer.X and y >= 0 and y < layer.Y then
		return layer.Content[x + y*layer.Width]
	end
end

TILES.LayerMethods.Fill = function(layer, tile)
	local clone = TILES.LayerMethods.Clone(layer)
	for n = 0, clone.ContentSize-1 do
		clone.Content[n] = tile
	end
	return clone
end

return TILES
