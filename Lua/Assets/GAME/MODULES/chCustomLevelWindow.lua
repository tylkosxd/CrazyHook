_WwdCustomsStr = 0x50BEE5
local _SearchFilter = ""
local _saves = nil
local _recs = nil
local hdlg = ffi.new("int")
local LoadButtonState = 1
local _LoadIcon = ffi.cast("int* (*__cdecl)()",0x50731A)
local _ChangeDir = ffi.cast("int (*__cdecl)(const char*)",0x4F64DE)
local CustomLevels = {}
local Months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
--local _atoi = ffi.cast("int (*__cdecl)(const char*)", 0x4A5EA6)
--local f0 = ffi.cast("int (*__thiscall)(int, int)", 0x4CB6B0)
--local _GetSelectionCount = ffi.cast("int (*__cdecl)(int)", 0x4385A0)
--local _ReloadListBox = ffi.cast("signed int (*__cdecl)(int)", 0x438484)

local _Items = {
    Title           = -1,
    ButtonPlay      = 1,
    ButtonCancel    = 2,
    ButtonLoad      = 3,
    LoadTitle       = 0x41,
    Load1Button     = 0x42,
    Load2Button     = 0x43,
    LoadBackButton  = 0x44,
    CheckBox        = 0x69,
    LevelsCount     = 0xA1,
    LevelIcon       = 0x22B,
    GameIcon        = 0x22C,
    RecIcon         = 0x22D,
    SearchBox       = 0x29A,
    ListBox         = 0x3FC,
    LoadWnd         = 0x3FD,
    Date            = 0x408,
    Author          = 0x409,
    InfoBox         = 0x40A,
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

local function _GetLevelName()
    return ffi.string(ffi.cast("const char*", _WwdCustomsStr))
end

local function PlayLevel()
    return ffi.C.DialogBoxParamA(nRes(2,3), "CUSTOMWORLD", nRes(1,1), 0x438380, 0) == 1
end

local function SelectTopIndex()
    ffi.C.PostMessageA(GetItem(_Items.ListBox), 0x186, 0, 0)
    ffi.C.PostMessageA(hdlg, 273, 0x103FC, 0)
end

local function SetIcon(item, image, from_file)
    if image == "NONE" then
        ffi.C.PostMessageA(GetItem(item), 0x0170, 0, 0)
    elseif from_file then
        ffi.C.PostMessageA(GetItem(item), 0x0170, ffi.C.LoadImageA(0, _GetCStr(GetCustomImgsPath() .. image .. ".ICO"), 1, 0, 0, 0x8030), 0)
    else
        ffi.C.PostMessageA(GetItem(item), 0x0170, ffi.C.LoadIconA( _LoadIcon()[2], image ), 0)
    end
end

local function SetText(item, text)
    ffi.C.SetDlgItemTextA(hdlg, item, text)
end

local function GetText(item, addr)
    return ffi.C.GetDlgItemTextA(hdlg, item, ffi.cast("int", addr), 64)
end

local function RunGame(level)
    snRes(ffi.cast("int", level), 49)
    ffi.C.PostMessageA(nRes(1,1), 0x111, 0x8005, 0)
end

function GetItem(item)
    return ffi.C.GetDlgItem(hdlg, item)
end

local function ShowWindow(wnd)
    ffi.C.ShowWindow(GetItem(wnd), 1)
end

local function HideWindow(wnd)
    ffi.C.ShowWindow(GetItem(wnd), 0)
end

local function EnableWindow(wnd)
    return ffi.C.EnableWindow(GetItem(wnd), 1)
end

local function DisableWindow(wnd)
    return ffi.C.EnableWindow(GetItem(wnd), 0)
end

local function SetDefaultFont(item)
    ffi.C.SendMessageA(GetItem(item), 0x30, ffi.C.SendMessageA(GetItem(_Items.Author), 0x31, 0, 0), 0)
end

local function GetDlgSize()
	local dlgRect = ffi.new("Rect[1]")
	ffi.C.GetWindowRect(hdlg, dlgRect)
	dlgRect[0].Right = dlgRect[0].Right - dlgRect[0].Left
	dlgRect[0].Bottom = dlgRect[0].Bottom - dlgRect[0].Top
	return dlgRect
end

local function GetItemSize(item)
    local itemRect = ffi.new("Rect[1]")
    local dlgRect = ffi.new("Rect[1]")
    ffi.C.GetWindowRect(GetItem(item), itemRect)
    ffi.C.GetWindowRect(hdlg, dlgRect)
    local spx, spy = itemRect[0].Left - dlgRect[0].Left, itemRect[0].Top - dlgRect[0].Top
    local w, h = math.abs(itemRect[0].Right - itemRect[0].Left), math.abs(itemRect[0].Bottom - itemRect[0].Top)
    return ffi.new("Rect", {spx, spy, w, h})
end

local function FixDate(str)
    if str:match"(%d%d:%d%d %d%d%.%d%d%.%d%d%d%d)" then
        local mon = Months[tonumber(str:sub(10,11))]
        local day = str:sub(7,8)
        local year = str:sub(-4)
        return mon.." "..day..", "..year
    else
        return str
    end
end

CLDIAL = {}

CLDIAL.UpdateListBox = function()
    local state = 0
    if _recs then
        state = ffi.C.SendMessageA(GetItem(_Items.CheckBox), 0xF0, 0, 0) -- get checkbox state
    end
    ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x184, 0, 0) -- reset content
    for name, vals in pairs(CustomLevels) do
        if string.upper(name):match(_SearchFilter) and vals.Rec >= state then
            ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x180, 0, GetCStrInt(name)) -- add level to the listbox
        end
    end
    SetText(_Items.LevelsCount, "Levels: " .. ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x18B, 0, 0)) -- update level counter
    SelectTopIndex()
    if ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x18B, 0, 0) <= 0 then -- if listbox is empty
		SetIcon(_Items.GameIcon, "NONE")
		SetIcon(_Items.LevelIcon, "NONE")
		SetIcon(_Items.RecIcon, "NONE")
		SetText(_Items.Date, "")
		SetText(_Items.Author, "")
    end
end

CLDIAL.LoadListBox = function()
    local lb = GetItem(_Items.ListBox)
    local custompath = GetCustomPath():sub(1,-2)
    if _FileExists(GetCustomPath().."\\_recs.lua") then
        _recs = require'Custom._recs'
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
                    if _recs then
                        rec = _recs[name] or 0
                    end
                    CustomLevels[name] = {Version = gametype, Level = leveln, Author = author, Date = date, Rec = rec} -- add level and info to the internal table
                    ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x180, 0, GetCStrInt(name)) -- add level to the listbox
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
        SetText(_Items.LevelsCount, "Levels: " .. ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x18B, 0, 0))
        SelectTopIndex()
    end
end

CLDIAL.CustomLevelWindow = function(ptr)

    ptr = ffi.cast("int", ptr)
    local iptr = ffi.cast("int*",ptr)
	
	if _chameleon[0] == chamStates.OnPostMessage then
		if ptr == 333 then
			mdl_exe._TimeThings(_nResult)
			--f0(Game(1), Game(1,5))
			--ffi.cast("int (*)(int)", Game(7,0,0,10))(Game(7,0))
			if PlayLevel() and _GetLevelName() ~= "" then
                local custom = GetCustomPath().._GetLevelName()..".WWD"
				RunGame(custom)
			end
			while ffi.C.ShowCursor(0) >= 0 do end
		end
    end

	if _chameleon[0] == chamStates.CustomLevelsWindow then
		hdlg = iptr[4]
		ffi.C.ShowCursor(1)

        -- Dialog start:
		if iptr[5] == 0x110 then
            -- Set default search text to ".*":
            CLDIAL.LoadListBox()
            _SearchFilter = ".*"
            -- Reset the save point just in case:
            mdl_exe.CSavePoint[0] = 0
            -- if the recommendations module exists:
            if _FileExists(GetCustomPath().."\\_recs.lua") then
                -- Create CheckBox:
                ffi.C.CreateWindowExA(4, "BUTTON", "Only recommended", 0x50010006, 10, 51, 140, 20, hdlg, _Items.CheckBox, 0, 0)
                SetDefaultFont(_Items.CheckBox)
            end
			-- create saves "tab" if saves file exists:
            if _FileExists(GetClawPath() .. "\\CustomSaves.lua") then
                local _file = assert(io.open(GetClawPath() .. "\\CustomSaves.lua", "r"))
                _saves = _file:read("*all")
                io.close(_file)
                LoadButtonState = 1
                ffi.C.CreateWindowExA(4, "STATIC", "", 0x4002C201, 1, 48, 312, 24, hdlg, _Items.LoadTitle, 0, 0)
                ffi.C.CreateWindowExA(4, "BUTTON", "Save point 1", 0x40010000, 65, 100, 188, 24, hdlg, _Items.Load1Button, 0, 0)
                SetDefaultFont(_Items.Load1Button)
                ffi.C.CreateWindowExA(4, "BUTTON", "Save point 2", 0x40010000, 65, 160, 188, 24, hdlg, _Items.Load2Button, 0, 0)
                SetDefaultFont(_Items.Load2Button)
                ffi.C.CreateWindowExA(4, "BUTTON", "Go back", 0x40010000, 65, 220, 188, 24, hdlg, _Items.LoadBackButton, 0, 0)
                SetDefaultFont(_Items.LoadBackButton)
            else
                _saves = nil
                DisableWindow(_Items.ButtonLoad)
                LoadButtonState = 0
            end
            -- Create new icon:
            ffi.C.CreateWindowExA(4, "STATIC", "", 0x50000843, 320, 308, 24, 25, hdlg, _Items.RecIcon, 0, 0)
            -- Create new static text:
            ffi.C.CreateWindowExA(4, "STATIC", "", 0x5002C200, 192, 354, 80, 25, hdlg, _Items.LevelsCount, 0, 0)
            SetText(_Items.LevelsCount, "Levels: " .. ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x18B, 0, 0))
            SetDefaultFont(_Items.LevelsCount)
            -- Focus on the dialog:
			ffi.C.SetFocus(hdlg)
		end

        -- Dialog's running:
		if iptr[5] == 0x111 then

            -- go to loading:
            if iptr[6] == _Items.ButtonLoad then
                local mapname = ffi.new("char[128]")
                if ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x188, 0, 0) >= 0 then -- if current selection
					ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x189, ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x188, 0, 0), ffi.cast("int", mapname))  -- get name from the current selection
				end
                if ffi.string(mapname) ~= "" then
                    DisableWindow(_Items.ButtonLoad)
                    LoadButtonState = 0
                    DisableWindow(_Items.ButtonPlay)
                    HideWindow(_Items.ListBox)
                    HideWindow(_Items.CheckBox)
                    HideWindow(_Items.SearchBox)
                    HideWindow(_Items.TextSearch)
                    HideWindow(_Items.LevelsCount)
                    ShowWindow(_Items.LoadTitle)
                    SetText(_Items.LoadTitle, ffi.string(mapname))
                    ShowWindow(_Items.Load1Button)
                    ShowWindow(_Items.Load2Button)
                    ShowWindow(_Items.LoadBackButton)
                end
            end

            -- play selected level from SP1:
            if iptr[6] == _Items.Load1Button then
                _saves = nil
                mdl_exe.CSavePoint[0] = 1
                iptr[6] = _Items.ButtonPlay
            end

            -- play selected level from SP2:
            if iptr[6] == _Items.Load2Button then
                _saves = nil
                mdl_exe.CSavePoint[0] = 2
                iptr[6] = _Items.ButtonPlay
            end

            -- go back from loading to listbox:
            if iptr[6] == _Items.LoadBackButton then
                EnableWindow(_Items.ButtonLoad)
                LoadButtonState = 1
                EnableWindow(_Items.ButtonPlay)
                ShowWindow(_Items.ListBox)
                ShowWindow(_Items.CheckBox)
                ShowWindow(_Items.SearchBox)
                ShowWindow(_Items.TextSearch)
                ShowWindow(_Items.LevelsCount)
                HideWindow(_Items.LoadTitle)
                HideWindow(_Items.Load1Button)
                HideWindow(_Items.Load2Button)
                HideWindow(_Items.LoadBackButton)
            end

            -- Change the "only rec" button state:
            if iptr[6] == _Items.CheckBox then
                CLDIAL.UpdateListBox()
            end

            -- Start the selected level:
			if iptr[6] == _Items.ButtonPlay then
				if ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x188, 0, 0) >= 0 then -- get current selection
					ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x189, ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x188, 0, 0), _WwdCustomsStr) -- set name from the current selection
				else
                    ffi.cast("char*",_WwdCustomsStr)[0] = 0
				end
            end

            -- Get info based on selected level in list:
			if iptr[6] == 0x103FC then
                if ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x18B, 0, 0) > 0 then -- if listbox is not empty
					local str = ffi.new("char[128]")
					ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x189, ffi.C.SendMessageA(GetItem(_Items.ListBox), 0x188, 0, 0), ffi.cast("int",str))  -- get name from the current selection
                    local info = CustomLevels[ffi.string(str)]
                    SetIcon(_Items.GameIcon, info.Version)
                    SetIcon(_Items.LevelIcon, "L"..info.Level)
		            SetText(_Items.Date, "Created " .. info.Date)
                    SetText(_Items.Author, "By ".. info.Author)
                    if info.Rec == 1 then
                        SetIcon(_Items.RecIcon, "REC", true)
                    elseif info.Rec > 1 then
                        SetIcon(_Items.RecIcon, "REC2", true)
                    else
                        SetIcon(_Items.RecIcon, "NONE")
                    end
                    if _saves then
                        local _find = string.find(_saves, '["'..ffi.string(str)..'"]', 1, true)
                        if LoadButtonState == 0 and _find then
                            EnableWindow(_Items.ButtonLoad)
                            LoadButtonState = 1
                        elseif LoadButtonState == 1 and not _find then
                            DisableWindow(_Items.ButtonLoad)
                            LoadButtonState = 0
                        end
                        if LoadButtonState == 1 then
                            if string.find(_saves, '["'..ffi.string(str)..'"][1]', 1, true) then
                                EnableWindow(_Items.Load1Button)
                            else
                                DisableWindow(_Items.Load1Button)
                            end
                            if string.find(_saves, '["'..ffi.string(str)..'"][2]', 1, true) then
                                EnableWindow(_Items.Load2Button)
                            else
                                DisableWindow(_Items.Load2Button)
                            end
                        end
                    end
				end
            end
		end

        -- SearchBox change:
		if iptr[6] == 0x300029A then
			local text = ffi.new("char[64]")
            if GetText(_Items.SearchBox, text) >= 1 then
                _SearchFilter = string.upper(ffi.string(text))
			else 
                _SearchFilter = ".*"
			end
            CLDIAL.UpdateListBox()
		end	

	end
end

return CLDIAL
