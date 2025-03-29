return {
	map = function()
		local cham = _chameleon[0]
		if cham == chamStates.LoadingEnd then
			snRes(0, 5) -- music off
			snRes(0, 106) -- front plane off
			GetFrontPlane().Flags.NoDraw = true
			if InfosDisplay[0].FPS == false then
				ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPFPS, 0)
			end
			if InfosDisplay[0].Watch == false then
				ffi.C.PostMessageA(nRes(1,1), 0x111, _message.MPSTOPWATCH, 0)
			end
		end
	end
}