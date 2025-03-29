--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Inputs module ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

local KEYS = {}

ffi.cdef[[
    typedef struct CControlsMgr{
        void* const _f_0;
        int InputState1;
        int InputState2;
        int InputState3;
        struct {
            int Jump;
            int Attack;
            int Projectile;
            int ToggleProjectile;
            int Unused;
            int Lift;
            int Pistol;
            int Magic;
            int Dynamite;
            int Special;
        } Controller;
        struct {
            int Left;
            int Right;
            int Up;
            int Down;
            int Jump;
            int Attack;
            int Projectile;
            int ToggleProjectile;
            int Unused;
            int Lift;
            int Pistol;
            int Magic;
            int Dynamite;
            int Special;
        } Keyboard;
        int _f_70;
        void* const _vtable;
        void* const _f_78;
        int _f_7C;
        int _f_80;
        void* const _f_84;
        void* const _f_88;
        int _f_8C;
        int _f_90;
    } CControlsMgr;
]]

local function formatKey(key)
    if type(key) == "string" then
        if #key == 1 and string.byte(key) >= 0x30 and string.byte(key) <= 0x39 then
            return string.byte(key)
        end
        return VKey[key] or InputFlags[key] and GetGameControls().Keyboard[key] or VKey[key:upper()] or nil
    end
    return key
end

KEYS.GetInput = function(input)
    if not input then
	    return GetGameControls().InputState2
    end
	if type(input) == "number" then
		return AND(GetGameControls().InputState2, input) ~= 0
    end
	if type(input) == "string" then
        return AND(GetGameControls().InputState2, InputFlags[input]) ~= 0
    end
end

KEYS.KeyPressed = function(key)
	key = formatKey(key)
	return mdl_exe._KeyPressed(key) ~= 0
end

KEYS.GetKeyInput = function(key)
	key = formatKey(key)
	return ffi.C.GetAsyncKeyState(key) == -32768
end

KEYS.InputPress = function(key)
	key = formatKey(key)
	local input = ffi.new("Input[1]")
	input[0].iType = 1
	input[0].ki = {key, 0, 0, 0, nil}
	return ffi.C.SendInput(1, input, ffi.sizeof(input))
end

KEYS.InputRelease = function(key)
	key = formatKey(key)
	local input = ffi.new("Input[1]")
	input[0].iType = 1
	input[0].ki = {key, 0, 2, 0, nil}
	return ffi.C.SendInput(1, input, ffi.sizeof(input))
end

KEYS.GetCursorPos = function()
    local p = ffi.new("Point[1]")
    ffi.C.GetCursorPos(p)
    return p[0]
end

return KEYS