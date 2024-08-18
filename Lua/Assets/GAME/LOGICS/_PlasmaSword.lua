
function main(self)
	if self.State == 0 then
        self.AttackTypeFlags = 2
        self.AttackRect = {-28, -36, 27, 27}
		self:SetImage"GAME_POWERUPS_NEWPLASMASWORD"
		self:SetAnimation"GAME_CYCLE50"
		self:CreateGlitter()
		if self.Smarts == 0 then
			self.Smarts = 30
		else
			self.Smarts = self.Smarts / 1000
		end
        self.State = 5
    elseif self.State == 5 then
        self:AnimationStep()
	end
end

function attack(self)
	ClawSound"CLAW_1110064"
    PlaySound"GAME_PICKUP1"
    ClawGivePowerup(Powerup.PlasmaSword, self.Smarts)
	self:DestroyGlitter()
	self:Destroy()
end
