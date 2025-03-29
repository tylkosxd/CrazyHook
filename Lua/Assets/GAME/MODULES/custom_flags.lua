ffi.cdef[[
	typedef struct { int flags; } DrawFlags_t;
	typedef struct { int flags; } Flags_t;
	typedef struct { int flags; } PlaneFlags_t;
    typedef struct { int flags; } SpecialFlags_t;
	typedef struct { int flags; } CollisionFlags_t;
	typedef struct { int flags; } InfosFlags_t;
]]

local SetFlagsMetatype = function(name)
	ffi.metatype(name.."_t", {
		__index = function(self, key)
			local flagsTable = assert(_G[name])
			local flag = flagsTable[key]
			if flag then
				return AND(self.flags, flag) ~= 0
			end
			return nil
		end,
		__newindex = function(self, key, val)
			local flagsTable = assert(_G[name])
			local flag = flagsTable[key]
			if flag and type(val) == "boolean" then
				if val == true then
					self.flags = OR(self.flags, flag)
				else
					self.flags = AND(self.flags, NOT(flag))
				end
			end
		end,
		__tostring = function(self)
			return HEX(self.flags)
		end
	})
end

SetFlagsMetatype("Flags")
SetFlagsMetatype("DrawFlags")
SetFlagsMetatype("CollisionFlags")
SetFlagsMetatype("SpecialFlags")
SetFlagsMetatype("PlaneFlags")
SetFlagsMetatype("InfosFlags")