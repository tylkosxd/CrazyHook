function main(self)
    local claw = GetClaw()
    
	if self.State == 0 then
        self.Flags.AlwaysActive = true
        self.State = 5
    else
		
		if self.State == 5 then
			self.State = 2000
		end

        if self.State == 2000 then
            if _CurrentPowerup[0] == Powerup.PlasmaSword then
                self.State = 2001
			else
				self.State = 5
			end
		end

        if self.State == 2001 then
            PrivateCopyCast("GAME_PLASDEATH", 0x5261A0)
            PrivateCopyCast("GAME_PLASSWORDEXPLOSION", 0x52610C)
            PrivateCast(Powerup.PlasmaSword, "int*", 0x44EE11)
            PrivateCopyCast("GAME_EXPLOS_PLASMA", 0x526124, true)
            self.State = 2002
		end

        if self.State == 2002 or self.State == 2003 or self.State == 2004 then  
            if _CurrentPowerup[0] ~= Powerup.PlasmaSword then
                self.State = 2005
            end
		end
		
        if self.State == 2002 then
            if GetClawAttackType"sword" then
                self.State = 2003
            end 
		end

        if self.State == 2003 then
			local pbx = claw.X
			local pby = claw.Y + PData().AttackOffsetY
			local pbv = 700
			local pbdf = ffi.new("DrawFlags_t")
			if PData().Dir == 0 then
				pbx = pbx - PData().AttackOffsetX
				pbv = -700
			else
				pbx = pbx + PData().AttackOffsetX
				pbdf.Mirror = true
			end
			CreateObject{x=pbx, y=pby, z=claw.Z+1, Name="_PlasmaBullet", DrawFlags=pbdf, SpeedX = pbv}
			PlaySound"CLAW_PLASMASWORD"
			self.State = 2004
		end
		
		if self.State == 2004 then
			if not GetClawAttackType("sword") then
				self.State = 2002
			end 
		end
		
		if self.State == 2005 then
            PrivateCopyCast("GAME_FIREDEATH", 0x5261A0)
            PrivateCopyCast("GAME_FIRESWORDEXPLOSION", 0x52610C)
            ffi.cast("int*", 0x44EE11)[0] = Powerup.FireSword
            PrivateCopyCast("GAME_EXPLOS_FIRE", 0x526124, true)
			ffi.cast("char*", 0x526124)[16] = 0
			ffi.cast("char*", 0x526124)[17] = 0
            self.State = 2000
		end
		
    end
end
