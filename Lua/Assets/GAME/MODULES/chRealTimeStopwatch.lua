local function _format_ptime(t)
    if #tostring(t) == 1 then
        return "0" .. t
    else
        return tostring(t)
    end
end

local function _format_time(t)
    local _msPart = string.sub(t, -3, -2)
    local _secPartFull = tonumber(string.sub(t, 1, -4)) or 0
    local _secPart = _format_ptime(_secPartFull%60)
    local _minPartFull = math.floor(_secPartFull/60)
    local _minPart = _format_ptime(_minPartFull%60)
    local _hourPart = math.floor(_minPartFull/60)
    return _hourPart .. ":" .. _minPart .. ":" .. _secPart .. "." .. _msPart
end

RTA_Stopwatch = function(ptr)
    if _chameleon[0] == chamStates.LoadingStart then
        _lClockStart = nil
        _lClockStop = nil
    elseif _chameleon[0] == chamStates.LoadingEnd then
        if not _lClockStart then
            _lClockStart = mdl_exe.RealTime[0] + 1500
        end
    elseif _chameleon[0] == chamStates.Gameplay then
        if InfosDisplay[0].LiveClock == true then
		    if ptr then 
			    hdc = tonumber(ffi.cast("int",ptr)) 
		    end
		    ffi.C.SetTextColor(hdc, 0xFFFFFF)
            if _lClockStart then
                _lTime = tostring(mdl_exe.RealTime[0] - _lClockStart)
                if _lTime then
                    if not _lClockStop then 
		                _lClock = _format_time(_lTime)
                    else
                        _lClock = _format_time(_lClockStop)
                    end
                end
            end
			local screen = ffi.cast("CPlane*", Game(9,23)).Screen
            local screenx, screeny = screen.Right+1, screen.Bottom+1;
            if _lClock then
                local rect = ffi.new("Rect",{screenx-8-#_lClock*10, screeny-28, screenx-8, screeny-4})
		        local lprect = ffi.new("Rect[1]", rect)
		        ffi.C.DrawTextA(hdc, _lClock ,#_lClock, lprect, 2)
            end
        end
    end
end

return RTA_Stopwatch
