--[[ Adding new items to the custom level dialog. And a table of all items with their IDs.
The reason for calculating positions and sizes relative to other items is to ensure they'll look the same on every OS.
I blame Windows.]]

local C = ffi.C

local function GetItem(hdlg, item)
	return C.GetDlgItem(hdlg, item)
end

local ITEMS = {}

ITEMS.Items = {
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
    TextSearch      = 0xFFFF
}

ITEMS.SetDefaultFont = function(hdlg, item)
    C.SendMessageA(GetItem(hdlg, item), 0x30, C.SendMessageA(GetItem(hdlg, ITEMS.Items.Author), 0x31, 0, 0), 0)
end

ITEMS.GetDlgItemSize = function(hdlg, item)
    local ptrItemRect = ffi.new("Rect[1]")
    local ptrDlgRect = ffi.new("Rect[1]")
    C.GetWindowRect(GetItem(hdlg, item), ptrItemRect)
    C.GetWindowRect(hdlg, ptrDlgRect)
	local itemRect, dlgRect = ptrItemRect[0], ptrDlgRect[0]
    local spx = itemRect.Left - dlgRect.Left - 3
	local spy = itemRect.Top - dlgRect.Top - 3
    local w = math.abs(itemRect.Right - itemRect.Left)
	local h = math.abs(itemRect.Bottom - itemRect.Top)
    return ffi.new("Rect", {spx, spy, w, h})
end

ITEMS.CreateLoad2Button = function(hdlg)
	local playButtonRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.ButtonPlay)
	local loadButtonRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.ButtonLoad)
	local x = 2*loadButtonRect.Left - playButtonRect.Left
	local y = playButtonRect.Top
	local w = playButtonRect.Right
	local h = playButtonRect.Bottom
	C.CreateWindowExA(4, "BUTTON", "Load SP2", 0x58010000, x, y, w, h, hdlg, ITEMS.Items.ButtonLoad2, 0, 0)
	ITEMS.SetDefaultFont(hdlg, ITEMS.Items.ButtonLoad2)
end

ITEMS.CreateStatusText = function(hdlg)
	local dateRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.Date)
	local authorRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.Author)
	local x = dateRect.Left
	local y = 2*authorRect.Top - dateRect.Top
	local w = dateRect.Right
	local h = dateRect.Bottom
	C.CreateWindowExA(4, "STATIC", "Status: Not Played", 0x5002C200, x, y, w, h, hdlg, ITEMS.Items.Status, 0, 0)
	ITEMS.SetDefaultFont(hdlg, ITEMS.Items.Status)
end

ITEMS.CreateLevelCounter = function(hdlg)
	local dateRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.Date)
	local listboxRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.ListBox)
	local h = dateRect.Bottom
	local x = listboxRect.Left + listboxRect.Right - 60
	local y = listboxRect.Top - 5 - h
	C.CreateWindowExA(4, "STATIC", "Levels: 0", 0x5002C200, x, y, 65, h, hdlg, ITEMS.Items.LevelsCount, 0, 0)
	ITEMS.SetDefaultFont(hdlg, ITEMS.Items.LevelsCount)
end

ITEMS.CreateRecCheckbox = function(hdlg)
	local dateRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.Date)
	local listboxRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.ListBox)
	local w = listboxRect.Right - 70
	local h = dateRect.Bottom
	local x = listboxRect.Left
	local y = listboxRect.Top - 5 - dateRect.Bottom
	C.CreateWindowExA(4, "BUTTON", "Showing all levels", 0x50010006, x, y, w, h, hdlg, ITEMS.Items.CheckBox, 0, 0)
	ITEMS.SetDefaultFont(hdlg, ITEMS.Items.CheckBox)
end

ITEMS.CreateRecIcon = function(hdlg)
	local iconRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.GameIcon)
	local infoboxRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.InfoBox)
	local dateRect = ITEMS.GetDlgItemSize(hdlg, ITEMS.Items.Date)
	local x = infoboxRect.Right - iconRect.Left - 12
	local y = iconRect.Top + dateRect.Bottom
	local w, h = iconRect.Right, iconRect.Bottom
	C.CreateWindowExA(4, "STATIC", "", 0x50000843, x, y, w, h, hdlg, ITEMS.Items.RecIcon, 0, 0)
end

return ITEMS