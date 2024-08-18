_exe = {
	_DropMultipleTreasure   = ffi.cast("int (*)(int, int, int, int, int)", 0x40FAA0),
	_ClawJump               = ffi.cast("void (*)(ObjectA*, int)", 0x41FC40),
	_KillClaw               = ffi.cast("void (*__cdecl)(ObjectA*, ObjectV*, PData*, int)", 0x418BD0),
	_ClawGivePowerup        = ffi.cast("int (*)(int, int)", 0x420EE0),
	_BlockClaw              = ffi.cast("void (*)()", 0x421450),
	_PlaySound              = ffi.cast("int (*__thiscall)(void*, int, int, int, int)", 0x421BB0),
	_RegisterCheat			= ffi.cast("void (*__thiscall)(int, const char*, int, int)", 0x423E40),
	_JumpToLevel            = ffi.cast("int (*__thiscall)(int*, int)", 0x429890),
	_ChangeResolution       = ffi.cast("int (*__thiscall)(int*, int, int)",0x429D80),
	_TimeThings             = ffi.cast("int* (*__thiscall)(int**)",0x42C3C0),
	_TextOut                = ffi.cast("int (*__thiscall)(int, const char*)", 0x42C780),
	_LoadBaseLevDefaults    = ffi.cast("int (*__cdecl)(int)", 0x454340),
	_GetSoundA              = ffi.cast("int* (*__thiscall)(int, const char*)", 0x45A4E0), -- (Game(10), name)
	_BnW                    = ffi.cast("signed int (*)(int)", 0x463C90),
	_CreateGoodie           = ffi.cast("int (*)(int, int, int, int, int)", 0x4751A0),
    _SendMultiMessage       = ffi.cast("int(*__thiscall)(int, int*, int)", 0x479200), -- (nRes(11), args, 1),
	_Quake                  = ffi.cast("void (*__cdecl)(int)", 0x48A000), -- (time ms)
	_ClawSound              = ffi.cast("ObjectA* (*)(const char*, int)", 0x48FB00),
    _EnemySound             = ffi.cast("int (*__cdecl)(ObjectA*, int*, int)", 0x4900C0),
    _GetBgImage             = ffi.cast("int (*__thiscall)(int, const char*, int, int, int, int)",0x492950),
	_DumpScreen             = ffi.cast("int (*__cdecl)(int, int*)", 0x499530),
    _Random                 = ffi.cast("int(*)()", 0x4A595B),
    _GetClawPath            = ffi.cast("int (*__cdecl)(int, int)", 0x4AF5E4),
	_StopSound              = ffi.cast("void (*__thiscall)(int)", 0x4B34D0), -- (_GetSoundA(Game(10), name))
	_MapMusicFile           = ffi.cast("int (*__thiscall)(int, void*, int, const char*)",0x4B4DC0),
	_GetMusic               = ffi.cast("int* (*__thiscall)(int, const char*)", 0x4B4E80), -- (nRes(20), name)
	_SetMusic               = ffi.cast("int (*__thiscall)(int, const char*, int)", 0x4B4ED0),
	_GetMusicState          = ffi.cast("int (*__thiscall)(int*)", 0x4B55B0), -- (_GetMusic(name))
	_SetMusicSpeed          = ffi.cast("int (*__thiscall)(int*, int, int)", 0x4B55E0),
	_GetValueFromRegister   = ffi.cast("int (*__thiscall)(int, const char*, int)",0x4B5950),
    _GetMusicAddr           = ffi.cast("void *(*__thiscall)(void*)", 0x4B5B30),
	_LoadSingleFile         = ffi.cast("void* (*__thiscall)(void*, const char*, unsigned int)",0x4B5FC0),
	_IncludeAssets          = ffi.cast("int (*__thiscall)(int, const char*, int)",0x4B6D50),
	_LoadFolder             = ffi.cast("void* (*__thiscall)(int, const char*)",0x4B79D0),
	_MakeScreenToFile       = ffi.cast("int (*__thiscall)(int, const char*, int, int, int)", 0x4BAA40),
    _SetPalette             = ffi.cast("void (*__thiscall)(int, int)", 0x4BC5B0),
	_SetImageAndI           = ffi.cast("int (*__thiscall)(ObjectA*, const char*, int)",0x4C6D60),
	_SetImage               = ffi.cast("int (*__thiscall)(ObjectA*, const char*)", 0x4C6DD0),
	_SetAnimation           = ffi.cast("int (*__thiscall)(ObjectA*, const char*, int)", 0x4C6E40),
    _SetSound               = ffi.cast("int (*__thiscall)(ObjectA*, const char*)", 0x4C6EA0),
	_RegisterHitHandler     = ffi.cast("int (*__thiscall)(ObjectA*, const char*)", 0x4C7730),
	_RegisterAttackHandler  = ffi.cast("int (*__thiscall)(ObjectA*, const char*)", 0x4C7810),
	_AnimationStep          = ffi.cast("int (*__thiscall)(int, int)", 0x4C8550),
	_CreateObject           = ffi.cast("ObjectA* (*__thiscall)(int, int, int, int, int, const char*, unsigned int)", 0x4C9480),
	_MapSoundsFolder        = ffi.cast("void (*__thiscall)(int, void*, const char*, const char*)",0x4CAE80),
	_Physics                = ffi.cast("int (*__thiscall)(int, ObjectA*, int, int, int)", 0x4CC7E0),
	_AlignToGround          = ffi.cast("int (*__thiscall)(int, ObjectA*, int)", 0x4CE420),
	_IsVisible              = ffi.cast("int (*__thiscall)(int, int, int, int, int)", 0x4CE620),
	_MapAnisFolder          = ffi.cast("void (*__thiscall)(int, void*, const char*, const char*)",0x4CECE0),
	_SetImgFlag             = ffi.cast("void (*__thiscall)(void*, unsigned int)", 0x4CF4C0),
	_SetImgColor            = ffi.cast("void (*__thiscall)(void*, unsigned int)", 0x4CF520),
	_SetImgCLT              = ffi.cast("void (*__thiscall)(void*, int)", 0x4CF560),
	_MapImagesFolder        = ffi.cast("void (*__thiscall)(int, void*, const char*, const char*)",0x4D0D30),
	_LoadAsset              = ffi.cast("int (*__thiscall)(int this, const char*, void**)", 0x4FC6B4),
	_GetSound               = ffi.cast("int* (*__thiscall)(int, const char*)", 0x4FC6D6), -- (Game(10)+16, name)
	_KeyPressed             = ffi.cast("int (*)(int)",ffi.cast("int*",0x50C438)[0]),
    --
    CSavePoint              = ffi.cast("int*", 0x424859),
	Hwnd                    = ffi.cast("int*", 0x4B8B91),
	Chameleon               = ffi.cast("int*",0x50BFB5),
	SkipLogoMovies          = ffi.cast("int*",0x50BFBB),
	SkipTitleScreen         = ffi.cast("int*",0x50BFBF),
	TestExit                = ffi.cast("int*",0x50BFD3),
	IntroSound              = ffi.cast("int*",0x52356C),
    EnableCurses            = ffi.cast("int*", 0x523570),
    DamageFactor            = ffi.cast("float*", 0x524580),
    HealthFactor            = ffi.cast("float*", 0x524584),
    SmartsFactor            = ffi.cast("float*", 0x52458C),
	TeleportX               = ffi.cast("int*", 0x5282C8),
	TeleportY               = ffi.cast("int*", 0x5282CC),
	CameraX                 = ffi.cast("int*", 0x52A314),
	CameraY                 = ffi.cast("int*", 0x52A318),
	SoundVolume             = ffi.cast("int*", 0x530990),
	CurrentBoss             = ffi.cast("ObjectA**",0x532864),
    AquatisData             = ffi.cast("int*", 0x5326FC),
    StartingPoints          = ffi.cast("int*", 0x532C3C),
    MultiMessage            = ffi.cast("int*", 0x532D1C),
	PowerupTime             = ffi.cast("int*",0x532D30),
	CurrentPowerup          = ffi.cast("int*",0x532D34),
    LastHitTime             = ffi.cast("int*", 0x532D48),
    GameLoadedFromSP        = ffi.cast("int*", 0x534D94),
	PlayAreaRect            = ffi.cast("Rect*", 0x535840),
	nResult                 = ffi.cast("int**", 0x535910),
	Inputs                  = ffi.cast("CControlsMgr**", 0x535918),
	MsCount                 = ffi.cast("const int*", 0x535928),
	Cheats                  = ffi.cast("int*", 0x53592C),
	NoEffects               = ffi.cast("int*",0x535964),
	InfosDisplay            = ffi.cast("InfosFlags_t*", 0x535998),
    LevelBasedData          = {
		[0] = ffi.cast("LevelBasedData*",0x535FE8), 
		[1] = ffi.cast("LevelBasedData*",0x5360A8)
	},
	mResult                 = ffi.cast("int**", 0x5362A0),
	Claw                    = ffi.cast("ObjectA**", 0x5365D4),
    Pickups                 = ffi.cast("int*", 0x536768),
	TreasuresCountTable     = ffi.cast("int*", 0x536B3C),
    ClawExclamation         = ffi.cast("ObjectA**", 0x53B0DC),
    EnemyExclamation        = ffi.cast("ObjectA**", 0x53B0E4),
	DisablePowerupMusic     = ffi.cast("int*", 0x53B0F8),
    MultiStats              = ffi.cast("ObjectA**", 0x53B134),
    AverageCLT              = ffi.cast("int**", 0x5AAFBC),
    FrameTime               = ffi.cast("int*", 0x5AAFD8),
    RealTime                = ffi.cast("int*", 0x5AAFDC),
    ObjectActions           = ffi.cast("int**", 0x5ACD40),
    ObjectMinAction         = ffi.cast("int*", 0x5ACD50),
    ObjectMaxAction         = ffi.cast("int*", 0x5ACD3C)
}

return _exe
