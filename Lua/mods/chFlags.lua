local _flags = {
	Flags = {
		NoHit           = 1,
		AlwaysActive    = 2,
		Safe            = 4,
		AutoHitDamage   = 8,
		OnElevator      = 0x10,
		Destroy         = 0x10000
	},
	DrawFlags = {
		NoDraw          = 1,
		Mirror          = 2,
		Invert          = 4,
		Flash           = 8
	},
    InfosFlags = {
        Objects         = 1,
        Multi           = 2,
        Pos             = 4,
        FPS             = 0x10,
        Timing          = 0x40,
        Watch           = 0x80,
        DebugRects      = 0x1000,
        DebugRectsPlus  = 0x2000,
		DebugText		= 0x4000,
        LiveClock       = 0x8000 
    },
	PlaneFlags = {
		Main = 1,
		NoDraw = 2,
        XWrap = 4,
        YWrap = 8
	},
    SpecialFlags = {
        StopElevator    = 1,
        FireShot        = 0x40000,
        IceShot         = 0x80000,
        LightningShot   = 0x100000
    }
}

_flags.SetFlagsMetatype = function(name)
	ffi.metatype(name.."_t",
		{
			__newindex = function(self,k,v)
				local flags = assert(_G[name])
				local flag = assert(flags[k])
				assert(type(v)=="boolean")
				if v then
					self.flags = OR(self.flags ,flag)
				else
					self.flags = AND(self.flags,NOT(flag))
				end
			end,
			__index = function(self,k)
				local flags = assert(_G[name])
				local flag = assert(flags[k])
				return AND(self.flags,flag)~=0
			end
		}
	)
end

return _flags
