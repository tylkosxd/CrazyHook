local function accel(t, dir)
    local a = 0.7
    local t_max = math.floor(10000/a)
    local v_min = 8
    local delta = GetTime() - t
    if AND(GetInput(),1) ~= 0 or delta >= t_max then
        return 18*dir
    else
        return math.floor((v_min + a*delta/1000))*dir
    end
end

function main(self)

	local claw = GetClaw()
	local input = GetInput()

        if self.State == 0 then
            self.Flags.AlwaysActive = true
            self.DrawFlags.NoDraw = true
            self.time = {Ls = 0, Rs = 0, Us = 0, Ds = 0}
            self.State = 1000
        end

        if self.State == 1000 then
            self.State = 1001
        elseif self.State == 1001 then
            self.State = 1000
        end

        if self.State == 2000 then
		    claw.State = 5008
		    claw.DrawFlags.Invert = true
		    claw.HitTypeFlags = 0xB50500 -- claw invulnerable
		    claw:SetAnimation("GAME_NULL")
		    claw:SetFrame(401)
		    claw.PhysicsType = 8 -- claw won't interact with any tile (all tiles will be clear)
            claw.Flags.flags = OR(claw.Flags.flags,0x80)
            self.X, self.Y = claw.X, claw.Y
            self.State = 2001
        end

        if self.State == 2001 then       
		    if AND(input,0x1000000) ~= 0 and AND(input,0x2000000) == 0 then 
			    PlayerData().Dir = 0 
			    claw.DrawFlags.Mirror = true
                self.time.Rs = 0
                if self.time.Ls == 0 then
                    self.time.Ls = GetTime()
                end
                self.SpeedX = accel(self.time.Ls, -1)
		    end
		    if AND(input,0x2000000) ~= 0 and AND(input,0x1000000) == 0 then 
			    PlayerData().Dir = 1 
			    claw.DrawFlags.Mirror = false 
                self.time.Ls = 0
                if self.time.Rs == 0 then
                    self.time.Rs = GetTime()
                end
                self.SpeedX = accel(self.time.Rs, 1)
		    end
            if AND(input,0x2000000) == 0 and AND(input,0x1000000) == 0 then
                self.time.Ls = 0
                self.time.Rs = 0
                self.SpeedX = 0
            end
		    if AND(input,0x4000000) ~= 0 and AND(input,0x8000000) == 0 then 
			    self.time.Ds = 0
                if self.time.Us == 0 then
                    self.time.Us = GetTime()
                end
                self.SpeedY = accel(self.time.Us, -1)
		    end
		    if AND(input,0x8000000) ~= 0 and AND(input,0x4000000) == 0 then 
			    self.time.Us = 0
                if self.time.Ds == 0 then
                    self.time.Ds = GetTime()
                end
                self.SpeedY = accel(self.time.Ds, 1)
		    end
            if AND(input,0x8000000) == 0 and AND(input,0x4000000) == 0 then
                self.time.Us = 0
                self.time.Ds = 0
                self.SpeedY = 0
            end
            self.X = self.X + self.SpeedX
            self.Y = self.Y + self.SpeedY
		    claw.X, claw.Y = self.X, self.Y
            if claw.Health <= 0 then
                self.State = 3000
            end
        end

        if self.State == 3000 then
            claw.DrawFlags.Invert = false
            if claw.Health > 0 then
	            claw.HitTypeFlags = 0x1B50544 -- claw not invulnerable 0x1b50544
                claw.PhysicsType = 1
                ClawJump(0)
            end
            self.State = 1000
        end
end
