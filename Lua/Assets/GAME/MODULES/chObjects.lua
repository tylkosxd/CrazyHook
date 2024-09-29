local OBJECTS = { 
}

function OBJECTS.CreateObject(params)
	if type(params) == "table" then
		local ip = {
			id 			= params.ID 		or params.id 		or -1,
			logic 		= params.Logic 		or params.logic 	or "CustomLogic",
			ref 		= params.Ref 		or params.ref 		or Game(2),
			x 			= params.X 			or params.x 		or GetCameraPos().X,
			y 			= params.Y 			or params.y 		or GetCameraPos().Y,
			z 			= params.Z 			or params.z 		or 0,
			flags		= params.flags 		or 0x40000,
			name		= params.Name 		or params.name 		or "",
			image		= params.Image 		or params.image 	or "",
			animation	= params.Animation 	or params.animation or "",
			sound		= params.Sound 		or params.sound 	or "",
			i			= params.I 			or params.i			or 0
		}
        if ip.id ~= - 1 and _objects[ip.id] then
            error("CreateObject - object with ID ".. ip.id .. " already exists")
        end
        if ip.logic ~= "CustomLogic" and ip.name ~= "" then
            error("You can call CreateObject with 'name' only for CustomLogic, not for " .. ip.logic .. "!")
        end
        local object = mdl_exe._CreateObject(ip.ref, ip.id, ip.x, ip.y, ip.z, ip.logic, ip.flags)
        if ip.id ~= -1 then
            _objects[ip.id] = object
        end
		if ip.name ~= "" then
			_objects_names[tonumber(ffi.cast("int", object))] = ip.name
		end
		if ip.image ~= "" then
			object:SetImage(ip.image)
		end
		if ip.animation ~= "" then
			object:SetAnimation(ip.animation)
		end
		if ip.sound ~= "" then
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
		if ip.i ~= 0 then
			object:SetFrame(ip.i)
		end
		
		object:Logic()
		return object
	else
		error("CreateObject - table expected!")
	end
end

function OBJECTS.GetAvailableID()
	local id = 1
	while true do
		if _objects[id] ~= nil then
			id = id + 1
		else
			return id
		end
	end
end

function OBJECTS.LoopThroughObjects(fun, arg)
    local ret = nil
	if Game(2) ~= 0 then
        -- this is the first node of the doubly linked list containing all the objects that are currently active (with some exceptions):
		local node = ffi.cast("node*", Game(2,5))
        -- Loop through the list:
		while node ~= nil do
			local obj = node.object
			node = node.next
			if type(fun) == "function" then ret = fun(obj, arg) else obj:Logic() end
            if ret then return ret end
		end
	end
    return ret
end

function OBJECTS.CreateGoodie(tab)
	if not tab.x then tab.x = GetClaw().X end
	if not tab.y then tab.y = GetClaw().Y end
	if not tab.z then tab.z = 1000 end
	if not tab.powerup then tab.powerup = 33 end
	mdl_exe._CreateGoodie(Game(), tab.x, tab.y, tab.z, tab.powerup)
end

function OBJECTS.CreateHUDObject(Rx, Ry, Rz, image)
    local window = PlayAreaRect[0]

    if string.lower(Rx) == "random" then 
        Rx = math.random(window.Right)
    elseif string.lower(Rx) == "center" then
        Rx = math.floor(0.5 + window.Right/2)
    elseif Rx < 0 then 
        Rx = window.Right + Rx
    end
        
    if string.lower(Ry) == "random" then 
        Ry = math.random(window.Bottom) 
    elseif string.lower(Ry) == "center" then
        Ry = math.floor(0.5 + window.Bottom/2)
    elseif Ry < 0 then 
        Ry = window.Bottom + Ry
    end

    local f = ffi.new("Flags_t")
    f.AlwaysActive = true
    return CreateObject{x=Rx,y=Ry,z=Rz,logic="BackgroundLogic",image=image, Flags=f}
end

function OBJECTS.LoopThroughInterfaces(fun, arg)
    local ret = nil
    local MS = mdl_exe.MultiStats[0]
	if MS ~= nil then
		local node = MS.Childs -- this is the first node of the doubly linked list containing all interface objects
		while node ~= nil do
		    local obj = node.object
			node = node.next
			if type(fun) == "function" then ret = fun(obj, arg) else obj:Logic() end
            if ret ~= nil then return ret end
		end  
	end
    return ret
end

function OBJECTS.GetInterface(name, digit)
	local fun = function(obj, name)
        if InterfaceLogics[name] then
			if tonumber(ffi.cast("int", obj.Logic)) == InterfaceLogics[name] then
                if not digit or digit == 0 then
				    return obj
                elseif digit > 0 then
					if obj._userdata ~= nil then
						if digit <= obj._userdata[12] then
							local object = ffi.cast("ObjectA*", obj._userdata[digit+12])
							return object
						end
					else
						error("GetInterface - object with logic ".. name .." doesn't have any userdata!")
					end
                end
			end
		else
			error("GetInterface - object with logic ".. name .." doesn't exist!")
        end
	end
    return LoopThroughInterfaces(fun, name)
end

function OBJECTS.CreateGlitter(obj, img)
    if obj.GlitterPointer == nil then
        if not img or string.lower(img) == "gold" then 
			img = "GAME_GLITTER"
        elseif string.lower(img) == "green" then 
			img = "GAME_GREENGLITTER"
        elseif string.lower(img) == "red" then 
			img = "GAME_GLITTERRED"
        elseif string.lower(img) == "warp" then 
			img = "GAME_WARPGLITTER"
        end
        obj.GlitterPointer = CreateObject{x=obj.X, y=obj.Y, z=obj.Z, logic="PowerupGlitter", image=img}
    end
end

function OBJECTS.GetAction(obj)
    local actions = mdl_exe.ObjectActions[0]
    local i = obj.State
    if i >= mdl_exe.ObjectMinAction[0] and i <= mdl_exe.ObjectMaxAction[0] then 
        return ffi.string( ffi.cast("const char*", actions[i-2000]) )
    end
    return ""
end

function OBJECTS.InRect(obj1, obj2, rect)
	if obj2 ~= nil then
		if not ffi.istype("Rect", rect) then 
			if ffi.istype("int[4]", rect) then
				return obj1.X > obj2.X + rect[0] and obj1.Y < obj2.Y + rect[1] and obj1.X < obj2.X + rect[2] and obj1.Y < obj2.Y + rect[3]
			elseif type(rect) == "table" and #rect == 4 then
				return obj1.X > obj2.X + rect[1] and obj1.Y < obj2.Y + rect[2] and obj1.X < obj2.X + rect[3] and obj1.Y < obj2.Y + rect[4]
			elseif type(rect) == "string" then
				rect = rect:lower()
				if rect == "hit" or rect == "hitrect" then 
					rect = obj2.HitRect
				elseif rect == "attack" or rect == "attackrect" then 
					rect = obj2.AttackRect
				elseif rect == "move" or rect == "moverect" then 
					rect = obj2.MoveRect
				elseif rect == "clip" or rect == "cliprect" then 
					rect = obj2.ClipRect
				end
			end
		end
		return obj1.X > obj2.X + rect.Left and obj1.Y > obj2.Y + rect.Top and obj1.X < obj2.X + rect.Right and obj1.Y < obj2.Y + rect.Bottom
	end
end

return OBJECTS
