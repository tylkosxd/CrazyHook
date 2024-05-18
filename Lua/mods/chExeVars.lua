_exev = {
    LevelBasedData      = {},
	nResult             = ffi.cast("int**", 0x535910),
	mResult             = ffi.cast("int**", 0x5362A0),
	Hwnd                = ffi.cast("int*", 0x4B8B91),
	Claw                = ffi.cast("ObjectA**", 0x5365D4),
	MsCount             = ffi.cast("const int*", 0x535928),
	CurrentBoss         = ffi.cast("ObjectA**",0x532864),
	CameraX             = ffi.cast("int*", 0x52A314),
	CameraY             = ffi.cast("int*", 0x52A318),
	TeleportX           = ffi.cast("int*", 0x5282C8),
	TeleportY           = ffi.cast("int*", 0x5282CC),
	NoEffects           = ffi.cast("int*",0x535964),
	CurrentPowerup      = ffi.cast("int*",0x532D34),
	PowerupTime         = ffi.cast("int*",0x532D30),
	TreasuresCountTable = ffi.cast("int*", 0x536B3C),
	Chameleon           = ffi.cast("int*",0x50BFB5),
	SkipLogoMovies      = ffi.cast("int*",0x50BFBB),
	SkipTitleScreen     = ffi.cast("int*",0x50BFBF),
	TestExit            = ffi.cast("int*",0x50BFD3),
	IntroSound          = ffi.cast("int*",0x52356C),
	InfosDisplay        = ffi.cast("InfosFlags_t*", 0x535998),
	Inputs              = ffi.cast("int**", 0x535918),
	PowerupMusicToggle  = ffi.cast("int*", 0x53B0F8),
	BigCheat            = ffi.cast("int*", 0x53592C),
	PlayAreaRect        = ffi.cast("Rect*", 0x535840),
	SoundVolume         = ffi.cast("int*", 0x530990),
    DamageFactor        = ffi.cast("float*", 0x524580),
    HealthFactor        = ffi.cast("float*", 0x524584),
    SmartsFactor        = ffi.cast("float*", 0x52458C),
    LastHitTime         = ffi.cast("int*", 0x532D48),
    Curses              = ffi.cast("int*", 0x523570)
}

_exev.LevelBasedData[0] = ffi.cast("LevelBasedData*",0x535FE8)
_exev.LevelBasedData[1] = ffi.cast("LevelBasedData*",0x5360A8)

_exev.nRes = function (na,nb,nc,nd,ne,nf)
	if not na then 
		return _exev.nResult[0]
	elseif not nb then 
		return _exev.nResult[0][na]
	elseif not nc then 
		return ffi.cast("int*",_exev.nResult[0][na])[nb]
	elseif not nd then 
		return ffi.cast("int**",_exev.nResult[0][na])[nb][nc]
	elseif not ne then 
		return ffi.cast("int***",_exev.nResult[0][na])[nb][nc][nd]
	elseif not nf then
		return ffi.cast("int****",_exev.nResult[0][na])[nb][nc][nd][ne] 
	else
		return ffi.cast("int*****",_exev.nResult[0][na])[nb][nc][nd][ne][nf]
	end
end

_exev.snRes = function (arg,na,nb,nc,nd,ne,nf)
	if not na then 
		_exev.nResult[0] = arg
	elseif not nb then 
		_exev.nResult[0][na] = arg
	elseif not nc then 
		ffi.cast("int*",_exev.nResult[0][na])[nb] = arg
	elseif not nd then 
		ffi.cast("int**",_exev.nResult[0][na])[nb][nc] = arg
	elseif not ne then 
		ffi.cast("int***",_exev.nResult[0][na])[nb][nc][nd] = arg
	elseif not nf then
		ffi.cast("int****",_exev.nResult[0][na])[nb][nc][nd][ne] = arg
	else
		ffi.cast("int*****",_exev.nResult[0][na])[nb][nc][nd][ne][nf] = arg
	end
end

_exev.Game = function (nb,nc,nd,ne,nf)
	return _exev.nRes(12,nb,nc,nd,ne,nf)
end

return _exev
