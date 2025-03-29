--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Tiles module ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module handles the planes and layers methods. ]]

local TILES = require"custom_planes.planes_layers"

TILES.GetTileA = require"custom_planes.planes_tile_properties"

ffi.cdef[[
    typedef struct CPlane {
        void* const _vtable;
        const int ID;
        PlaneFlags_t Flags;
        int* const _Game_;
        const float RelativeX;
        const float RelativeY;
        float MovementX;
        float MovementY;
        int* Tiles;
        const int* Rows;
        const int Width;
        const int Height;
        const int WidthPx;
        const int HeightPx;
        const int TileWidth;
        const int TileHeight;
        const Rect ScreenA;
        const Rect Screen;
        const Rect DefTileRect;
        const int ScreenAWidth;
        const int ScreenAHeight;
        const int ScreenACenterX;
        const int ScreenACenterY;
        int Z;
        const int ScreenCenterX;
        const int ScreenCenterY;
        const int Log2TileWidth;
        const int Log2TileHeight;
        int SpeedX;
        int SpeedY;
        int* _f_9C;
        CImage** Tileset;
        const int _f_A4;
        const int _f_A8;
        const int _f_AC;
        void* const _f_B0;
        char Name[64];
        int _f_F4;
        int _f_F8;
        int _f_FC;
        int _f_100;
        int _f_104;
        int _f_108;
        int _f_10C;
        int _f_110;
        int _f_114;
        int _f_118;
        int _f_11C;
        int _f_120;
        int _f_124;
        int _f_128;
        int _f_12C;
        int _f_130;
        int _f_134;
        int _f_138;
        int _f_13C;
        int _f_140;
        int FillColor;
    } CPlane;
]]

TILES.PlanesMethods = {}

ffi.metatype("CPlane", {
	__index = function(self, key)
		if TILES.PlanesMethods[key] then
			return TILES.PlanesMethods[key]
		end
	end,
	__newindex = function(self,key,val)
		if self[key] then
			self[key] = val
			return
		end
		error("CPlane __newindex")
	end,
    __tostring = function(self)
        return ffi.string(self.Name)
    end,
    __eq = function(self, other)
        if type(other) == "string" then
            return ffi.string(self.Name) == other
        end
    end
})

local theCoordinateOnPlane = function(plane, x, y)
	return x >= 0 and x < plane.Width and y >= 0 and y < plane.Height
end

local theTileExists = function(plane, tile)
    if tile == TILES.Clear or tile == TILES.Color then return true end
	local tileset = plane.Tileset[0]
	if tile < tileset.FirstImageNum or tile > tileset.LastImageNum then return false end
	return tileset.Images[tile] ~= nil
end

TILES.Planes = {}

TILES.Planes.GetPlane = function(indexOrName)
    if type(indexOrName) == "number" then
        local index = indexOrName
        local addr = Game(9, 14, index)
        if index < 0 or index >= PlanesCount() or addr == 0 then return end
        return ffi.cast("CPlane*", addr)
    elseif type(indexOrName) == "string" then
        local name = indexOrName
        local addr, plane
        for i = 0, PlanesCount() do
            addr = Game(9, 14, i)
            if addr ~= 0 then
                plane = ffi.cast("CPlane*", addr)
                if ffi.string(plane.Name) == name then
                    return plane
                end
            end
        end
    end
end

TILES.Planes.GetTile = function(plane, x, y)
    if plane == nil then
        MessageBox("GetTile - invalid plane")
		return
	end
	if theCoordinateOnPlane(plane, x, y) then
		return plane.Tiles[x + y * plane.Width]
	end
	return TILES.Wildcard -- returns -2 if out of bounds
end

TILES.Planes.PlaceTile = function(plane, x, y, tile)
    if plane == nil then
        MessageBox("GetTile - invalid plane")
		return
	end
    if theCoordinateOnPlane(plane, x, y) and theTileExists(plane, tile) then
		plane.Tiles[x + y * plane.Width] = tile
    end
	return plane
end

TILES.Planes.CreateTileLayer = function(plane, x, y, w, h)
	if not y and not w and not h then
		if type(x) == "table" and #x == 4 then
			x, y, w, h = x[1], x[2], x[3]-x[1]+1, x[4]-x[2]+1
		elseif ffi.istype("Rect", x) then
			x, y, w, h = x.Left, x.Top, x.Right-x.Left+1, x.Bottom-x.Top+1
		else
			MessageBox("Plane:GetTileLayer - invalid arguments")
			return
		end
	end
	if not x or x < 0 or not y or y < 0 or not w or w < 0 or not h or h < 0 then
		MessageBox("Plane:GetTileLayer - invalid arguments")
		return
	end
	local layer = TILES.NewTileLayer(plane, x, y, w, h)
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

return TILES