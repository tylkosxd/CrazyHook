function main(self)

	local PLAY_AREA = mdl_exe.PlayAreaRect[0]

	if self.State == 0 then
		self.Flags.AlwaysActive, self.DrawFlags.NoDraw = true, true
		self.normalWidth, self.normalHeight = nRes(31), nRes(32)
        PrivateCast(1, "char*", 0x429BAF) -- lock + key 
        PrivateCast(10, "char*", 0x429B6F) -- lock - key
		do
			self.planes = {}
			local minPlaneWidth = self.Width/64
			local minPlaneHeight = self.Height/64
			for i = 0, PlanesCount()-1 do
				local plane = GetPlane(i)
				if plane ~= nil and plane.Flags.NoDraw ~= true and (plane.Width < minPlaneWidth or plane.Height < minPlaneHeight) then
					table.insert(self.planes, plane)
					plane.Flags.NoDraw = true
					MessageBox("Plane with index " .. i .. " is too small for this resolution!\nThe plane's visibility has been disabled")
				end
			end
		end
		self.State = 2
	end

	if self.State == 2 then
        if nRes(26) ~= 10 then
            mdl_exe._SetPlayArea(_nResult[0], 10, 1, 0)
        end
		if PLAY_AREA.Right + 1 ~= self.Width then
			self.State = 3
		end
	end

	if self.State == 3 then
		mdl_exe._ChangeResolution(nRes(), self.Width, self.Height)
		self.State = 2
	end

    if self.State == 4 then
        ChangeResolution(self.normalWidth, self.normalHeight)
		for _, plane in ipairs(self.planes) do
			plane.Flags.NoDraw = false
		end
        ffi.cast("char*",0x429BAF)[0] = 10  -- unlock + key
        ffi.cast("char*",0x429B6F)[0] = 1 -- unlock - key
        self:Destroy()
    end
end
