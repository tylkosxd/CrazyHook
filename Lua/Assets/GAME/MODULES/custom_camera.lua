--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Camera module ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ This module handles the game's camera (screen position) and contains some functions for manipulating it.]]

local CAM = {PtrCameraObject = nil}

CAM.MapCameraPtr = function() -- this function is called at the end of the level's loading screen.
    CAM.PtrCameraObject = LoopThroughObjects(function(obj)
        if obj.Logic == CaptainClawScreenPosition then return obj end
    end)
end

CAM.CameraToPoint = function(x, y)
    if ffi.istype("Point", x) then
        y = x.y
        x = x.x
    end
	mdl_exe.CameraX[0] = x
	mdl_exe.CameraY[0] = y
    local camera = CAM.PtrCameraObject
    if camera ~= nil and camera.State ~= 8888 then
		camera.State = 8888
	end
end

CAM.CameraToObject = function(object)
	if not ffi.istype("ObjectA*", object) or object == nil then
		MessageBox("CameraToObject - the argument must be an object!")
		return
	end
    CAM.CameraToPoint(object.X, object.Y)
end

CAM.SetCameraPoint = function(x, y)
    local camera = CAM.PtrCameraObject
	if camera == nil then
        MessageBox("Couldn't find the CaptainClawScreenPosition logic")
        return
    end
    if ffi.istype("Point", x) then
        y = x.y
        x = x.x
    end
    camera.State = 9000
    local data = camera._d
    data[0] = x
    data[1] = y
    data[2] = data[0]
    data[3] = data[1]
end

CAM.CameraToClaw = function()
    local camera = CAM.PtrCameraObject
    if camera ~= nil and camera.State ~= 26 and camera.State ~= 5003 then
        camera.State = 24
    end
	mdl_exe.CameraX[0] = -1
	mdl_exe.CameraY[0] = -1
end

CAM.SetCameraToPointSpeed = function(speedX, speedY)
    PrivateCast(speedX, "int*", 0x48971D)
    PrivateCast(speedY, "int*", 0x489722)
end

CAM.GetCameraPoint = function()
    return ffi.cast("Point*", Game(9,23)+132)[0]
end

return CAM