-- Desired aspect ratio
local aspect_ratio = "16:9"

local window_sizes = {
    [ "4:3"] = { 640, 480},
    ["16:9"] = { 864, 486},
    ["21:9"] = {1160, 486},
    ["32:9"] = {1664, 486},
}

if not window_sizes[aspect_ratio] then
    ffi.C.MessageBoxA(
        nil,
        "Invalid aspect ratio (\"" .. aspect_ratio .. "\"). Defaulting to 4:3",
        "Plugin error",
        0x1030
    )
    aspect_ratio = "4:3"
end

local width = window_sizes[aspect_ratio][1]
local height = window_sizes[aspect_ratio][2]

local rX = width/640
local dX = math.floor((width-640)/2)

local rY = height/480
local dY = math.floor((height-480)/2)

-- Screen images lookup folder (for non 4:3 ratios)
local xcreens_folder = "XR\\" .. aspect_ratio:gsub(":", "X")

local function _chamAdd(addr, code)
	local cham_exe = ffi.cast("char*", addr)
	local i = 0
	for v in string.gmatch(code, "([^ ]+)") do
		cham_exe[i] = tonumber(v, 16)
		i = i+1
	end
end

-- Get/Set int:
local gInt = function(addr)
    return ffi.cast("int*", addr)[0]
end
local sInt = function(addr, n)
    ffi.cast("int*", addr)[0] = n
end

-- Multiply by ratio:
local mXInt = function(addr)
    sInt(addr, math.floor(gInt(addr) * rX))
end
local mYInt = function(addr)
    sInt(addr, math.floor(gInt(addr) * rY))
end

-- Add the difference:
local aXInt = function(addr)
    sInt(addr, math.floor(gInt(addr) + dX))
end
local aYInt = function(addr)
    sInt(addr, math.floor(gInt(addr) + dY))
end

if aspect_ratio ~= "4:3" then
	-- Base resolution:

	sInt(0x429D2E, width)
	sInt(0x429D3A, height)

	sInt(0x429D41, height)
	sInt(0x429D46, width)

	sInt(0x42B5F5, height)
	sInt(0x42B5FA, width)

	sInt(0x428F69, height)
	sInt(0x428F6E, width)

	sInt(0x428F95, height)
	sInt(0x428F8F, width)

	sInt(0x429FEC, height)
	sInt(0x429FF1, width)

	sInt(0x42904F, height)
	sInt(0x429054, width)

	sInt(0x4290A8, height)
	sInt(0x4290AD, width)

	sInt(0x42639C, height)
	sInt(0x426388, width)

	sInt(0x4268CB, height)
	sInt(0x4268C1, width)

	sInt(0x426F1A, height)
	sInt(0x426F1F, width)

	sInt(0x426F51, height)
	sInt(0x426F58, width)

	sInt(0x426F9A, height)
	sInt(0x426F90, width)

	sInt(0x429672, height)
	sInt(0x429679, width)

	sInt(0x4296F2, height)
	sInt(0x4296F9, width)

	sInt(0x42A0E7, height)
	sInt(0x42A0EC, width)

	sInt(0x42C76F, height)
	sInt(0x42C763, width)

	sInt(0x42CF49, height)
	sInt(0x42CF4E, width)

	sInt(0x42D47C, height)
	sInt(0x42D481, width)

	sInt(0x42EAE0, height)
	sInt(0x42EAE7, width)

	sInt(0x437B7F, height)
	sInt(0x437B77, width)

    sInt(0x535848, width-1)
    sInt(0x53584C, height-1)

	sInt(0x477122, width/2)
	sInt(0x47A30D, width/2)
	sInt(0x47D073, width/2)
	sInt(0x49C461, width/2)
	sInt(0x4292A4, width)
	sInt(0x4292AE, height)

	-- Base resolution SetRect args:

	sInt(0x42A179, height-1)
	sInt(0x42A17E, width-1)

    -- Video playback (non HQ, force 4:3):

    _chamAdd(0x4F4C5E, "B8 02 00 00 00 90 90")
    -- MOV EAX, 2 -- NOP -- NOP

	-- File/folder paths:

    ffi.copy(ffi.cast("char*", 0x52718E), xcreens_folder, 7)
    ffi.copy(ffi.cast("char*", 0x52719D), xcreens_folder, 7)
    ffi.copy(ffi.cast("char*", 0x528303), "WORLDX", 6)

	-- Menu:
	do
		-- MenuClaw position:

        sInt(0x4614F6, width/2 - (640/2 - gInt(0x4614F6)))
        sInt(0x4614FE, width/2 + (gInt(0x4614FE) - 640/2))
        sInt(0x461506, gInt(0x4614FE))

        local MenuClawY = 64*rY
		ffi.cast("char*", 0x45D4F6)[0] = MenuClawY > 127 and 127 or MenuClawY

		-- MenuSparkle position:

		aXInt(0x526DA8)
		aYInt(0x526DAC)
		aXInt(0x526DB0)
		aYInt(0x526DB4)
		aXInt(0x526DB8)
		aYInt(0x526DBC)
		aXInt(0x526DC0)
		aYInt(0x526DC4)
		aXInt(0x526DC8)
		aYInt(0x526DCC)
		aXInt(0x526DD0)
		aYInt(0x526DD4)
		aXInt(0x526DD8)
		aYInt(0x526DDC)
		aXInt(0x526DE0)
		aYInt(0x526DE4)
		aXInt(0x526DE8)
		aYInt(0x526DEC)
		aXInt(0x526DF0)
		aYInt(0x526DF4)
		aXInt(0x526DF8)
		aYInt(0x526DFC)
		aXInt(0x526E00)
		aYInt(0x526E04)
		aXInt(0x526E08)
		aYInt(0x526E0C)
		aXInt(0x526E10)
		aYInt(0x526E14)
		aXInt(0x526E18)
		aYInt(0x526E1C)
		aXInt(0x526E20)
		aYInt(0x526E24)
		aXInt(0x526E28)
		aYInt(0x526E2C)

		-- Titles position:

		mXInt(0x45F858)
        mYInt(0x45F853)

		mXInt(0x45F88E)
        mYInt(0x45F889)

		mXInt(0x45F8C4)
        mYInt(0x45F8BF)

		mXInt(0x45F8FA)
        mYInt(0x45F8F5)

		mXInt(0x45F930)
		mYInt(0x45F92B)

		mXInt(0x45F966)
		mYInt(0x45F961)

		mXInt(0x45F99C)
		mYInt(0x45F997)

		mXInt(0x45FA09)
		mYInt(0x45FA04)

		mXInt(0x45FA3F)
		mYInt(0x45FA3A)

		mXInt(0x45FA75)
		mYInt(0x45FA70)

		mXInt(0x45FABC)
		mYInt(0x45FAB7)

		mXInt(0x45FAF2)
		mYInt(0x45FAED)

		mXInt(0x45FB3C)
		mYInt(0x45FB37)

		mXInt(0x45FB72)
		mYInt(0x45FB6D)

		mXInt(0x45FBA8)
		mYInt(0x45FBA3)

		-- Version and player name text rect:

        mYInt(0x536294)
		mXInt(0x536298)
        mYInt(0x53629C)

        -- Selectable elements position:

        aYInt(0x45F5A7)
        aYInt(0x45F5B0)

        sInt(0x45F5BE, width)

        aYInt(0x45F602)
        aYInt(0x45F60C)

        aYInt(0x45F61B)
        aYInt(0x45F625)

        aYInt(0x45F634)
        aYInt(0x45F63E)

        aYInt(0x45F68C)
        aYInt(0x45F696)

        aYInt(0x45F6A8)

        aYInt(0x45F6BB)
        aYInt(0x45F6C5)

        aYInt(0x45F6EC)

        aYInt(0x45F706)
        aYInt(0x45F710)

        -- New/load game:
        sInt(0x461A4C, 37 + math.floor(0.64*dX))
        sInt(0x461A58, 308 + math.floor(1.5*dX))
        mYInt(0x461A60)

	end

    -- Loading:
    do
	    -- Loading bar:
	    mXInt(0x47006A)
	    mXInt(0x47007A)
	    mYInt(0x470072)
	    mYInt(0x470082)

	    mXInt(0x46FF7C)
	    mXInt(0x46FF8C)
	    mYInt(0x46FF84)
	    mYInt(0x46FF94)

	    -- Loading "Custom level: " text:
	    sInt(0x470D6C, width-1)
	    sInt(0x470D64, height-35)
	    sInt(0x470D74, height-5)

    end

	-- Booty:
	do
        -- LEVEL symbol:
        mYInt(0x40DB9B)
		sInt(0x40DBA0, width-220)

        sInt(0x40DBFA, width-220)
        mYInt(0x40DBF3)

        -- LEVEL score digits:
        sInt(0x40DC59, width-150)

        -- GAME symbol:
        mYInt(0x40DC79)

        mYInt(0x40DCC2)

        -- TreasureCounter X coord:
        aXInt(0x40DED4)

        -- Map pieces:
        aXInt(0x40C7A3)
        aYInt(0x40C7AB)
        aXInt(0x40C7B3)
        aXInt(0x40C7BB)
        aYInt(0x40C7C3)
        aYInt(0x40C7CB)
        aXInt(0x40C7D3)
        aYInt(0x40C7DB)
        aXInt(0x40C7E3)
        aYInt(0x40C7EB)

        -- Gems:
        aYInt(0x40D7E5)
        aXInt(0x40D7ED)
        aYInt(0x40D7F5)
        aXInt(0x40D7FD)
        aXInt(0x40D805)
        aYInt(0x40D80D)
        aXInt(0x40D815)
        aYInt(0x40D81D)
        aXInt(0x40D825)
        aYInt(0x40D82D)
        aXInt(0x40D835)
        aYInt(0x40D83D)
        aXInt(0x40D845)
        aYInt(0x40D84D)
        aXInt(0x40D855)
        aYInt(0x40D85D)

        -- Map progress level 3 (8 dots):
        aXInt(0x40CB28)
        aYInt(0x40CB30)
        aXInt(0x40CB38)
        aYInt(0x40CB40)
        aXInt(0x40CB48)
        aYInt(0x40CAEC)
        aXInt(0x40CB50)
        aYInt(0x40CB58)
        aXInt(0x40CB60)
        aYInt(0x40CAE7)
        aXInt(0x40CB68)
        aXInt(0x40CB70)
        aXInt(0x40CB78)
        aYInt(0x40CB80)

        --Map progress level 5 (11 dots):
        aXInt(0x40CAF9)
        aYInt(0x40CCA1)
        aXInt(0x40CB19)
        aYInt(0x40CCB3)
        aYInt(0x40CCC5)
        aYInt(0x40CCD0)
        aXInt(0x40CCDB)
        aYInt(0x40CCE6)
        aXInt(0x40CB1E)
        aYInt(0x40CD02)
        aYInt(0x40CD14)
        aXInt(0x40CD1F)
        aYInt(0x40CD2A)
        aXInt(0x40CD35)
        aYInt(0x40CD40)
        aXInt(0x40CD4B)
        aYInt(0x40CD56)
        aXInt(0x40CD61)
        aYInt(0x40CD6C)

        -- Map progress level 7 (6 dots):
        aXInt(0x40CE81)
        aYInt(0x40CE8C)
        aXInt(0x40CE97)
        aYInt(0x40CEA2)
        aXInt(0x40CEAD)
        aYInt(0x40CEB8)
        aYInt(0x40CECA)
        aXInt(0x40CED5)
        aYInt(0x40CEE0)
        aYInt(0x40CEF2)
        aXInt(0x40CCF2)
        aXInt(0x40CCF7)

        -- Map progress level 9 and 11 (33 dots):
        aXInt(0x40D07D)
        aYInt(0x40D088)
        aXInt(0x40D093)
        aYInt(0x40D09E)
        aXInt(0x40D0A9)
        aYInt(0x40D0B4)
        aXInt(0x40D0BF)
        aYInt(0x40D0CA)
        aXInt(0x40CF75)
        aYInt(0x40D0D5)
        aXInt(0x40D0E0)
        aYInt(0x40D0EB)

        aYInt(0x40D0F6)

        aYInt(0x40CF96)
        aXInt(0x40D108)
        aYInt(0x40D113)
        aXInt(0x40D11E)

        aYInt(0x40CF9B)
        aXInt(0x40D130)
        aYInt(0x40D13B)
        aXInt(0x40D146)
        aYInt(0x40D151)
        aYInt(0x40D15C)
        aXInt(0x40D167)
        aYInt(0x40CFA0)
        aXInt(0x40D179)

        aXInt(0x40D18B)
        aYInt(0x40D196)
        aXInt(0x40D1A1)
        aYInt(0x40D1AC)
        aXInt(0x40D1B7)
        aYInt(0x40D1C2)
        aXInt(0x40D1CD)
        aYInt(0x40D1D8)
        aXInt(0x40D1E3)
        aYInt(0x40D1EE)
        aXInt(0x40D1F9)
        aYInt(0x40D204)
        aXInt(0x40D20F)
        aYInt(0x40D21A)
        aXInt(0x40D225)
        aYInt(0x40D230)
        aXInt(0x40D23B)
        aXInt(0x40D279)
        aYInt(0x40D289)

        aYInt(0x40D294)
        aXInt(0x40D29F)
        -- Hook for a few dots, because some x and y coords collide:
        do
            _chamAdd(0x40D246, "EB 05") -- JMP SHORT
            _chamAdd(0x40D24D, "E9 32 B2 02") -- JMP 0x438484
            _chamAdd(0x40D25C, "EB 0C") -- JMP SHORT
            _chamAdd(0x40D311, "EB 05") -- JMP SHORT
            _chamAdd(0x438484, "C7 84 24 BC 03 00 00 6F 01 00 00 C7 84 24 D8 03 00 00 6F 01 00 00 C7 84 24 B0 03 00 00 7B 01 00 00 C7 84 24 EC 03 00 00 2C 01 00 00 E9 9D 4D FD FF")
			-- MOV DWORD PTR SS:[LOCAL.66], 16F -- MOV DWORD PTR SS:[LOCAL.59], 16F -- MOV DWORD PTR SS:[LOCAL.69], 17B -- MOV DWORD PTR SS:[LOCAL.54], 17B -- JMP 0x40D252
            aYInt(0x43848B)
            aXInt(0x438496)
            aXInt(0x4384A1)
            aYInt(0x4384AC)
        end
        aXInt(0x40D2AA)
        aYInt(0x40D2B5)
        aXInt(0x40D2C0)
        aYInt(0x40D2CB)
        -- Remove 30th dot:
        sInt(0x40D2D6, -1)
        sInt(0x40D2E1, -1)
        --
        aYInt(0x40D2EC)
        aXInt(0x40D2F7)
        aYInt(0x40D302)
        aXInt(0x40D30D)

	end

end

local PLUGIN = {}

PLUGIN.map = function()
    if aspect_ratio ~= "4:3" then
        if _chameleon[0] == chamStates.LoadingStart then
            sInt(0x40D7CE, 364) -- gem1.X and gem3.Y
            sInt(0x40C75D, 316) -- map2.Y and map4.X
        end
        if _chameleon[0] == chamStates.LoadingEnd then
            -- Some values need to be adjusted based on current level:
            if nRes(11,5) == 2 then
                aXInt(0x40D7CE)
            else
                aYInt(0x40D7CE)
            end
            if nRes(11,5) == 3 then
                aYInt(0x40C75D)
            else
                aXInt(0x40C75D)
            end
            -- Changing screens dirname again after loading custom level with a custom background:
            ffi.copy(ffi.cast("char*", 0x52718E), xcreens_folder, 7)
            ffi.copy(ffi.cast("char*", 0x52719D), xcreens_folder, 7)
        end
    end
end

return PLUGIN

