--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Objects modules ]] -------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module contains some functions that deal with objects. For description look in OBJECTS section in CrazyHook.lua ]]

local OBJECTS = require'custom_objects.objects_struct'

OBJECTS.CreateObject = function(params)
	if type(params) ~= "table" then
		error("CreateObject - argument must be a table!")
	end
	local ip = {
		id 			= params.ID 		or params.id 		or -1,
		logic 		= params.Logic 		or params.logic 	or "CustomLogic",
		ref 		= params.Ref 		or params.ref 		or Game(2),
		x 			= params.X 			or params.x 		or GetCameraPos().X,
		y 			= params.Y 			or params.y 		or GetCameraPos().Y,
		z 			= params.Z 			or params.z 		or 0,
		flags		= params.flags 		or 0x40000,
		name		= params.Name 		or params.name 		or nil,
		image		= params.Image 		or params.image 	or nil,
		animation	= params.Animation 	or params.animation or nil,
		sound		= params.Sound 		or params.sound 	or nil,
		i			= params.I 			or params.i			or nil
	}
	if ip.id ~= - 1 and OBJECTS.ObjectsList[ip.id] then
		MessageBox("CreateObject - the provided ID is already taken!")
		return
	end
	if ip.logic ~= "CustomLogic" and ip.name then
		MessageBox("You can call CreateObject with 'name' parameter only for CustomLogic!")
		return
	end
	local object = mdl_exe._CreateObject(ip.ref, ip.id, ip.x, ip.y, ip.z, ip.logic, ip.flags)
	if ip.id ~= -1 then
		OBJECTS.ObjectsList[ip.id] = object
	end
	if ip.name then
		OBJECTS.ObjectsNames[tonumber(ffi.cast("int", object))] = ip.name
	end
	if ip.image then
		object:SetImage(ip.image)
	end
	if ip.animation then
		object:SetAnimation(ip.animation)
	end
	if ip.sound then
		object:SetSound(ip.sound)
	end
	for k,v in pairs(params) do
		if not ip[k:lower()] then
			object[k] = v
		end
	end
	if params.Flags then
		object.Flags = params.Flags
	end
	if ip.i and type(ip.i) == "number" and ip.i > 0 then
		object:SetFrame(ip.i)
	end
	object:Logic()
	return object
end

OBJECTS.CreateGoodie = function(tab)
	tab.x = tab.x or tab.X or GetClaw().X
	tab.y = tab.y or tab.Y or GetClaw().Y
	tab.z = tab.z or tab.Z or 1000
	tab.powerup = tab.powerup or tab.Powerup or DropItem.Coin
	mdl_exe._CreateGoodie(Game(), tab.x, tab.y, tab.z, tab.powerup)
end

local function GetScreenCenter(coord)
	local screen = PlayAreaRect[0]
	return coord == "X" and math.floor(0.5 + screen.Right/2) or coord == "Y" and math.floor(0.5 + screen.Bottom/2)
end

OBJECTS.CreateHUDObject = function(params)
	if type(params) ~= "table" then
		MessageBox("CreateHUDObject - argument must be a table!")
		return
	end
	params.X = params.X or params.x or GetScreenCenter("X")
	params.Y = params.Y or params.y or GetScreenCenter("Y")
	params.x, params.y = nil, nil
	params.Z = params.Z or params.z or 10000
	params.z = nil
	params.Flags = ffi.new("Flags_t", Flags.AlwaysActive)
    return CreateObject(params)
end

OBJECTS.GetAvailableID = function()
	local id = 1
	while true do
		if OBJECTS.ObjectsList[id] ~= nil then
			id = id + 1
		else
			return id
		end
	end
end

OBJECTS.LoopThroughObjects = function(fun, arg)
    local ret = nil
	if Game(2) == 0 then return end
	-- this is the first node of the doubly linked list containing all the objects that are currently active (with some exceptions):
	local node = ffi.cast("node*", Game(2,5))
	-- Loop through the list:
	while node ~= nil do
		if type(fun) == "function" then
			ret = fun(node.object, arg)
		else
			node.object:Logic()
		end
		if ret then return ret end
		node = node.next
	end
    return ret
end

OBJECTS.LoopThroughInterfaces = function(fun, arg)
    local ret = nil
    local MS = mdl_exe.MultiStats[0]
	if MS == nil then return end
	local node = MS.Childs -- this is the first node of the doubly linked list containing all interface objects
	while node ~= nil do
		if type(fun) == "function" then
			ret = fun(node.object, arg)
		else
			node.object:Logic()
		end
		if ret ~= nil then return ret end
		node = node.next
	end
    return ret
end

OBJECTS.GetInterface = function(name, digit)
	if type(name) == "string" then
		if not InterfaceLogics[name] then
			MessageBox("GetInterface - wrong logic!")
			return
		else
			name = InterfaceLogics[name]
		end
	end
	if type(name) ~= "number" then
		MessageBox("GetInterface - first argument must be a string or a number.")
		return
	end
	if digit and type(digit) ~= "number" then
		MessageBox("GetInterface - second argument must be nil or a number.")
		return
	end
	local findInterface = function(obj)
		if tonumber(ffi.cast("int", obj.Logic)) ~= name then
			return
		end
		if not digit or digit <= 0 or obj._userdata == nil then
			return obj
		end
		if digit <= obj._userdata[12] then
			return ffi.cast("ObjectA*", obj._userdata[digit+12])
		end
	end
    return LoopThroughInterfaces(findInterface)
end

OBJECTS.CreateGlitter = function(obj, img)
    if obj.GlitterPointer ~= nil then return end
	if not img then img = "gold" end
	img = img:lower()
	if img == "gold" then
		img = "GAME_GLITTER"
	elseif img == "green" then
		img = "GAME_GREENGLITTER"
	elseif img == "red" then
		img = "GAME_GLITTERRED"
	elseif img == "warp" or img == "purple" then
		img = "GAME_WARPGLITTER"
	else
		img = "GAME_GLITTER"
	end
	obj.GlitterPointer = CreateObject{x=obj.X, y=obj.Y, z=obj.Z, logic="PowerupGlitter", image=img}
end

OBJECTS.GetAction = function(obj)
    local actions = mdl_exe.ObjectActions[0]
    local i = obj.State
    if i >= mdl_exe.ObjectMinAction[0] and i <= mdl_exe.ObjectMaxAction[0] then
        return ffi.string( ffi.cast("const char*", actions[i-2000]) )
    end
    return ""
end

OBJECTS.ShowData = function(obj)
	local data = {"Data:\n"}
	for k,_ in pairs(obj:GetData()) do
		table.insert(data, k)
	end
	MessageBox(table.concat(data), "\n")
end

local function isInRect(obj1, obj2, rect)
	return obj1.X > obj2.X + rect.Left and obj1.Y > obj2.Y + rect.Top and obj1.X < obj2.X + rect.Right and obj1.Y < obj2.Y + rect.Bottom
end

OBJECTS.InRect = function(obj1, obj2, rect)
	if not obj2 then return false end
	if not rect then return false end
	if type(rect) == "string" then
		rect = rect:lower()
		rect = (rect == "hit" or rect == "hitrect") and obj2.HitRect
		or (rect == "attack" or rect == "attackrect") and obj2.AttackRect
		or (rect == "move" or rect == "moverect") and obj2.MoveRect
		or obj2.ClipRect
	end
	return isInRect(obj1, obj2, rect)
end

return OBJECTS