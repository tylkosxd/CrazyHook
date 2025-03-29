--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- [[ General utilites ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local GEN = {}

GEN.SafeRequire = function(moduleName)
	local success, module = pcall(require, moduleName)
	return success and module or nil
end

GEN.EscapeMagicChars = function(str)
	str = str:gsub("%%", "%%%%")
	str = str:gsub("([%^$()%+%[%]])", "%%%1")
	return str
end

GEN.TableContains = function(tab, val)
    for _,v in pairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

GEN.ITableContains = function(tab, val)
    for _,v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

GEN.GetTableKey = function(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

GEN.GetITableKey = function(tab, value)
    for k,v in ipairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

GEN.ClearTable = function(tab)
    for k,_ in pairs(tab) do
        tab[k] = nil
    end
end

GEN.GetCStr = function(str)
    local c_str = ffi.new("char[?]", #str+1)
    ffi.copy(c_str, str)
    return c_str
end

return GEN