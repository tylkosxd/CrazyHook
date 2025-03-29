function main(object)
	object.Flags.AlwaysActive = true
	local claw = GetClaw()
	if _CurrentPowerup[0] ~= 666 or _PowerupTime[0] == 0 or claw.Health <= 0 then
		object:Destroy()
	end
	if type(object.CPN) == "function" then
		object.CPN(object)
	end
end
