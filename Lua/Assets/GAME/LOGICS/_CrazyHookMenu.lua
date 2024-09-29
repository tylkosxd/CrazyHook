
function main(self)

	if self.State == 0 then
		self.timeZero = GetRealTime()
		self.idleAni = {"MENU_CRAZYHOOK_IDLE1", "MENU_CRAZYHOOK_BLOCK", "MENU_CRAZYHOOK_STRIKE1", "MENU_CRAZYHOOK_STRIKE2"}
		self.walkAni = {"MENU_CRAZYHOOK_ADVANCE", "MENU_CRAZYHOOK_FASTADVANCE"}
		self.idleSound = {"", "", "CRAZYHOOK_1", "CRAZYHOOK_2"}
		self.State = 100
	else
	
		self:AnimationStep()
		
		if self.State == 100 then
			self.clawPtr = LoopThroughObjects(function(obj)
				if GetImgStr(obj.Image) == "MENU_CLAW" then
					return obj
				end
			end)
			self.State = 101
		end
		
		if self.State == 101 and self.clawPtr.I > 10 and GetRealTime() > self.timeZero then
			if self.clawPtr.X < 320 then
				self.DrawFlags.Mirror = false
				self.dir = 1
				self.X = 720
				self.State = 1
			elseif self.clawPtr.X > 320 then
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
			self.X = self.X - self.rand * self.dir
			if (self.X <= 540 and self.X > 530) or (self.X >= 100 and self.X < 110) then
				self.rand = math.random(4)
				self:SetAnimation(self.idleAni[self.rand])
				if self.idleSound[self.rand] ~= "" then
					PlaySound(self.idleSound[self.rand])
				end
				self.time = GetRealTime()
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
			self.time = GetRealTime()
			self.State = 4
		end
		
		if self.State == 4 and GetRealTime() > self.time + 1500 then
			self.rand = math.random(2)
			self:SetAnimation(self.walkAni[self.rand])
			self.DrawFlags.Mirror = self.dir == 1
			self.State = 5
		end
		
		if self.State == 5 then
			self.X = self.X + self.rand * self.dir
			if self.X >= 700 or self.X <= -60 then
				self.timeZero = GetRealTime() + 7777
				self.State = 101
			end
		end
		
		if self.State <= 5 and (self.clawPtr.X > 380 and self.dir == 1) or (self.clawPtr.X < 260 and self.dir == -1) then
			self.State = 6
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
			self.X = 720
			self.Y = 100
			self.timeZero = GetRealTime() + math.random(7000, 15000)
			self.State = 101
		end
		
	end
end