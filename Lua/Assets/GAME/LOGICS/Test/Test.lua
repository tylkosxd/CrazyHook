-- When the local "test" variable in CrazyHook.lua is set to true, you can test anything on-the-go by modifing this file, without closing the game.
-- Press F5 to execute the script.

local function findBestColor(color, pal)
    local diffs = {}
    -- square of euclidean distance:
    for i = 0, 255 do
        diffs[i] = (color.Red - pal[i].Red)^2 + (color.Green - pal[i].Green)^2 + (color.Blue - pal[i].Blue)^2
    end
    return table.key(diffs, math.min(unpack(diffs)))
end

local function setRetroPal()
    local retroPal = LoadPaletteFile(GetClawPath() .. "\\Assets\\GAME\\MODULES\\custom_palettes\\retro.txt")
    if retroPal then
        local currentPal = GetCurrentPalette()
        local newPal = ffi.new"CPalette"
        for color = 0, 255 do
            local toset = tostring(retroPal[findBestColor(currentPal[color], retroPal)])
            newPal[color] = toset
        end
        newPal:Set()
    end
end

function test(self, t)
    MultClawClimbSpeed(2)
end