--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- [[ Crazy Patches ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

--ffi.C.VirtualProtect(0x50C000, 0x14000, 4, ffi.new("int[1]")) -- changing the page protection from read-only to read-write.

local function _chamAdd(addr, code)
	local cham_exe = ffi.cast("char*",addr)
	local i = 0
	for v in string.gmatch(code, "([^ ]+)") do
		cham_exe[i] = tonumber(v, 16)
		i = i+1
	end
end

do --[[ ;bearhug sound fix
        PUSH EDI ; arg 4 = bool - loop sound
        PUSH EDI ; arg 3 = 0
        PUSH EDI ; arg2 = 0
        MOV ECX, DWORD PTR DS:[ECX+10] ; this = *sound
        MOV EDI, DWORD PTR DS:[530990]
        PUSH EDI ; arg1 = volume
        XOR EDI, EDI
        CALL 004B3FA0 ; play sound
        MOVE DWORD PTR DS: [ESI+4BC], EDI; reset input press counter
        POP EDI
        XOR EAX, EAX
        POP ESI
        RETN
    ]]
    _chamAdd(0x40AF2A, "57 57 57 8B 49 10 8B 3D 90 09 53 00 57 33 FF E8 62 90 0A 00 89 BE BC 04 00 00 5F 33 C0 5E C3")
end

do -- JUMP SHORT 0xA
    _chamAdd(0x40F7F4,"EB 0A")
end

do -- ?
    _chamAdd(0x40F7FA,"00 00 00 00 00 00")
end

do -- Double jump fix part 1:
    _chamAdd(0x41D536, "90 90 E9 79 AF 01 00 6A 01 68 10 27 52 00")
end

do -- trigger save for custom levels:
	_chamAdd(0x4247A0, "EB 0F 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90")
end

do -- custom save system state
    _chamAdd(0x424859,"00 00 00 00")
end

do-- JUMP SHORT 0x55
    _chamAdd(0x427055,"EB 55")
end

do
    _chamAdd(0x4270B6,"6A 00")
end

do -- JUMP SHORT 0x4
    _chamAdd(0x427766,"EB 04")
end

do -- SkipLogoMovies
    _chamAdd(0x4277E9,"A1 BB BF 50 00 EB 04")
end

do -- SkipTitleScreen
    _chamAdd(0x42782E,"A1 BF BF 50 00 EB 04")
end

do -- Chameleon On PostMessageA
    _chamAdd(0x427D28,"E9 6B 41 0E 00")
end

do -- MenuHook
    _chamAdd(0x427E32,"E9 A0 41 0E 00 90 90 90")
end

do -- change message ID for "load custom level" dialog
    _chamAdd(0x428203,"68 4D 11 00 00")
end

do -- skip checks for starting level
    _chamAdd(0x42D5B6,"EB 05")
end

do -- skip checks for loading level
    _chamAdd(0x42D5E6,"EB 05")
end

do -- skip text out and sound on MPHAUNTED / chameleon 10 for mouse wheel
	_chamAdd(0x42E60E, "EB 71 81 FB 0A 02 00 00 0F 85 18 A9 08 00 56 89 FE 52 BA 0A 00 00 00 E8 42 D9 0D 00 5A 5E 8D 83 FD FD FF FF E9 FD A8 08 00")
end

-- from 0x42E634 to 0x42E67C - free for future use

do
    _chamAdd(0x42E8C5,"EB 60 8B 44 24 14 85 C0 75 19 EB 56")
end

do
    _chamAdd(0x42EBA5,"6A 00")
end

do
    _chamAdd(0x42EBFB,"6A 00")
end

do -- jump to Chameleon 7
    _chamAdd(0x438385,"E9 C9 31 0D 00")
end

do -- dont get info of the selected level in the custom lvls dlg listbox" 
    _chamAdd(0x43840E,"EB 16")
end

do -- JMP SHORT ; don't load strings to custom lvls dlg listbox
    _chamAdd(0x438466, "EB")
end

do -- Double jump fix part 2
    _chamAdd(0x4384B6, "83 BE E4 00 00 00 10 7F 09 C7 41 1C 18 00 00 00 EB 07 C7 41 1C 8A 13 00 00 E9 69 50 FE FF")
end

do -- dont get info of the selected level in the custom lvls dlg listbox" 
    _chamAdd(0x4385A0, "C3")
end

do
    _chamAdd(0x43869E,"EB 06")
end

do -- jump on string formating to display the custom level name on loading screen
    _chamAdd(0x438C50, "EB 0A 90 90 90 90 90 90 90 90")
end

do
    _chamAdd(0x4390BB,"EB 40")
end

do
    _chamAdd(0x439113,"EB 3A")
end

do -- Disable the damage multiplier for LavaGeyser (mpcultist)
    _chamAdd(0x457A6D, "8B CE EB 15")
end

do -- Disable the damage multiplier for LavaMouth (mpcultist)
    _chamAdd(0x4599BB, "8B CE EB 15")
end

do 
    _chamAdd(0x45D426,"4D 65 6E 75 48 6F 6F 6B 00")
end

do -- PUSH MenuHookString
    _chamAdd(0x45D4E5,"68 26 D4 45 00")
end

do
    _chamAdd(0x460003,"EB 41")
end

do
    _chamAdd(0x461C43,"FF 35 60 D3 53 00 52 E9 13 00 00 00")
end

do
    _chamAdd(0x461C69,"8D 4C 24 1C")
end

do
    _chamAdd(0x461C78,"83 C4 18")
end

do -- jump to Chameleon 2
    _chamAdd(0x46D2FD,"E9 BB EB 09 00 90 90 90 90 90 90 90 90 90 90 90")
end

do
    _chamAdd(0x46D5EF,"E9 11 DF 09 00")
end

do -- jump to Chameleon 3
    _chamAdd(0x46DA3B,"E9 6E E4 09 00")
end

do
    _chamAdd(0x46E781,"EB 16")
end

do -- jump chameleon 5 pre
    _chamAdd(0x46E7C1,"E9 AB 00 00 00")
end

do -- jump 
    _chamAdd(0x46E871,"74 F4 E9 C5 CC 09 00 E9 4A FF FF FF")
end

do
    _chamAdd(0x46EDF8,"E9 D1 D0 09 00 90")
end

do --[[ ; Multiplayer curses
        MOV DWORD PTR DS:[532D1C], EDI
	    MOV EBX, DWORD PTR DS:[ARG.2]
	    MOV EBP, DWORD PTR DS:[ARG.1]
	    MOV DWORD PTR DS:[532D24], EBX
	    MOV DWORD PTR DS:[532D20], EBP
	    JMP SHORT 47C699
    ]]
	_chamAdd(0x47C673, "89 3D 1C 2D 53 00 8B 9C 24 9C 00 00 00 8B AC 24 98 00 00 00 89 1D 24 2D 53 00 89 2D 20 2D 53 00 EB 04")
end

do -- Show perfect in custom levels:
	_chamAdd(0x49C426, "EB 0A")
end

do
    _chamAdd(0x4B612A,"EB 04")
end

do
    _chamAdd(0x4B69D9,"EB 04")
end

do
    _chamAdd(0x4B6ADB,"EB 03")
end

do
    _chamAdd(0x4B720F,"E9 76 43 05 00")
end

do
    _chamAdd(0x4B7426,"90 90")
end

do
    _chamAdd(0x4B745F,"90 90")
end

do
    _chamAdd(0x4B8C1D,"EB 42")
end

do
    _chamAdd(0x4B8C61,"A3 91 8B 4B 00 6A 01 EB B5")
end

do -- jump to chameleon 10
	_chamAdd(0x4B8F2E, "E9 DD 56 F7 FF 90")
end

do -- ; ChameleonB
    _chamAdd(0x50B505, "E8 46 4A F6 FF 50 52 A1 23 B4 50 00 BA 83 B4 50 00 E8 17 FF FF FF 68 6C 0A 52 00 50 FF 15 04 C3 50 00 BA 9C B4 50 00 E8 01 FF FF FF 6A 00 FF D0 58 5A 58 E9 B7 20 F6 FF 52 BA 05 00 00 00 56 50 5E E8 21 0A 00 00 5E 90 5A E9 25 33 F6 FF 52 56 89 E6 BA 07 00 00 00 E8 0B 0A 00 00 5E 5A 2D 10 01 00 00 E9 1D CE F2 FF 52 6A 24 50 E8 DA A6 F9 FF 5A 52 85 C0 75 02 EB 05 C6 00 00 EB 22 58 5A 5A 89 D9 EB 24 56 50 E8 DC FF FF FF 85 C0 75 07 68 00 60 4B 00 EB 05 68 F0 60 4B 00 5E 58 EB 0D 58 5A 5A 89 D9 6A 01 EB 02 6A 00 58 C3 83 C4 04 FF D6 83 EC 04 5E E9 54 BC FA FF")
end

do
    _chamAdd(0x50BE60,"43 55 53 54 4F 4D 5F 53 50 4C 41 53 48 00 6A 3C 6A 10 6A CC 6A F0 8F 83 34 01 00 00 8F 83 38 01 00 00 8F 83 3C 01 00 00 8F 83 40 01 00 00 E8 5D 15 F1 FF E9 96 BF F0 FF 52 BA 04 00 00 00 E8 C9 00 00 00 5A 3D A7 00 00 00 E9 7F BE F1 FF 52 BA 03 00 00 00 E8 B3 00 00 00 5A C2 08 00 52 BA 02 00 00 00 E8 A4 00 00 00 5A E9 3F 14 F6 FF 0F 84 29 33 F6 FF 52 BA 01 00 00 00 E8 8D 00 00 00 5A E9 19 2F F6 FF")
end

do -- [[ "*.WWD" ]]
    _chamAdd(0x50BEE5,"2A 2E 57 57 44 00")
end

do
    _chamAdd(0x50BEEB,"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
end

do -- ; Chameleon Main
    _chamAdd(0x50BF6C, "50 52 A1 23 B4 50 00 BA 83 B4 50 00 E8 B5 F4 FF FF 68 6C 0A 52 00 50 FF 15 04 C3 50 00 BA 9C B4 50 00 E8 9F F4 FF FF 5A 89 15 B5 BF 50 00 56 FF D0 58 B8 00 00 00 00 A3 B5 BF 50 00 58 C3")
end

do
    _chamAdd(0x50BFBB,"00 00 00 00 00 00 00 00")
end

do
    _chamAdd(0x50BFC3,"89 2D 10 59 53 00 E8 22 CA FA FF E9 2E A8 F1 FF 00 00 00 00 A1 D3 BF 50 00 85 C0 75 0D 6A 00 6A 00 6A 01 6A 05 E9 4D BE F1 FF 68 39 05 00 00 FF 15 54 C1 50 00")
end

do
    _chamAdd(0x50BFFE,"00 00")
end

do -- [[ "Assets" ]]
    _chamAdd(0x5236F0,"41 73 73 65 74 73 00")
end

do
    local curVer = string.gsub(tostring(version), "%d", "%0%."):sub(1,-2)
    if curVer:sub(-1) == "0" then curVer = curVer:sub(1,-3) end
	ffi.copy(ffi.cast("char*", 0x527508), curVer)
end
