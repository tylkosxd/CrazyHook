--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------- [[ Custom level's window module ]] -------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--[[ It modifies and handles the 'Select Custom Level' window. It's a bit messy.
If you don't understand something - WinUser.h is over 10000 lines long... so just open it and look for the constants you need.]]

local ITEMS = require'game_custom_dlg.cdlg_items'

local ITEM_ID = ITEMS.Items

local SAVES = nil -- 'CustomSaves.lua' file

local ALL_LEVELS_DATA = {}

local LISTBOX = {}

local C = ffi.C

local hdlg = ffi.new("int")

local WM_INITDIALOG	= 0x110
local WM_COMMAND	= 0x111

local load1ButtonState = 0
local load2ButtonState = 0

local singleplayer = false

--[[ Some functions in the executable for reference:
local ChangeDir = ffi.cast("int (*__cdecl)(const char*)", 0x4F64DE)
local f0 = ffi.cast("int (*__thiscall)(int, int)", 0x4CB6B0)
local GetSelectionCount = ffi.cast("int (*__cdecl)(int)", 0x4385A0)
local ReloadListBox = ffi.cast("signed int (*__cdecl)(int)", 0x438484)]]

local getHandle = ffi.cast("int* (*__cdecl)()", 0x50731A)

local function getCustomPath()
    return GetClawPath() .. ffi.string(ffi.cast("const char*",0x524DAC)) -- returns [claw]\\Custom\\
end

local levelCompletionSum = require"game_csaves.csaves_file".GetCompletionSum

local DIAL = {
	Width = ffi.cast("short*", 0x5CEF12)[0],
	Height = ffi.cast("short*", 0x5CEF14)[0],
	SearchFilter = ".",
	ChosenLevel = ""
}

DIAL.Param = function()
	return C.DialogBoxParamA(nRes(2,3), "CUSTOMWORLD", nRes(1,1), 0x438380, 0)
end

DIAL.GetItem = function(item)
    return C.GetDlgItem(hdlg, item)
end

DIAL.SetIcon = function(item, image, fromFile)
    if not image or image == "NONE" then
        C.PostMessageA(DIAL.GetItem(item), 0x170, 0, 0)
    elseif fromFile then
		local path = GetClawPath() .. "\\Assets\\STATES\\DIALOGS\\IMAGES\\CUSTOMWORLD\\"
        C.PostMessageA(DIAL.GetItem(item), 0x170, C.LoadImageA(0, GetASCIIZ(path .. image .. ".ICO"), 1, 0, 0, 0x8030), 0)
    else
        C.PostMessageA(DIAL.GetItem(item), 0x170, C.LoadIconA(getHandle()[2], image), 0)
    end
end

DIAL.SetText = function(item, text)
    C.SetDlgItemTextA(hdlg, item, text)
end

DIAL.GetText = function(item, addr)
    return C.GetDlgItemTextA(hdlg, item, ffi.cast("int", addr), 64)
end

DIAL.ShowWindow = function(wnd)
    C.ShowWindow(DIAL.GetItem(wnd), 1)
end

DIAL.HideWindow = function(wnd)
    C.ShowWindow(DIAL.GetItem(wnd), 0)
end

DIAL.EnableWindow = function(wnd)
    return C.EnableWindow(DIAL.GetItem(wnd), 1)
end

DIAL.DisableWindow = function(wnd)
    return C.EnableWindow(DIAL.GetItem(wnd), 0)
end

DIAL.IsSinglePlayer = function()
	local text = ffi.new("char[64]")
	DIAL.GetText(ITEM_ID.ButtonPlay, text)
	return ffi.string(text) == "Play!"
end

DIAL.UpdateLevelStatus = function(level)
	if not SAVES then return end
	local status = "Status: "
	local entryShort = 'saves["' .. level .. '"]'
	local find = string.find(SAVES, entryShort..'[0]', 1, true)
	if find then
		local vals = SAVES:match(EscapeMagicChars(entryShort..'[0]') .. ' = {(.-)}')
		local gath = tonumber(vals:match"^(%d+),") -- gathered treasures
		local all = tonumber(vals:match",(%d+),")
		local checksum = tonumber(vals:match",(%d+)$")
		if levelCompletionSum(level, gath, all) == checksum then
			local percentage = all ~= 0 and math.floor(gath/all*1000)/10 or 100
			percentage = percentage > 100 and 100 or percentage
			status = status .. "Completed, " .. percentage .. "%"
		else
			status = status .. "Unknown"
		end
	else
		local saveFind = string.find(SAVES, entryShort, 1, true)
		status = saveFind and status .. "Played" or status .. "Not Played"
	end
	DIAL.SetText(ITEM_ID.Status, status)
end

DIAL.UpdateLoadButtons = function(level)
	if not SAVES then return end
	-- Show/hide "Load SP1" button:
	local save1 = string.find(SAVES, 'saves["'..level..'"][1]', 1, true)
	if load1ButtonState == 0 and save1 then
		DIAL.EnableWindow(ITEM_ID.ButtonLoad)
		load1ButtonState = 1
	elseif load1ButtonState == 1 and not save1 then
		DIAL.DisableWindow(ITEM_ID.ButtonLoad)
		load1ButtonState = 0
	end
	-- Show/hide "Load SP2" button:
	local save2 = string.find(SAVES, 'saves["'..level..'"][2]', 1, true)
	if load2ButtonState == 0 and save2 then
		DIAL.EnableWindow(ITEM_ID.ButtonLoad2)
		load2ButtonState = 1
	elseif load2ButtonState == 1 and not save2 then
		DIAL.DisableWindow(ITEM_ID.ButtonLoad2)
		load2ButtonState = 0
	end
end

DIAL.UpdateDescription = function()
	local level = LISTBOX.GetCurrentSelection()
	local info = ALL_LEVELS_DATA[level]
	DIAL.SetIcon(ITEM_ID.GameIcon, info.Version)
	DIAL.SetIcon(ITEM_ID.LevelIcon, "L" .. info.Level)
	DIAL.SetText(ITEM_ID.Date, "Created: " .. info.Date .. ", Size: " .. info.Size .. "KB")
	DIAL.SetText(ITEM_ID.Author, "Author: ".. info.Author)
	local recIcon = info.Rec == 1 and "REC" or info.Rec == 2 and "REC2" or "NONE"
	DIAL.SetIcon(ITEM_ID.RecIcon, recIcon, true)
	if not singleplayer then return end
	DIAL.UpdateLevelStatus(level)
	DIAL.UpdateLoadButtons(level)
end

LISTBOX.SelectTopIndex = function()
    C.PostMessageA(DIAL.GetItem(ITEM_ID.ListBox), 0x186, 0, 0)
    C.PostMessageA(hdlg, 0x111, 0x103FC, 0)
end

LISTBOX.Clear = function()
	C.SendMessageA(DIAL.GetItem(ITEM_ID.ListBox), 0x184, 0, 0)
end

LISTBOX.AddItem = function(name)
	C.SendMessageA(DIAL.GetItem(ITEM_ID.ListBox), 0x180, 0, ffi.cast("int", GetASCIIZ(name)))
end

LISTBOX.GetCount = function()
	return C.SendMessageA(DIAL.GetItem(ITEM_ID.ListBox), 0x18B, 0, 0)
end

LISTBOX.GetCurrentSelection = function()
	local level = ffi.new("char[128]")
	local curSel = C.SendMessageA(DIAL.GetItem(ITEM_ID.ListBox), 0x188, 0, 0)
	C.SendMessageA(DIAL.GetItem(ITEM_ID.ListBox), 0x189, curSel, ffi.cast("int", level))
	return ffi.string(level)
end

LISTBOX.Init = function()
	local customPath = getCustomPath()
	if not DirExists(customPath) then return end
	ALL_LEVELS_DATA = require('game_custom_dlg.cdlg_wwd_read')(hdlg, customPath) or {}
	DIAL.SetText(ITEM_ID.LevelsCount, "Levels: " .. LISTBOX.GetCount())
	LISTBOX.SelectTopIndex()
end

LISTBOX.Update = function()
    local state = C.SendMessageA(DIAL.GetItem(ITEM_ID.CheckBox), 0xF0, 0, 0)
	local text = state == 1 and "Showing only recommended" or state == 2 and "Showing only highly recommended" or "Showing all"
	DIAL.SetText(ITEM_ID.CheckBox, text)
    LISTBOX.Clear()
    for name, vals in pairs(ALL_LEVELS_DATA) do
        if name:upper():match(DIAL.SearchFilter) and vals.Rec >= state then
            LISTBOX.AddItem(name)
        end
    end
	local count = LISTBOX.GetCount()
	DIAL.SetText(ITEM_ID.LevelsCount, "Levels: " .. count)
    LISTBOX.SelectTopIndex()
    if count <= 0 then
		DIAL.SetIcon(ITEM_ID.GameIcon, "NONE")
		DIAL.SetIcon(ITEM_ID.LevelIcon, "NONE")
		DIAL.SetIcon(ITEM_ID.RecIcon, "NONE")
		DIAL.SetText(ITEM_ID.Status, "")
		DIAL.SetText(ITEM_ID.Date, "")
		DIAL.SetText(ITEM_ID.Author, "")
    end
end

DIAL.Main = function(ptr)

    ptr = ffi.cast("int", ptr)
    local iptr = ffi.cast("int*", ptr)
	local cham = _chameleon[0]

	if cham == chamStates.OnPostMessage and ptr == 0x114D then
		--mdl_exe._TimeThings(_nResult) -- not sure what it does
		if DIAL.Param() == ITEM_ID.ButtonPlay and DIAL.ChosenLevel ~= "" then
			SAVES = nil
			DIAL.ChosenLevel = getCustomPath()..DIAL.ChosenLevel..".WWD"
			snRes(ffi.cast("int", DIAL.ChosenLevel), 49)
			C.PostMessageA(nRes(1,1), 0x111, _message.LevelStart, 0)
		else
			mdl_exe.CSavePoint[0] = 0
		end
    end

	if cham == chamStates.CustomLevelsWindow then

		hdlg = iptr[4]

		C.ShowCursor(1)

		if iptr[5] == WM_INITDIALOG then
			mdl_exe.CSavePoint[0] = 0 -- reset the save point just in case
			if FileExists(GetClawPath() .. "\\CustomSaves.lua") then
                local file = assert(io.open(GetClawPath() .. "\\CustomSaves.lua", "r"))
                SAVES = file:read("*all")
                io.close(file)
            else
                SAVES = nil
            end
			ITEMS.CreateRecIcon(hdlg)
			ITEMS.CreateLevelCounter(hdlg)
            DIAL.SearchFilter = "." -- default search filter
			LISTBOX.Init()
			ITEMS.CreateRecCheckbox(hdlg)
			-- Singleplayer dialog has more elements than the multiplayer one:
			singleplayer = DIAL.IsSinglePlayer()
			if singleplayer then
				ITEMS.CreateLoad2Button(hdlg)
				ITEMS.CreateStatusText(hdlg)
				DIAL.SetText(ITEM_ID.ButtonLoad, "Load SP1")
			end
			C.SetFocus(hdlg)
		end

		if iptr[5] == WM_COMMAND then
            if iptr[6] == ITEM_ID.ButtonLoad then
				mdl_exe.CSavePoint[0] = 1
				iptr[6] = ITEM_ID.ButtonPlay
            end

            if iptr[6] == ITEM_ID.ButtonLoad2 then
				mdl_exe.CSavePoint[0] = 2
				iptr[6] = ITEM_ID.ButtonPlay
            end

            if iptr[6] == ITEM_ID.CheckBox then
                LISTBOX.Update()
            end

			if iptr[6] == ITEM_ID.ButtonPlay then
				DIAL.ChosenLevel = LISTBOX.GetCurrentSelection()
            end
            -- Get info based on selected level in list:
			if iptr[6] == 0x103FC then -- 0x10000 + ITEM_ID.ListBox
                if LISTBOX.GetCount() > 0 then -- if listbox is not empty
					DIAL.UpdateDescription()
				end
            end
			-- SearchBox change:
			if iptr[6] == 0x300029A then -- 0x3000000 + ITEM_ID.SeatchBox
				local text = ffi.new("char[64]")
				local len = DIAL.GetText(ITEM_ID.SearchBox, text)
				if len >= 1 then
					text = ffi.string(text, math.min(len, 63))
					DIAL.SearchFilter = EscapeMagicChars(text):upper()
				else
					DIAL.SearchFilter = "."
				end
				LISTBOX.Update()
			end
		end
	end
end

return DIAL
