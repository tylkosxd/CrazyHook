_WwdCustomsStr = 0x50BEE5
local SearchFilter = ""
local SavesData = nil
local RecsData = nil
local hdlg = ffi.new("int")
local LoadButtonState = 0
local LoadButton2State = 0
local _LoadIcon = ffi.cast("int* (*__cdecl)()",0x50731A)
local _ChangeDir = ffi.cast("int (*__cdecl)(const char*)",0x4F64DE)
--local _atoi = ffi.cast("int (*__cdecl)(const char*)", 0x4A5EA6)
--local f0 = ffi.cast("int (*__thiscall)(int, int)", 0x4CB6B0)
--local _GetSelectionCount = ffi.cast("int (*__cdecl)(int)", 0x4385A0)
--local _ReloadListBox = ffi.cast("signed int (*__cdecl)(int)", 0x438484)

local CustomLevels = {}

local Months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}

local DlgItems = {
    Title           = -1,
    ButtonPlay      = 1,
    ButtonCancel    = 2,
    ButtonLoad      = 3,
	ButtonLoad2		= 4,
    CheckBox        = 0x69,
    LevelsCount     = 0xA1,
    LevelIcon       = 0x22B,
    GameIcon        = 0x22C,
    RecIcon         = 0x22D,
    SearchBox       = 0x29A,
    ListBox         = 0x3FC,
    Date            = 0x408,
    Author          = 0x409,
    InfoBox         = 0x40A,
	Status			= 0x40B,
    TextSearch      = 0xFFFF,
}

local function GetCStrInt(str)
    return ffi.cast("int", _GetCStr(str))
end

local function GetCustomPath()
    return GetClawPath() .. ffi.string(ffi.cast("const char*",0x524DAC))
end

local function GetCustomImgsPath()
    return GetClawPath() .. "\\Assets\\STATES\\DIALOGS\\IMAGES\\CUSTOMWORLD\\"
end

local function GetSelectedLevelName()
    return ffi.string(ffi.cast("const char*", _WwdCustomsStr))
end

local function CalcSum2(name, one, two)
	local cstr = _GetCStr(name)
	return one*cstr[0] + two*cstr[#name-1] + cstr[0]*cstr[0] + 729
end

local function FixDate(str)
	local day_suf = function(day)
		if tonumber(day) > 3 and tonumber(day) < 21 or tonumber(day) > 23 and tonumber(day) < 31 then
			day = day .. "th"
		else
			if day:sub(-1) == "1" then
				day = day .. "st"
			elseif day:sub(-1) == "2" then
				day = day .. "nd"
			elseif day:sub(-1) == "3" then
				day = day .. "rd"
			end
		end
		return day
	end
    if str:match"(%d%d:%d%d %d%d%.%d%d%.%d%d%d%d)" then
        local mon = Months[tonumber(str:sub(10,11))]
        local day = day_suf(str:sub(7,8))
        local year = str:sub(-4)
        return mon.." "..day.." "..year
    else
		local mon = str:match"(%a+)%A"
		local day = day_suf(str:match"%D(%d+),")
		local year = str:sub(-4)
        return mon.." "..day.." "..year
    end
end

CLDIAL = {
	Width = ffi.cast("short*", 0x5CEF12)[0],
	Height = ffi.cast("short*", 0x5CEF14)[0]
}

CLDIAL.GetItem = function(item)
    return ffi.C.GetDlgItem(hdlg, item)
end

CLDIAL.SelectTopIndex = function()
    ffi.C.PostMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x186, 0, 0)
    ffi.C.PostMessageA(hdlg, 273, 0x103FC, 0)
end

CLDIAL.SetIcon = function(item, image, from_file)
    if image == "NONE" then
        ffi.C.PostMessageA(CLDIAL.GetItem(item), 0x0170, 0, 0)
    elseif from_file then
        ffi.C.PostMessageA(CLDIAL.GetItem(item), 0x0170, ffi.C.LoadImageA(0, _GetCStr(GetCustomImgsPath() .. image .. ".ICO"), 1, 0, 0, 0x8030), 0)
    else
        ffi.C.PostMessageA(CLDIAL.GetItem(item), 0x0170, ffi.C.LoadIconA(_LoadIcon()[2], image), 0)
    end
end

CLDIAL.SetText = function(item, text)
    ffi.C.SetDlgItemTextA(hdlg, item, text)
end

CLDIAL.GetText = function(item, addr)
    return ffi.C.GetDlgItemTextA(hdlg, item, ffi.cast("int", addr), 64)
end

CLDIAL.ShowWindow = function(wnd)
    ffi.C.ShowWindow(CLDIAL.GetItem(wnd), 1)
end

CLDIAL.HideWindow = function(wnd)
    ffi.C.ShowWindow(CLDIAL.GetItem(wnd), 0)
end

CLDIAL.EnableWindow = function(wnd)
    return ffi.C.EnableWindow(CLDIAL.GetItem(wnd), 1)
end

CLDIAL.DisableWindow = function(wnd)
    return ffi.C.EnableWindow(CLDIAL.GetItem(wnd), 0)
end

CLDIAL.SetDefaultFont = function(item)
    ffi.C.SendMessageA(CLDIAL.GetItem(item), 0x30, ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.Author), 0x31, 0, 0), 0)
end

CLDIAL.GetDlgItemSize = function(item)
    local itemRect = ffi.new("Rect[1]")
    local dlgRect = ffi.new("Rect[1]")
    ffi.C.GetWindowRect(CLDIAL.GetItem(item), itemRect)
    ffi.C.GetWindowRect(hdlg, dlgRect)
    local spx, spy = itemRect[0].Left - dlgRect[0].Left - 3, itemRect[0].Top - dlgRect[0].Top - 3
    local w, h = math.abs(itemRect[0].Right - itemRect[0].Left), math.abs(itemRect[0].Bottom - itemRect[0].Top)
    return ffi.new("Rect", {spx, spy, w, h})
end

CLDIAL.CreateLoad2Button = function()
	local playButtonRect = CLDIAL.GetDlgItemSize(DlgItems.ButtonPlay)
	local loadButtonRect = CLDIAL.GetDlgItemSize(DlgItems.ButtonLoad)
	local x = 2*loadButtonRect.Left - playButtonRect.Left
	local y = playButtonRect.Top
	local w = playButtonRect.Right
	local h = playButtonRect.Bottom
	ffi.C.CreateWindowExA(4, "BUTTON", "Load SP2", 0x58010000, x, y, w, h, hdlg, DlgItems.ButtonLoad2, 0, 0)
	CLDIAL.SetDefaultFont(DlgItems.ButtonLoad2)
end

CLDIAL.CreateStatusText = function()
	local dateRect = CLDIAL.GetDlgItemSize(DlgItems.Date)
	local authorRect = CLDIAL.GetDlgItemSize(DlgItems.Author)
	local x = dateRect.Left
	local y = 2*authorRect.Top - dateRect.Top
	local w = dateRect.Right
	local h = dateRect.Bottom
	ffi.C.CreateWindowExA(4, "STATIC", "Status: Not Played", 0x5002C200, x, y, w, h, hdlg, DlgItems.Status, 0, 0)
	CLDIAL.SetDefaultFont(DlgItems.Status)
end

CLDIAL.CreateLevelCounter = function()
	local dateRect = CLDIAL.GetDlgItemSize(DlgItems.Date)
	local listboxRect = CLDIAL.GetDlgItemSize(DlgItems.ListBox)
	local h = dateRect.Bottom
	local x = listboxRect.Left + listboxRect.Right - 60
	local y = listboxRect.Top - 5 - h
	ffi.C.CreateWindowExA(4, "STATIC", "", 0x5002C200, x, y, 65, h, hdlg, DlgItems.LevelsCount, 0, 0)
	CLDIAL.SetText(DlgItems.LevelsCount, "Levels" .. ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x18B, 0, 0))
	CLDIAL.SetDefaultFont(DlgItems.LevelsCount)
end

CLDIAL.CreateRecCheckbox = function()
	local dateRect = CLDIAL.GetDlgItemSize(DlgItems.Date)
	local listboxRect = CLDIAL.GetDlgItemSize(DlgItems.ListBox)
	local w = listboxRect.Right - 70
	local h = dateRect.Bottom
	local x = listboxRect.Left
	local y = listboxRect.Top - 5 - dateRect.Bottom
	ffi.C.CreateWindowExA(4, "BUTTON", "Showing all levels", 0x50010006, x, y, w, h, hdlg, DlgItems.CheckBox, 0, 0)
	CLDIAL.SetDefaultFont(DlgItems.CheckBox)
end

CLDIAL.CreateRecIcon = function()
	local iconRect = CLDIAL.GetDlgItemSize(DlgItems.GameIcon)
	local infoboxRect = CLDIAL.GetDlgItemSize(DlgItems.InfoBox)
	local dateRect = CLDIAL.GetDlgItemSize(DlgItems.Date)
	local x = infoboxRect.Right - iconRect.Left - 12
	local y = iconRect.Top + dateRect.Bottom
	local w, h = iconRect.Right, iconRect.Bottom
	ffi.C.CreateWindowExA(4, "STATIC", "", 0x50000843, x, y, w, h, hdlg, DlgItems.RecIcon, 0, 0)
end

CLDIAL.IsSinglePlayerDialog = function()
	local text = ffi.new("char[64]")
	CLDIAL.GetText(DlgItems.ButtonPlay, text)
	return ffi.string(text) == "Play!"
end

CLDIAL.UpdateListBox = function()
    local state = 0
    if RecsData then
        state = ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.CheckBox), 0xF0, 0, 0) -- get checkbox state
		if state == 1 then
			CLDIAL.SetText(DlgItems.CheckBox, "Showing only recommended")
		elseif state == 2 then
			CLDIAL.SetText(DlgItems.CheckBox, "Showing only highly recommended")
		else
			CLDIAL.SetText(DlgItems.CheckBox, "Showing all")
		end
    end
    ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x184, 0, 0) -- reset content
    for name, vals in pairs(CustomLevels) do
        if string.upper(name):match(SearchFilter) and vals.Rec >= state then
            ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x180, 0, GetCStrInt(name)) -- add level to the listbox
        end
    end
	-- update level counter:
	CLDIAL.SetText(DlgItems.LevelsCount, "Levels: " .. ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x18B, 0, 0))
    CLDIAL.SelectTopIndex()
    if ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x18B, 0, 0) <= 0 then -- if listbox is empty
		CLDIAL.SetIcon(DlgItems.GameIcon, "NONE")
		CLDIAL.SetIcon(DlgItems.LevelIcon, "NONE")
		CLDIAL.SetIcon(DlgItems.RecIcon, "NONE")
		CLDIAL.SetText(DlgItems.Date, "")
		CLDIAL.SetText(DlgItems.Author, "")
    end
end

CLDIAL.LoadListBox = function()
    local lb = CLDIAL.GetItem(DlgItems.ListBox)
    local custompath = GetCustomPath():sub(1,-2)
    if _FileExists(GetCustomPath().."\\_recs.lua") then
        RecsData = require'Custom._recs'
    end
    -- open all files and get data from headers:
    if _DirExists(custompath) then
        local failed = {}
        for filename in lfs.dir(custompath) do
            if #filename > 4 and string.upper(filename):sub(-4) == ".WWD" then 
                local f = io.open(custompath .. "\\" .. filename, "rb")
                if f then
                    local header = ffi.new("char[1][208]")
                    header[0] = f:read(208)
                    io.close(f)
                    local name = filename:sub(1,-5)
                    local leveln = tonumber(ffi.string(ffi.cast("const char*", header[0]+16)):match"%d+")
                    if leveln == nil or leveln > 14 or leveln < 0 then 
                        leveln = 0 
                    end
                    local author = ffi.string(ffi.cast("const char*", header[0]+80))
                    local date = FixDate(ffi.string(ffi.cast("const char*", header[0]+144)))
                    local gametype = "OLDCLAW"
                    if _ChangeDir("Custom") == 0 then
				        if _ChangeDir(custompath .. "\\" .. name) == 0 then
                            gametype = "CLAW"
				            _ChangeDir("..")
				        end
					    _ChangeDir("..")
				    end
                    local rec = 0
                    if RecsData then
                        rec = RecsData[name] or 0
                    end
					local size = math.floor(_GetFileSize(custompath .. "\\" .. filename)/1024)
                    CustomLevels[name] = {Version = gametype, Level = leveln, Author = author, Date = date, Rec = rec, Size = size} -- add level and info to the internal table
                    ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x180, 0, GetCStrInt(name)) -- add level to the listbox
                else
                    table.insert(failed, filename)
                end
            end
        end
        -- Show message box if the function failed to open some files:
        local num_fails = #failed
        if num_fails > 0 then
            local str = ""
            local reason = ""
            if num_fails == 1 then str = "file" else str = "files" end
            if num_fails < 5 then reason = "Bad encoding - renaming the files should solve it." else
            reason = "Unknown" end
            MessageBox("Failed to open " .. num_fails .." " .. str .. ": \n"..table.concat(failed, ", ").."\nPossible reason: "..reason)
        end
        CLDIAL.SetText(DlgItems.LevelsCount, "Levels: " .. ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x18B, 0, 0))
        CLDIAL.SelectTopIndex()
    end
end

CLDIAL.CustomLevelWindow = function(ptr)

    ptr = ffi.cast("int", ptr)
    local iptr = ffi.cast("int*",ptr)
	
	if _chameleon[0] == chamStates.OnPostMessage then
		if ptr == 333 then
			mdl_exe._TimeThings(_nResult)
			if GetSelectedLevelName() ~= "" then
				if ffi.C.DialogBoxParamA(nRes(2,3), "CUSTOMWORLD", nRes(1,1), 0x438380, 0) == 1 then
					local custom = GetCustomPath()..GetSelectedLevelName()..".WWD"
					-- Start the game:
					snRes(ffi.cast("int", custom), 49)
					ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8005, 0)
				end
			end
			while ffi.C.ShowCursor(0) >= 0 do end
		end
    end

	if _chameleon[0] == chamStates.CustomLevelsWindow then
		hdlg = iptr[4]
		ffi.C.ShowCursor(1)

        -- Dialog start:
		if iptr[5] == 0x110 then
			-- Create new icon:
			CLDIAL.CreateRecIcon()
			-- Create new static text, level counter:
			CLDIAL.CreateLevelCounter()
            -- Set default search text to ".*":
            CLDIAL.LoadListBox()
            SearchFilter = ".*"
            -- Reset the save point just in case:
			if mdl_exe.CSavePoint[0] ~= 0 then
				mdl_exe.CSavePoint[0] = 0
			end
            -- if the recommendations module exists:
            if _FileExists(GetCustomPath().."\\_recs.lua") then
				CLDIAL.CreateRecCheckbox()
            end
			-- if the custom saves file exists:
            if _FileExists(GetClawPath() .. "\\CustomSaves.lua") then
				-- read the file:
                local _file = assert(io.open(GetClawPath() .. "\\CustomSaves.lua", "r"))
                SavesData = _file:read("*all")
                io.close(_file)
            else
                SavesData = nil
            end
			-- for single player's dialog:
			if CLDIAL.IsSinglePlayerDialog() then
				CLDIAL.CreateLoad2Button()
				CLDIAL.CreateStatusText()
				CLDIAL.SetText(DlgItems.ButtonLoad, "Load SP1")
			end
            -- Focus:
			ffi.C.SetFocus(hdlg)
		end

        -- Dialog's running:
		if iptr[5] == 0x111 then

            -- Play from save point 1:
            if iptr[6] == DlgItems.ButtonLoad then
				mdl_exe.CSavePoint[0] = 1
				iptr[6] = DlgItems.ButtonPlay
            end

            -- Play from save point 2:
            if iptr[6] == DlgItems.ButtonLoad2 then
				mdl_exe.CSavePoint[0] = 2
				iptr[6] = DlgItems.ButtonPlay
            end

            -- Change the "only rec" button state:
            if iptr[6] == DlgItems.CheckBox then
                CLDIAL.UpdateListBox()
            end

            -- Start the selected level:
			if iptr[6] == DlgItems.ButtonPlay then
				SavesData = nil
				if ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x188, 0, 0) >= 0 then -- get current selection
					ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x189, ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x188, 0, 0), _WwdCustomsStr) -- set name from the current selection
				else
					mdl_exe.CSavePoint[0] = 0
                    ffi.cast("char*",_WwdCustomsStr)[0] = 0
				end
            end

            -- Get info based on selected level in list:
			if iptr[6] == 0x103FC then
                if ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x18B, 0, 0) > 0 then -- if listbox is not empty
					local level = ffi.new("char[128]")
					-- Get name and data from the current selection:
					do
						local cur_sel = ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x188, 0, 0)
						ffi.C.SendMessageA(CLDIAL.GetItem(DlgItems.ListBox), 0x189, cur_sel, ffi.cast("int", level)) 
					end
                    local info = CustomLevels[ffi.string(level)]
					-- Set base description:
					do
						CLDIAL.SetIcon(DlgItems.GameIcon, info.Version)
						local ico = "L" .. info.Level
						CLDIAL.SetIcon(DlgItems.LevelIcon, ico)
						local info1 = "Created: " .. info.Date .. ", Size: " .. info.Size .. "KB"
						CLDIAL.SetText(DlgItems.Date, info1)
						local info2 = "Author: ".. info.Author
						CLDIAL.SetText(DlgItems.Author, info2)
					end
					-- Set REC icon:
                    if info.Rec == 1 then
                        CLDIAL.SetIcon(DlgItems.RecIcon, "REC", true)
                    elseif info.Rec > 1 then
                        CLDIAL.SetIcon(DlgItems.RecIcon, "REC2", true)
                    else
                        CLDIAL.SetIcon(DlgItems.RecIcon, "NONE")
                    end
					-- For single-player dialog:
                    if SavesData then
						if CLDIAL.IsSinglePlayerDialog() then
							-- Update status:
							local _find = string.find(SavesData, '["'..ffi.string(level)..'"][0] = ', 1, true)
							if _find then
								local vals = SavesData:match('saves%["'.. ffi.string(level) ..'"%]%[0%] = {(.-)}')
								local gath = tonumber(vals:match"(%d+),%d+,%d+")
								local all = tonumber(vals:match"%d+,(%d+),%d+")
								if CalcSum2(ffi.string(level), gath, all) == tonumber(vals:match"%d+,%d+,(%d+)") then
									if all ~= 0 then
										local perc = math.floor(gath/all*1000)/10
										CLDIAL.SetText(DlgItems.Status, "Status: Completed " .. perc .. "%")
									else
										CLDIAL.SetText(DlgItems.Status, "Status: Completed 100%")
									end
								else
									CLDIAL.SetText(DlgItems.Status, "Status: ???")
								end
							else
								_find = string.find(SavesData, '["'..ffi.string(level)..'"] = ', 1, true)
								if _find then
									CLDIAL.SetText(DlgItems.Status, "Status: Played")
								else
									CLDIAL.SetText(DlgItems.Status, "Status: Not Played")
								end
							end
							-- Show/hide "Load SP1" button:
							_find = string.find(SavesData, '["'..ffi.string(level)..'"][1] = {', 1, true)
							if LoadButtonState == 0 and _find then
								CLDIAL.EnableWindow(DlgItems.ButtonLoad)
								LoadButtonState = 1
							elseif LoadButtonState == 1 and not _find then
								CLDIAL.DisableWindow(DlgItems.ButtonLoad)
								LoadButtonState = 0
							end
							-- Show/hide "Load SP2" button:
							_find = string.find(SavesData, '["'..ffi.string(level)..'"][2] = {', 1, true)
							if LoadButton2State == 0 and _find then
								CLDIAL.EnableWindow(DlgItems.ButtonLoad2)
								LoadButton2State = 1
							elseif LoadButton2State == 1 and not _find then
								CLDIAL.DisableWindow(DlgItems.ButtonLoad2)
								LoadButton2State = 0
							end
						end
                    end
				end
            end
		end

        -- SearchBox change:
		if iptr[6] == 0x300029A then
			local text = ffi.new("char[64]")
            if CLDIAL.GetText(DlgItems.SearchBox, text) >= 1 then
                SearchFilter = string.upper(ffi.string(text))
			else 
                SearchFilter = ".*"
			end
            CLDIAL.UpdateListBox()
		end	

	end
end

return CLDIAL
