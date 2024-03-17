function main(object)

	local claw = GetClaw()
	local input = GetInput()

	if claw.Health <= 0 then 
		claw.DrawFlags.Invert = false 
		object:Destroy()
	elseif object.turn_off then
		GetClaw().DrawFlags.Invert = false
		GetClaw().HitTypeFlags = 28640580 -- claw not invulnerable
		ClawJump(0)
		object:Destroy()
	else
		claw.State = 5008
		claw.DrawFlags.Invert = true
		claw.HitTypeFlags = 11863296 -- claw invulnerability
		claw:SetAnimation("GAME_NULL")
		claw:SetFrame(401)
		claw.PhysicsType = 8 -- claw won't interact with any tile (all tiles will be clear)
		if AND(input,0x1000000)~=0 and AND(input,0x2000000)==0 then 
			object.X = object.X-8 
			PlayerData().Dir = 0 
			claw.DrawFlags.Mirror = true 
		end
		if AND(input,0x2000000)~=0 and AND(input,0x1000000)==0 then 
			object.X = object.X+8 
			PlayerData().Dir = 1 
			claw.DrawFlags.Mirror = false 
		end
		if AND(input,0x4000000)~=0 then 
			object.Y = object.Y-8 
		end
		if AND(input,0x8000000)~=0 then 
			object.Y = object.Y+8 
		end
		claw.Flags.flags = OR(claw.Flags.flags,0x80)
		claw.X,claw.Y = object.X,object.Y
	end
end
