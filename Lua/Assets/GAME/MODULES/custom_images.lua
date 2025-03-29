
-- Graph type, contains image data and its settings:
ffi.cdef[[
    typedef struct CGraphV {
        int _f_0;
        int _f_4;
        int _f_8;
        void* ImgData;
        int _f_10;
        int Flag;
        int Color;
        int* ColorTable;
    } CGraphV;

    typedef struct CGraphA {
        void* const _vtable;
        int ID;
        int _field_8;
        int* const _Game_;
        int Width;
        int Height;
        int CenterX;
        int CenterY;
        int OffsetX;
        int OffsetY;
        int _field_28;
        int _field_2C;
        CGraphV* _v;
    } CGraphA;

	typedef struct CImage {
		void* const _vtable;
		const int ID;
		int _f_8;
		void* const _Game_;
		void* _f_10;
		CGraphA** Images;
		const int NumImages;
		const int NumImages;
		int _f_20;
		const char Name[64];
		const int FirstImageNum;
		const int LastImageNum;
	} CImage;
]]

ffi.metatype("CGraphA", {
	__index = function(self, key)
		if self._v ~= nil then
			local ok, result = pcall(function()
				return self._v[key]
			end)
			if ok then
				return result
			end
		end
	end,
	__newindex = function(self, key, val)
		if self._v ~= nil then
			local ok = pcall(function()
				return self._v[key]
			end)
			if ok then
				self._v[key] = val
				return
			end
		end
	end
})

ffi.metatype("CImage", {
	__index = function(self, i)
		if type(i) == "number" then
			return self.Images[i]
		end
	end,
	__tostring = function(self)
		local str = self.Name
		if ffi.cast("int", str) > 36 then -- 36 is the return value of ffi.offsetof("CImage", "Name")
			return ffi.string(str)
		else
			return nil
		end
	end,
	__eq = function(self, other)
		if type(other) == "string" then
			return tostring(self) == other
		end
	end
})

local IMAGES = {}

IMAGES.SetImgFlag = function(img, flag)
	img = type(img) == "string" and GetImage(img) or ffi.istype("ObjectA*", img) and img.Image or img
    if img == nil then return end -- check for null pointer - the 'not' operator doesn't work with C data.
	if type(flag) == "number" and flag > 0 and flag <= 8 and flag ~= 4 then -- flag 4 crashes the game, and the other won't render the image
		mdl_exe._SetImgFlag(img, flag)
	else
		MessageBox("SetImgFlag - invalid image flag " .. tostring(flag))
	end
end

IMAGES.SetImgColor = function(img, color)
	img = type(img) == "string" and GetImage(img) or ffi.istype("ObjectA*", img) and img.Image or img
    if img == nil then return end
	if type(color) == "number" then
		mdl_exe._SetImgColor(img, color)
	else
		MessageBox("SetImgColor - invalid color")
	end
end

IMAGES.SetImgCLT = function(img, clt)
	img = type(img) == "string" and GetImage(img) or ffi.istype("ObjectA*", img) and img.Image or img
    if img == nil then return end
	clt = type(clt) == "string" and clt:upper() or ""
	if clt == "LIGHT" then
		mdl_exe._SetImgCLT(img, nRes(11,474))
	elseif clt == "AVERAGE" then
		mdl_exe._SetImgCLT(img, nRes(11,475))
	else
		MessageBox("SetImgCLT - invalid color table. \nUse 'Average' or 'Light'")
	end
end

return IMAGES