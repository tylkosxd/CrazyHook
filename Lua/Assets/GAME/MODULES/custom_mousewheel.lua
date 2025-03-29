local MW = {
    Counter = 0,
    LastTime = 0
}

MW.GetMouseWheelEvent = function()
    return MW.Counter
end

MW.Main = function(ptr)
    if _chameleon[0] == chamStates.MouseWheel then
        MW.Counter = ffi.cast("int", ptr) > 0 and 1 or -1
        MW.LastTime = GetRealTime() + 30
    end
    if MW.Counter ~= 0 and GetRealTime() > MW.LastTime then
        MW.Counter = 0
    end
end

return MW