--[[ This module, along with the '_ClawCPowerup' global logic (in LOGICS folder), handles the custom powerups.]]

local function destroyCatnipGlitter()
    if PlayerData().CatnipGlitter ~= nil then
		PlayerData().CatnipGlitter:Destroy()
		PlayerData()._CGlit = 0
	end
end

local CPOW = {
    PtrPowerupHandler = nil
}

CPOW.CustomPowerup = function(name, time)
	if not name then return end
    time = time or 30000
    if _PowerupTime[0] == 0 or _CurrentPowerup[0] ~= Powerup.Custom then
        CPOW.PtrPowerupHandler = nil
    end
    destroyCatnipGlitter()
	if CPOW.PtrPowerupHandler ~= nil and CPOW.PtrPowerupHandler.CPN ~= name then
		-- check for null pointer above - the not operator doesn't work with C data.
		CPOW.PtrPowerupHandler:Destroy()
		CPOW.PtrPowerupHandler = nil
		mdl_exe._ClawGivePowerup(0,0)
	end
	mdl_exe._ClawGivePowerup(Powerup.Custom, time)
	if CPOW.PtrPowerupHandler == nil then
		CPOW.PtrPowerupHandler = CreateObject{name="_CustomPowerupHandler"}
	end
	CPOW.PtrPowerupHandler.Flags.AlwaysActive = true
	CPOW.PtrPowerupHandler.CPN = name
end

return CPOW