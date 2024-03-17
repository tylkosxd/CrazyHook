CustomLevelWindow = function(ptr)
	local _WwdCustomsStr = 0x50BEE5
	if _chameleon[0] == chamStates.OnPostMessageA then		
		if tonumber(ffi.cast("int",ptr)) == 333 then -- custom levels
			_TimeThings()
			--local v34 = ffi.cast("int (*__thiscall)(int, int**, int, int)",nRes(11,0,1))(nRes(11),_nResult,1,5)
			ffi.cast("int (*__thiscall)(int, int)",0x4CB6B0)(Game(1),Game(1,5))
			local v6 = Game(7,0)
			ffi.cast("int (*)(int)",Game(7,0,0,10))(v6)
			if ffi.C.DialogBoxParamA(nRes(2,3), "CUSTOMWORLD", nRes(1,1), 0x438380, 0)==1 and ffi.cast("char*",_WwdCustomsStr)[0]~=0 then
				local _getcwd = ffi.cast("int (*__cdecl)(int, int)",0x4AF5E4)
				local str = ffi.new("char[255][1]")
				_getcwd(ffi.cast("int",str),254)
				local custom = ffi.string(ffi.cast("const char*",str[0]))..ffi.string(ffi.cast("const char*",0x524DAC))..ffi.string(ffi.cast("const char*",_WwdCustomsStr))..".WWD"
				snRes(ffi.cast("int", custom), 49)
				ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8005, 0) --RunGame
			end
			while (ffi.C.ShowCursor(0)>=0) do end
			_TimeThings()
		end

	elseif _chameleon[0] == chamStates.CustomLevels then -- open custom level window
		local namestr = tostring(ffi.string(ffi.cast("const char*",ffi.cast("int",ptr)+60)))
		local baselev = 0
		for i=0,#namestr do
			if string.byte(namestr,i+1)>=49 and string.byte(namestr,i+1)<=57 then
				local _atoi = ffi.cast("int (*__cdecl)(const char*)",0x4A5EA6)
				baselev = _atoi(ffi.cast("const char*",ffi.cast("int",ptr)+60+i))
				break
			end
		end
		if baselev>14 or baselev<0 then 
			baselev=0 
		end
		ffi.C.PostMessageA(ffi.C.GetDlgItem(hdlg,555),0x0170,ffi.C.LoadIconA(ffi.cast("int*",ffi.cast("int (*__cdecl)()",0x50731A)()+8)[0],"L"..tostring(baselev)),0)
		ffi.C.SetDlgItemTextA(hdlg,1032,ffi.cast("const char*",ffi.cast("int",ptr)+188))
		ffi.C.SetDlgItemTextA(hdlg,1033,"Created by "..tostring(ffi.string(ffi.cast("const char*",ffi.cast("int",ptr)+124))))
	
	elseif _chameleon[0] == chamStates.CustomLevelsWindow then
		hdlg = ffi.cast("int*",ptr)[4]
		ffi.C.ShowCursor(1)
		if ffi.cast("int*",ptr)[5]==272 then
			local text = ffi.cast("char*",_WwdCustomsStr)
			text[0] = 0x2A text[1] = 46 text[2] = 87 text[3] = 87
			text[4] = 68 text[5] = 0
			local listbox = ffi.C.GetDlgItem(hdlg, 1020)
			ffi.C.PostMessageA(listbox,0x186,0,0)
			ffi.C.PostMessageA(hdlg,273,0x103FC,0)
			ffi.C.SetFocus(hdlg)
		end
		if ffi.cast("int*",ptr)[5]==273 then
			if ffi.cast("int*",ptr)[6]==1 then
				if ffi.C.SendMessageA(ffi.C.GetDlgItem(hdlg, 1020), 0x188, 0, 0)>=0 then
					ffi.C.SendMessageA(ffi.C.GetDlgItem(hdlg, 1020), 0x189, ffi.C.SendMessageA(ffi.C.GetDlgItem(hdlg, 1020), 0x188, 0, 0), _WwdCustomsStr)
				else ffi.cast("char*",_WwdCustomsStr)[0]=0
				end
			elseif ffi.cast("int*",ptr)[6]==0x103FC then
				local f = ffi.cast("int (*__cdecl)(int)",0x4385A0)
				if f(hdlg)==1 then
					local _chdir = ffi.cast("int (*__cdecl)(const char*)",0x4F64DE)
					local str = ffi.new("char[128]")
					local dates = ffi.new("char[64]")
					ffi.C.SendMessageA(ffi.C.GetDlgItem(hdlg, 1020), 0x189, ffi.C.SendMessageA(ffi.C.GetDlgItem(hdlg, 1020), 0x188, 0, 0), ffi.cast("int",str))
					if _chdir("Custom")==0 then
						if _chdir(ffi.string(ffi.cast("const char*",str)))==0 then
							ffi.C.PostMessageA(ffi.C.GetDlgItem(hdlg,556),0x0170,ffi.C.LoadIconA(ffi.cast("int*",ffi.cast("int (*__cdecl)()",0x50731A)()+8)[0],"CLAW"),0)
							_chdir("..")
						else
							ffi.C.PostMessageA(ffi.C.GetDlgItem(hdlg,556),0x0170,ffi.C.LoadIconA(ffi.cast("int*",ffi.cast("int (*__cdecl)()",0x50731A)()+8)[0],"OLDCLAW"),0)
						end
						_chdir("..")
					end
					ffi.C.GetDlgItemTextA(hdlg,1032,ffi.cast("int",dates),64)
					str = tostring(ffi.string(ffi.cast("const char*",str))).."("..tostring(ffi.string(ffi.cast("const char*",dates)))..")"
					ffi.C.SetDlgItemTextA(hdlg,1032,str)
				end
			end
		end
		if ffi.cast("int*",ptr)[6]==0x0300029A then
			local len = 0
			local text = ffi.cast("char*",_WwdCustomsStr)
			if ffi.C.GetDlgItemTextA(hdlg,666,_WwdCustomsStr,64)>=1 then
				for i=0,64 do if len==0 and text[i]==0 then len=i end end
			else text[0] = 0x2A
			end
			text[len] = 0x2A text[len+1] = 46 text[len+2] = 87 text[len+3] = 87
			text[len+4] = 68 text[len+5] = 0
			local f = ffi.cast("signed int (*__cdecl)(int)",0x438484)
			f(hdlg)
			ffi.C.PostMessageA(ffi.C.GetDlgItem(hdlg, 1020),0x186,0,0)
			ffi.C.PostMessageA(hdlg,273,0x103FC,0)
			if ffi.C.SendMessageA(ffi.C.GetDlgItem(hdlg, 1020), 0x18B, 0, 0)<=0 then
				ffi.C.PostMessageA(ffi.C.GetDlgItem(hdlg,556),0x0170,0,0)
				ffi.C.PostMessageA(ffi.C.GetDlgItem(hdlg,555),0x0170,0,0)
				ffi.C.SetDlgItemTextA(hdlg,1032,"")
				ffi.C.SetDlgItemTextA(hdlg,1034,"")
			end
		end	
	end
end

return CustomLevelWindow
