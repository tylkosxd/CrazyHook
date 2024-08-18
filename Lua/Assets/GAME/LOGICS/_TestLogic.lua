
function main(self)
	if self.State == 0 then
		self.Flags.AlwaysActive, self.DrawFlags.NoDraw = true, true
		self.count = 0
		self.State = 1
	end

	if self.State == 1 and GetInput"Special" then
        self.State = 2
	end

	if self.State == 2 and not GetInput"Special" then

		self.State = 3
	end
	
	if self.State == 3 and KeyPressed"5" then
		GetTime = function() return 100 end
		MessageBox(version)
		self.State = 2
	end
	
	if self.State > 0 then
		
	end
end