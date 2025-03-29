
function main(self)

	if self.State == 0 then
		self.timeZero = GetRealTime()
		self.screenWidth = nRes(31)
		self.X = self.screenWidth + 80 -- outside the screen
		self.idleAni = {"MENU_CRAZYHOOK_IDLE1", "MENU_CRAZYHOOK_BLOCK", "MENU_CRAZYHOOK_STRIKE1", "MENU_CRAZYHOOK_STRIKE2"}
		self.walkAni = {"MENU_CRAZYHOOK_ADVANCE", "MENU_CRAZYHOOK_FASTADVANCE"}
		self.idleSound = {"", "", "CRAZYHOOK_1", "CRAZYHOOK_2"}
		self.State = 100
	end

	if self.State > 0 then
		self:AnimationStep()
	end

	if self.State == 100 then
		self.clawPtr = LoopThroughObjects(function(obj)
			if GetImgStr(obj.Image) == "MENU_CLAW" then
				return obj
			end
		end)
		if self.clawPtr then
			self.Y = self.clawPtr.Y
			self.State = 101
		end
	end

	if self.State == 101 and self.clawPtr.I > 10 and self.timeZero < GetRealTime() then
		local clawIsOnTheLeftSide = self.clawPtr.X < self.screenWidth/2
		if clawIsOnTheLeftSide then
			self.DrawFlags.Mirror = false
			self.dir = 1
			self.X = self.screenWidth + 80
			self.State = 1
		else
			self.DrawFlags.Mirror = true
			self.dir = -1
			self.X = -80
			self.State = 1
		end
	end

	if self.State == 1 then
		self.rand = math.random(2)
		self:SetAnimation(self.walkAni[self.rand])
		self.State = 2
	end

	if self.State == 2 then
		local newX = tonumber(self.X) - (0.33 + self.rand) * self.dir
		self.X = math.round(newX)
		local diff = self.screenWidth/2 - self.X
		local selfIsOnTheRightStop = diff < -210 and diff > -220
		local selfIsOnTheLeftStop = diff < 220 and diff > 210
		if selfIsOnTheRightStop or selfIsOnTheLeftStop then
			self.rand = math.random(4)
			self:SetAnimation(self.idleAni[self.rand])
			if self.idleSound[self.rand] ~= "" then
				PlaySound(self.idleSound[self.rand])
			end
			self.time = GetRealTime() + math.random(300)
			self.State = 3
		end
	end

	if self.State == 3 and GetRealTime() > self.time + 1500 then
		self.rand = self.rand + 1
		if self.rand > 4 then
			self.rand = 1
		end
		self:SetAnimation(self.idleAni[self.rand])
		if self.idleSound[self.rand] ~= "" then
			PlaySound(self.idleSound[self.rand])
		end
		self.time = GetRealTime() + math.random(300)
		self.State = 4
	end

	if self.State == 4 and GetRealTime() > self.time + 1500 then
		self.rand = math.random(2)
		self:SetAnimation(self.walkAni[self.rand])
		self.DrawFlags.Mirror = self.dir == 1
		self.State = 5
	end

	if self.State == 5 then
		local newX = tonumber(self.X) + (0.33 + self.rand) * self.dir
		self.X = math.round(newX)
		if self.X > self.screenWidth + 60 or self.X < -60 then
			self.timeZero = GetRealTime() + math.random(9000, 20000)
			self.State = 101
		end
	end

	if self.State <= 5 then
		--local clawWalksLeft = self.clawPtr.DrawFlags
		if math.abs(self.X - self.clawPtr.X) < 130 then
			self.State = 6
		end
	end

	if self.State == 6 then
		self:SetAnimation"MENU_CRAZYHOOK_JUMP"
		self.State = 7
	end

	if self.State == 7 then
		self.Y = self.Y - 9
		if self.Y < -50 then
			self.State = 8
		end
	end

	if self.State == 8 then
		self.X = self.screenWidth + 80
		self.Y = self.clawPtr.Y
		self.timeZero = GetRealTime() + math.random(7000, 15000)
		self.State = 101
	end
end
