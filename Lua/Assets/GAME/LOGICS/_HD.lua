
function main(self)

	PLAY_AREA = ffi.cast("Rect*", 0x535840)[0]

	if self.State == 0 then
		self.Flags.AlwaysActive, self.DrawFlags.NoDraw = true, true
        ffi.cast("char*",0x429BAF)[0] = 1 -- lock + on keyboard
        ffi.cast("char*",0x429B6F)[0] = 10 -- lock - on keyboard
		self.State = 2
	end

	if self.State == 2 then
        if nRes(26) ~= 10 then
            --ffi.cast("void(*__thiscall)(void*,int,int,int)", 0x429BF0)(_nResult[0],10,1,0)
            --ffi.cast("char*",0x429BAF)[0] = 1
        end
		if PLAY_AREA.Right + 1 ~= self.Width then
			self.State = 3
		end
	end

	if self.State == 3 then
		ChangeResolution(self.Width,self.Height)
		self.State = 2
	end

    if self.State == 4 then
        ChangeResolution(640,480)
        ffi.cast("char*",0x429BAF)[0] = 10  -- unlock + on keyboard
        ffi.cast("char*",0x429B6F)[0] = 1 -- unlock - on keyboard
        self:Destroy()
    end
end
