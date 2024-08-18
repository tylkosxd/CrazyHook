GameType = {
	SinglePlayer 	= 3,
	MultiPlayer 	= 4
}

TreasureType = {
	Coin 		= 0,
	Goldbar 	= 1,
	Ring 		= 2,
	Chalice 	= 3,
	Cross 		= 4,
	Scepter 	= 5,
	Gecko 		= 6,
	Crown 		= 7,
	Skull 		= 8
}

Powerup = {
	EndOfLevel       = 0x26AD,
	Warp             = 0x26AE,
	AniRope          = 0x26AF,
	TNTAmmo          = 0x26B0,
	AmmoCurse        = 0x26B1,
	MagicCurse       = 0x26B2,
	HealthCurse      = 0x26B3,
	LifeCurse        = 0x26B4,
	TreasureCurse    = 0x26B5,
	FreezeCurse      = 0x26B6,
	Ghost            = 0x26B7,
	FireSword        = 0x26B8,
	LighteningSword  = 0x26B9, -- old typo, needs to stay
	LightningSword   = 0x26B9,
	IceSword         = 0x26BA,
	PlasmaSword      = 0x26BB,
	Catnip           = 0x26BC,
	Vader            = 0x26BD,
	ExtraLife        = 0x26BE,
	SirenProjectile  = 0x26BF,
	Custom 			 = 0x29A
}

-- This one is outdated, use CollisionFlags instead:
ObjectType = {
	Generic		= 1,
	Player		= 2,
	Enemy		= 4,
	PowerUp		= 8,
	Shot		= 0x10,
	PShot		= 0x20,
	EShot		= 0x40,
	Special		= 0x80,
	User1		= 0x100,
	User2		= 0x200
}

DeathType = {
	Spikes 	= 0,
	Goo 	= 1
}

TileAttribute = {
	Clear 	= 0, 
	Solid 	= 1, 
	Ground 	= 2, 
	Climb 	= 3,  
	Death 	= 4, 
	Mask 	= 6
}

TileType = {
	Single 	= 0x51414C,
	Double 	= 0x51418C,
	Mask 	= 0x5141CC
}

ImageFlag = {
	NoDraw 		= 0,
	Normal 		= 1, 
	Ghost 		= 2, 
	Shadow 		= 3,
	ColorFill 	= 5, 
	Glitch 		= 6,
	Chameleon 	= 6,
	Blob 		= 7
}

InputFlags = { 
	Jump                = 1,
	Attack              = 2,
	Projectile          = 4,
	ToggleProjectile    = 8,
	Unused				= 0x10,
	Lift                = 0x20,
	Pistol              = 0x40,
	Magic               = 0x80,
	Dynamite            = 0x100,
	Special             = 0x200,
	Left                = 0x1000000,
	Right               = 0x2000000,
	Up                  = 0x4000000,
	Down                = 0x8000000
}

Flags = {
	NoHit           = 1,
	AlwaysActive    = 2,
	Safe            = 4,
	AutoHitDamage   = 8,
	OnElevator      = 0x10,
	Destroy         = 0x10000,
	Interactable	= 0x40000
}

DrawFlags = {
	NoDraw          = 1,
	Mirror          = 2,
	Invert          = 4,
	Flash           = 8
}

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
	LiveClock       = 0x8000,
	HealthBars      = 0x10000
}

PlaneFlags = {
	Main 	= 1,
	NoDraw 	= 2,
	XWrap 	= 4,
	YWrap 	= 8
}

SpecialFlags = {
	StopElevator    = 1,
	StartElevator   = 2,
	OneWayElevator  = 0x100,
	TriggerElevator = 0x1000,
	FireShot        = 0x40000,
	IceShot         = 0x80000,
	LightningShot   = 0x100000
}

CollisionFlags = {
	Generic             = 1,
	Player              = 2,
	Enemy               = 4,
	Unknown1			= 8,
	ThrownObject        = 0x10,
	PistolBullet        = 0x20,
	EnemyBullet         = 0x40,
	Platform            = 0x80,
	Special				= 0x100,
	Curse               = 0x200,
	Unknown2			= 0x400,
	Checkpoint          = 0x800,
	JumpSwitch          = 0x1000,
	Unknown3			= 0x2000,
	Unknown4			= 0x4000,
	Unknown5			= 0x8000,
	Health              = 0x10000,
	Unknown6			= 0x20000,
	Treasure            = 0x40000,
	Unknown7			= 0x80000,
	MagicAmmo           = 0x100000,
	Unknown8			= 0x200000,
	Unknown9			= 0x400000,
	PistolAmmo          = 0x800000,
	ArchingProjectile   = 0x1000000,
	MagicProjectile     = 0x2000000,
	Sound               = 0x4000000,
}

ClawStates = {
	Jump 		= 4,
	MoveRight 	= 8,
	MoveLeft 	= 9,
	Stand 		= 24,
	Fall 		= 25,
	Crouch 		= 26,
	Climb 		= 27,
	Hit 		= 31,
	Lift 		= 5000,
	Throw 		= 5001,
	Land 		= 5002,
	LookUp 		= 5003,
	DeathFall 	= 5004,
	Death 		= 5005,
	OnEdge 		= 5006,
	Swing 		= 5007,
	Bearhug 	= 5008,
	Freeze 		= 5009
}

chamStates = {
	LoadingAssets 		= 0,
	LoadingObjects 		= 1,
	LoadingStart 		= 2,
	LoadingEnd 			= 3,
	OnPostMessage 		= 4,
	Gameplay 			= 5,
	CustomLevels 		= 6,
	CustomLevelsWindow 	= 7
}

InterfaceLogics = {
	ScoreFrame = 0x493E90, 
	WeaponFrame = 0x494550, 
	HealthFrame = 0x494220, 
	LivesFrame = 0x494880, 
	TimerFrame = 0x494B20, 
	ScoreRibbon = 0x42F840
}

AttackString = {
	"none", 
	"stand_sword_stab", 
	"none", 
	"stand_straight_punch", 
	"stand_hook_punch", 
	"stand_pistol_shot", 
	"stand_magic_claw", 
	"crouch_sword_stab", 
	"air_sword_stab", 
	"air_pistol_shot", 
	"air_magic_claw", 
	"none", 
	"stand_dynamite_throw", 
	"stand_front_kick", 
	"crouch_pistol_shot", 
	"crouch_magic_claw", 
	"crouch_dynamite_throw", 
	"none",
	"air_dynamite_throw"
} -- an array actually...

VKey = {
	LEFT_MOUSE 		= 0x01,
	RIGHT_MOUSE 	= 0x02,
	MIDDLE_MOUSE 	= 0x04,
	BACKSPACE 		= 0x08,
	TAB 			= 0x09,
	ENTER 			= 0x0D,
	SHIFT 			= 0x10,
	CONTROL 		= 0x11,
	ALT 			= 0x12,
	PAUSE 			= 0x13,
	CAPS_LOCK		= 0x14,
	ESCAPE 			= 0x1B,
	SPACE 			= 0x20,
	PAGE_UP 		= 0x21,
	PAGE_DOWN 		= 0x22,
	END 			= 0x23,
	HOME 			= 0x24,
	LEFT_ARROW 		= 0x25,
	UP_ARROW 		= 0x26,
	RIGHT_ARROW 	= 0x27,
	DOWN_ARROW 		= 0x28,
	PRINT_SCREEN 	= 0x2C,
	INSERT 			= 0x2D,
	DELETE 			= 0x2E,
	-- yes, the numerics aren't here
	A 		= 0x41,
	B 		= 0x42,
	C 		= 0x43,
	D 		= 0x44,
	E 		= 0x45,
	F 		= 0x46,
	G 		= 0x47,
	H 		= 0x48,
	I 		= 0x49,
	J 		= 0x4A,
	K 		= 0x4B,
	L 		= 0x4C,
	M 		= 0x4D,
	N 		= 0x4E,
	O 		= 0x4F,
	P 		= 0x50,
	Q 		= 0x51,
	R 		= 0x52,
	S 		= 0x53,
	T 		= 0x54,
	U 		= 0x55,
	V 		= 0x56,
	W 		= 0x57,
	X 		= 0x58,
	Y 		= 0x59,
	Z 		= 0x5A,
	NUM0 	= 0x60,
	NUM1 	= 0x61,
	NUM2 	= 0x62,
	NUM3 	= 0x63,
	NUM4 	= 0x64,
	NUM5 	= 0x65,
	NUM6 	= 0x66,
	NUM7 	= 0x67,
	NUM8 	= 0x68,
	NUM9 	= 0x69,     
	F1 		= 0x70,
	F2 		= 0x71,
	F3 		= 0x72,
	F4 		= 0x73,
	F5 		= 0x74,
	F6 		= 0x75,
	F7 		= 0x76,
	F8 		= 0x77,
	F9 		= 0x78,
	F10 	= 0x79,
	F11 	= 0x7A,
	F12 	= 0x7B
}

_message = {
	CustomLevelStart 		= 0x8005,
	ExitGame 				= 0x8008,		
	LevelEnd 				= 0x800E,
	PreviousLevel 			= 0x800F,
	IncreasePlayArea 		= 0x801B,
	DecreasePlayArea 		= 0x801C,
	Credits 				= 0x8021,
	ExitLevel				= 0x8023,
	Multiplayer 			= 0x8025,
	HelpScreen 				= 0x8035,
	BackToGame 				= 0x8036,
	UploadScores 			= 0x8039,
	ClawDeath 				= 0x803A,
	OpenCustomLevelWindow 	= 0x8042,
	Teleport 				= 0x805C,
	EditMacros				= 0x8059,
	ClawSuicide 			= 0x8063,
	Booty 					= 0x807C,
	LoadGame 				= 0x807E,
	NewGame 				= 0x807F,
	InGameMenu 				= 0x8080,
	OpenWindow 				= 0x8090,
	-- Cheats:
	MPSCULLY			= 0x800E,
	MPMOULDER 			= 0x800F,
	MPKFA				= 0x8043,
	MPAPPLE 			= 0x8044,
	MPLOADED 			= 0x8045,
	MPGANDOLF 			= 0x8046,
	MPBUNZ 				= 0x8047,
	MPMOONGOODIES 		= 0x8049,
	MPJORDAN 			= 0x804A,
	MPFPS 				= 0x804B,
	MPPOS 				= 0x804C,
	MPBOUNCECOUNT 		= 0x804D,
	MPNOINFO 			= 0x804E,
	MPSUPERTHROW 		= 0x804F,
	MPFREAK 			= 0x805B,
	MPTOPLESS 			= 0x8064,
	MPMIDLESS 			= 0x8065,
	MPBOTTOMLESS 		= 0x8066,
	MPWIMPY 			= 0x806A,
	MPBLASTER 			= 0x806C,
	MPSTOPWATCH 		= 0x806E,
	MPPLAYALLDAY 		= 0x8071,
	MPARMOR 			= 0x8072,
	MPJAZZY 			= 0x8076,   
	MPINCVID 			= 0x8077, 
	MPDECVID 			= 0x8078,
	MPDEFVID 			= 0x8079,
	MPGOBLE 			= 0x807A,
	MPMONOLITH 			= 0x8086,
	MPDEVHEADS 			= 0x8087,
	MPSPOOKY 			= 0x8088,
	MPSHADOW 			= 0x8089,
	MPHAUNTED 			= 0x808A,
	MPCULTIST 			= 0x808B,
	MPCASPER 			= 0x808D,
	MPVADER 			= 0x808E,
	MPPENGUIN 			= 0x8091,
	MPHOTSTUFF 			= 0x8092,
	MPFRANKLIN 			= 0x8093,
	MPSKINNER 			= 0x80AA,
	MPGLOOMY 			= 0x80AD,
	MPNOISE 			= 0x80AE,
	MPMAESTRO 			= 0x80AF,
	MPLANGSAM 			= 0x80B0,
	MPNORMALMUSIC 		= 0x80B1,
	MPLONGRANGE 		= 0x80B2,
	MPBOUNCECOUNTER 	= 0x80B3,
	MPWILDWACKY 		= 0x80B4,
	MPEASYMODE 			= 0x80B5,
	MPTWINTURBO 		= 0x80B6,
	-- Jump to level cheats:
	MPCHEESESAUCE 		= 0x809C,
	MPEXACTLY 			= 0x809D,
	MPRACEROHBOY 		= 0x809E,
	MPBUDDYWHAT 		= 0x809F,
	MPMUGGER 			= 0x80A0,
	MPGOOFCYCLE 		= 0x80A1,
	MPROTARYPOWER 		= 0x80A2,
	MPSHIBSHANK 		= 0x80A3,
	MPWHYZEDF 			= 0x80A4,
	MPSUPERHAWK 		= 0x80A5,
	MPJOBNUMBER 		= 0x80A6,
	MPLISTENANDLEARN 	= 0x80A7,
	MPYEAHRIGHT 		= 0x80A8,
	MPCLAWTEAMTULEZ 	= 0x80A9
}
