local TILES = {
	Clear = -1, -- used by Game
	Wildcard = -2, -- any tile and out of bounds
	Color = 0xEEEEEEEE -- used by Game, always filled with the same color (plane -> FillColor)
}

ffi.cdef[[
	typedef struct CTileLayer{
		struct CPlane* PRoot;
		int X;
		int Y;
		const int Width;
		const int Height;
		const int ContentSize;
		int Content[?];
	} CTileLayer;
]] -- variable length structure

ffi.cdef[[
	typedef struct CTileLayerIterParams{
		int LayerTile;
		int LayerX;
		int LayerY;
		int PlaneTile;
		int PlaneX;
		int PlaneY;
	} CTileLayerIterParams;
]]

TILES.LayersMethods = {}

ffi.metatype("CTileLayer", {
	__index = function(self, key)
		if TILES.LayersMethods[key] then
			return TILES.LayersMethods[key]
		end
	end,
	__newindex = function(self, key, val)
		if self[key] then
			self[key] = val
			return
		end
		error("CTileRange __newindex")
	end
})

TILES.NewTileLayer = function(plane, x, y, w, h)
	local size = w*h
	return ffi.new("CTileLayer", size, {plane, x, y, w, h, size})
end

TILES.Layers = {}

-- Anchors/Places the layer to the plane:
TILES.Layers.Place = function(layer)
	local count = 0
	for m = 0, layer.Height-1 do
		for n = 0, layer.Width-1 do
			layer.PRoot:PlaceTile(layer.X + n, layer.Y + m, layer.Content[count])
			count = count+1
		end
	end
end

-- Returns the copy of the layer:
TILES.Layers.Clone = function(layer)
	local clone = TILES.NewTileLayer(layer.PRoot, layer.X, layer.Y, layer.Width, layer.Height)
	for n = 0, clone.ContentSize-1 do
		clone.Content[n] = layer.Content[n]
	end
	return clone
end

TILES.Layers.SetPos = function(layer, x, y)
	y = y or layer.Y
	layer.X = x
	layer.Y = y
	return layer
end

TILES.Layers.Shift = function(layer, x, y)
	y = y or 0
	layer.X = layer.X + x
	layer.Y = layer.Y + y
	return layer
end

TILES.Layers.Offset = function(layer, offx, offy, fill)
	offy = offy or 0
	fill = fill or TILES.Wildcard
	if offx == 0 and offy == 0 then
		return layer
	end
	local clone = TILES.Layers.Clone(layer)
	TILES.Layers.Fill(layer, fill)
	for n = 0, layer.ContentSize-1 do
		local nx = n%layer.Width + offx
		local ny = math.floor(n/layer.Width) + offy
		if ny >= 0 and ny < layer.Height and nx >= 0 and nx < layer.Width then
			layer.Content[nx + ny*layer.Width] = clone.Content[n]
		end
	end
	return layer
end

TILES.Layers.ResizeToNew = function(layer, w, h, fill)
	fill = fill or TILES.Wildcard
	local clone = TILES.NewTileLayer(layer.PRoot, layer.X, layer.Y, w, h)
	clone = TILES.Layers.Fill(clone, fill)
	for py = 0, layer.Height-1 do
		for px = 0, layer.Width-1 do
			clone.Content[px + py*clone.Width] = layer.Content[px + py*layer.Width]
		end
	end
	return clone
end

TILES.Layers.SetPlane = function(layer, plane)
	plane = ffi.istype("CPlane*", plane) and plane or GetPlane(plane)
	if plane == nil then
		MessageBox"Layer:SetPlane - invalid plane"
		return
	end
	layer.PRoot = plane
	return layer
end

TILES.Layers.MergeToNew = function(L1, L2, fill)
	local posx, posy = math.min(L1.X, L2.X), math.min(L1.Y, L2.Y)
	local width = math.max(L1.X+L1.Width, L2.X+L2.Width) - posx
	local height = math.max(L1.Y+L1.Height, L2.Y+L2.Height) - posy

	local clone = TILES.Layers.ResizeToNew(L1, width, height, fill)
	TILES.Layers.SetPos(clone, posx, posy)
	TILES.Layers.Offset(clone, L1.X - posx, L1.Y - posy, fill)

	local clone2 = TILES.Layers.ResizeToNew(L2, width, height)
	TILES.Layers.SetPos(clone2, posx, posy)
	TILES.Layers.Offset(clone2, L2.X - posx, L2.Y - posy)

	for n = 0, clone.ContentSize-1 do
		--MessageBox(table.concat({"i =", n, "x =", n%clone.Height, "y =", math.floor(n/clone.Height), "\n", clone.Content[n], "->", clone2.Content[n]}, " "))
		if clone2.Content[n] ~= TILES.Wildcard then
			clone.Content[n] = clone2.Content[n]
		end
	end
	return clone
end

TILES.Layers.Merge = function(layer, second)
	if layer.X + layer.Width < second.X or
	layer.Y + layer.Height < second.Y or
	second.X + second.Width < layer.X or
	second.Y + second.Height < layer.Y then
		return layer
	end

	local clone = TILES.Layers.ResizeToNew(second, layer.Width, layer.Height)
	TILES.Layers.SetPos(clone, layer.X, layer.Y)
	TILES.Layers.Offset(clone, second.X - layer.X, second.Y - layer.Y)

	for n = 0, layer.ContentSize-1 do
		if clone.Content[n] ~= TILES.Wildcard then
			layer.Content[n] = clone.Content[n]
		end
	end
	return layer
end

TILES.Layers.Map = function(layer, fun, ...)
    if type(fun) ~= "function" then
        MessageBox"Layer:MapContent - invalid argument, function expected"
        return layer
    end
	local clone = TILES.Layers.Clone(layer)
	local count = 0
	local params = ffi.new("CTileLayerIterParams")
	for y = 0, clone.Height-1 do
		for x = 0, clone.Width-1 do
			local px, py = clone.X + x, clone.Y + y
			params.LayerTile = clone.Content[y*clone.Width + x]
			params.LayerX = x
			params.LayerY = y
			params.PlaneTile = clone.PRoot.Tiles[py*clone.PRoot.Width + px]
			params.PlaneX = px
			params.PlaneY = py
			layer.Content[count] = fun(params, ...) or clone.Content[count]
			count = count+1
		end
	end
	return layer
end

TILES.Layers.SetContent = function(layer, content)
	local one_index = type(content) == "table" and 1 or 0
	for n = 0, layer.ContentSize-1 do
		layer.Content[n] = content[n + one_index] or layer.Content[n]
	end
	return layer
end

TILES.Layers.GetContentCopy = function(layer)
	local copy = {}
	for n = 0, layer.ContentSize-1 do
		table.insert(copy, layer.Content[n])
	end
	return copy
end

TILES.Layers.SetTile = function(layer, content, x, y)
	if type(content) ~= "number" then
		MessageBox"Layer:SetTile - the tile to set must be a number"
        return layer
	end
	y = y or 0
	if x < 0 or x >= layer.Width or y < 0 or y >= layer.Height then
		return layer
	end
	layer.Content[x + y*layer.Width] = content
	return layer
end

TILES.Layers.SetRow = function(layer, content, row)
	if type(row) ~= "number" or row < 0 or row >= layer.Height then
		return layer
	end
	if type(content) == "number" then
		for x = 0, layer.Width-1 do
			layer.Content[x + row*layer.Width] = content
		end
	end
	if type(content) == "table" then
		for x = 1, layer.Width do
			if type(content[x]) == "number" then
				layer.Content[x + row*layer.Width - 1] = content[x]
			end
		end
	end
	return layer
end

TILES.Layers.SetColumn = function(layer, content, column)
	if type(column) ~= "number" or column < 0 or column >= layer.Width then
		return layer
	end
	if type(content) == "number" then
		for y = 0, layer.Height-1 do
			layer.Content[column + y*layer.Width] = content
		end
	end
	if type(content) == "table" then
		for y = 1, layer.Height do
			if type(content[y]) == "number" then
				layer.Content[column + (y-1)*layer.Width] = content[y]
			end
		end
	end
	return layer
end

TILES.Layers.GetTile = function(layer, x, y)
	if x >= 0 and x < layer.X and y >= 0 and y < layer.Y then
		return layer.Content[x + y*layer.Width]
	end
end

TILES.Layers.Fill = function(layer, tile)
	for n = 0, layer.ContentSize-1 do
		layer.Content[n] = tile
	end
	return layer
end


return TILES