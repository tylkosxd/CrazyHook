
ffi.cdef[[
    typedef struct CSingleTileA {
        const int Type;
        const int TileWidth;
        const int TileHeight;
        int Attribute;
    } CSingleTileA;
    
    typedef struct CDoubleTileA {
        const int Type;
        const int TileWidth;
        const int TileHeight;
        int Attribute;
        int RectAttribute;
        Rect TileRect;
    } CDoubleTileA;

    typedef struct CMaskTileA {
        const int Type;
        const int TileWidth;
        const int TileHeight;
        const int Attribute;
        const int _unknown;
        int* Mask;
    } CMaskTileA;
]]

ffi.metatype("CSingleTileA", {
    __index = function(self, key)
        if key == "RectAttribute" or key == "TileRect" then
            return nil
        end
    end
})

-- Get tile attributes/properties:
return function(id)
	if Game(9) == 0 or Game(9,19) == 0 or type(id) ~= "number" then return end
    if id < 0 or id > Game(9, 20) then return end -- Game(9, 20) - the number of the last tile in the main plane's tileset
	local tile = Game(9, 19, id)
	local tType = CastGet(tile, 0)
	if tType == TileType.Single then
		return ffi.cast("CSingleTileA*", tile)
	elseif tType == TileType.Double then
		return ffi.cast("CDoubleTileA*", tile)
	elseif tType == TileType.Mask then
		return ffi.cast("CMaskTileA*", tile)
	end
end