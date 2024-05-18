-- Object metatype:

ffi.metatype("ObjectA", 
    {
	    __index = function(self, key)
            -- Compatibility with previous version(-s):
            if key == "_field_180" then
                return self.SpecialFlags.flags
            end
            --.--
		    local ok, result = pcall(function()
			    return self._v[key]
		    end)
		    if ok then
			    return result
		    end
		    local data = _objects_data[_GetObjectsAddress(self)]
		    if data then
			    local result = data[key]
			    if result ~= nil then
				    return result
			    end
		    end
		    if Object[key] then
			    return Object[key]
		    end
	    end,
	    __newindex = function(self, key, val)
            -- Compatibility with previous version(-s):
            if key == "_field_180" then
                self.SpecialFlags.flags = val
                return
            end
            --.--
		    local ok = pcall(function()
			    return self._v[key]
		    end)
		    if ok then
			    self._v[key] = val
			    return
		    end
		    local data = _objects_data[_GetObjectsAddress(self)]
		    if data then
			    data[key] = val
			    return
		    end
		    error("ObjectA __newindex " .. _GetLogicName(self) .. " " .. key .. " " .. tostring(val))
	    end
    }
)

-- PlayerData metatype,
-- for the compatibility with previous version(-s):

ffi.metatype("PData", 
    {
	    __index = function(self, key)
		    local good, result = pcall(function()
			    return ffi.cast("NewPDataType*", self)[key]
		    end)
		    if good then
			    return result
            end 
            local ok = pcall(function()
			    return self[key]
		    end)
            if ok then
                return self[key]
            end
	    end,
        __newindex = function(self, key, val)
            local good = pcall(function()
			    return ffi.cast("NewPDataType*", self)[key]
		    end)
		    if good then
			    ffi.cast("NewPDataType*", self)[key] = val
			    return
		    end
            local ok = pcall(function()
			    return self[key]
		    end)
		    if ok then
			    self[key] = val
			    return
		    end
		    error("PData __newindex " .. key .. " " .. tostring(val))
	    end
    }
)


