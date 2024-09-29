function main(object)
	object.Flags.AlwaysActive = true
	if _CurrentPowerup[0] ~= 666 or _PowerupTime[0] == 0 or GetClaw().Health <= 0 then
		object:Destroy()
	end
	if type(object.CPN) == "function" then
		object.CPN(object)
	end
end
