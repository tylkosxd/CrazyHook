-- Flags types:
ffi.cdef[[
	typedef struct { int flags; } DrawFlags_t;
	typedef struct { int flags; } Flags_t;
	typedef struct { int flags; } PlaneFlags_t;
    typedef struct { int flags; } SpecialFlags_t;
    typedef struct { int flags; } InfosFlags_t;
	typedef struct { int flags; } CollisionFlags_t;
]]

local SetFlagsMetatype = function(name)
	ffi.metatype(name.."_t",
		{
			__newindex = function(self,k,v)
				local flags = assert(_G[name])
				local flag = assert(flags[k])
				assert(type(v) == "boolean")
				if v then
					self.flags = OR(self.flags, flag)
				else
					self.flags = AND(self.flags, NOT(flag))
				end
			end,
			__index = function(self,k)
				local flags = assert(_G[name])
				local flag = assert(flags[k])
				return AND(self.flags, flag) ~= 0
			end
		}
	)
end

SetFlagsMetatype("Flags")
SetFlagsMetatype("DrawFlags")
SetFlagsMetatype("CollisionFlags")
SetFlagsMetatype("SpecialFlags")
SetFlagsMetatype("PlaneFlags")
SetFlagsMetatype("InfosFlags")

-- Built-in logics (functions):
ffi.cdef"typedef int (*Logic)(struct ObjectA*);"

-- BYTE and PBYTE:
ffi.cdef[[
	typedef unsigned char BYTE;
	typedef BYTE* PBYTE;
]]

-- Rect and point:
ffi.cdef[[
	typedef struct Rect {
		int Left;
		int Top;
		int Right;
		int Bottom;
	} Rect;

    typedef struct Point {
		union {
			int x;
			int X;
		};
		union {
			int y;
			int Y;
		};
    } Point;
]]

-- Palette:
ffi.cdef[[
    typedef struct CColor {
        unsigned char Red;
        unsigned char Green;
        unsigned char Blue;
        unsigned char Alpha;
    } CColor;

    typedef struct CPalette {
        struct CColor Color[256];
    } CPalette;
]]

ffi.metatype("CPalette",
	{
		__index = function(self, key)
			if type(key) == "number" then
				if key >= 0 and key < 256 then
					return self.Color[key]
				end
				error("CPalette __index " .. key)
			end
			if _cpalette[key] then
				return _cpalette[key]
			end
		end,
		__newindex = function(self, key, val)
			if type(val) == "string" then
				local html = assert(val:match"(#%d%d%d%d%d%d)", "CPalette __index - could not match color to the html format")
				local red = tonumber(html:sub(2, 3), 16)
				local green = tonumber(html:sub(4, 5), 16)
				local blue = tonumber(html:sub(6, 7), 16)
				val = ffi.new("CColor", {red, green, blue})
				self.Color[key] = val
				return
			end
			if type(key) == "number" and key >= 0 and key < 256 then
				self.Color[key] = val
				return
			end
			error("CPalette __newindex " .. key .. " " .. tostring(val))
		end
	}
)

-- Graph type, contains image data and its settings:
ffi.cdef[[
    typedef struct GraphV {
        int _f_0;
        int _f_4;
        int _f_8;
        int* ImgData;
        int _f_10;
        int Flag;
        int Color;
        int* ColorTable;
        int _f_1C;
        int _f_20;
        int _f_24;
        int _f_28;
        int _f_2C;
        int _f_30;
        int _f_34;
        int _f_38;
        int _f_3C;
        int _f_40;
    } GraphV;

    typedef struct GraphA {
        void* const _vtable;
        int _field_4;
        int _field_8;
        int * const _Game_;
        int Width;
        int Height;
        int CenterX;
        int CenterY;
        int OffsetX;
        int OffsetY;
        int _field_28;
        int _field_2C;
        GraphV* _v;
    } GraphA;
]]

ffi.metatype("GraphA", 
    {
	    __index = function(self, key)
		    local ok, result = pcall(function()
				if self._v ~= nil then
					return self._v[key]
				end
		    end)
		    if ok then
		        return result
		    end
		    if self[key] then
		        return self[key]
		    end
	    end,
	    __newindex = function(self, key, val)
		    local ok = pcall(function()
				if self._v ~= nil then
					return self._v[key]
				end
		    end)
		    if ok then
				self._v[key] = val
		        return
		    end
		    if self[key] then
				self[key] = val
		        return
		    end
		    error("GraphA __newindex " .. _GetLogicName(self) .. " " .. key .. " " .. tostring(val))
	    end
    }
)

-- Object types:
ffi.cdef[[
	typedef struct ObjectV {
		const void *_vtable;
		int _field_4;
		int _field_8;
		int _field_C;
		Logic Logic;
		union {
			struct PData* _p;
			int* _d;
		};
		int* _userdata;
		int State;
		int TimeDelay;
		int FrameDelay;
		int UserFlags;
		int XMin;
		int XMax;
		int YMin;
		int YMax;
		int _field_3C;
		int _field_40;
		int XTweak;
		int YTweak;
		int _FullLogicCycle;
		int _FullLogicCycle2_;
		int _field_54;
		int _field_58;
		int _field_5C;
		int _field_60;
		int User[8];
		int _field_84;
		int _field_88;
		int _field_8C;
		int _field_90;
		int _field_94;
		int _field_98;
		int _field_9C;
		int _field_A0;
		int _field_A4;
		int _field_A8;
		int _field_AC;
		int _field_B0;
		int _field_B4;
		int Counter;
		int Speed;
		int _f_C0;
		int _f_C4;
		int Width;
		int Height;
		int _f_D0;
		int _f_D4;
		int _f_D8;
		int _f_DC;
		int _f_E0;
		int _f_E4;
		int _f_E8;
		int _f_EC;
		Rect UserRect1;
		Rect UserRect2;
		int _f_110;
		int _f_114;
		int _f_118;
		int _f_11C;
		int _f_120;
		int _f_124;
		int _f_128;
		int _f_12C;
		int _f_130;
		int _f_134;
		int _f_138;
		int _f_13C;
		int _f_140;
		int _f_144;
		int _f_148;
		int _f_14C;
		int _f_150;
		int _f_154;
		int _f_158;
		int _f_15C;
		int _f_160;
		int _f_164;
		const char* TSound;
	} ObjectV;

	typedef struct ObjectA {
		void * const _vtableA;
		const int ID;
		Flags_t Flags;
		int * const _Game_;
		int _field_10;
		int _field_14;
		int OSX;
		int OSY;
		Rect OnScreenBox;
		int OnScreenWidth;
		int OnScreenHeight;
		int OnScreen;
		int _f_3C;
		DrawFlags_t DrawFlags;
		int _field_44;
		int _field_48;
		int _field_4C;
		int _field_50;
		int _f_54;
		int _f_58;
		int X;
		int Y;
		Rect ClipRect;
		int Z;
		int _field_78;
		struct ObjectV* _v;
		int* _HitHandler;
		struct ObjectA* HitRef;
		int* _AttackHandler;
		struct ObjectA* AttRef;
		int* _BumpHandler;
		struct ObjectA* BumpRef;
		struct ObjectA* ObjectBelow;
		int _f_9C;
		int _f_A0;
		int _f_A4;
		int _f_A8;
		int AX;
		int AY;
		int _f_B4;
		int _field_B8;
		int _field_BC;
		int _field_C0;
		int _field_C4;
		int _field_C8;
		int _field_CC;
		int _field_D0;
		int _field_D4;
		int _field_D8;
		const char* _Name;
		struct ObjectA* GlitterPointer;
		int PhysicsType;
		union {
			int ObjectTypeFlags;
			CollisionFlags_t BumpFlags;
		};
		union {
			int HitTypeFlags;
			CollisionFlags_t HitFlags;
		};
		union {
			int AttackTypeFlags;
			CollisionFlags_t AttackFlags;
		};
		int _field_F4;
		int MoveResX;
		int MoveResY;
		int _field_100;
		int EditorX;
		int EditorY;
		int _EditorZ_;
		int _IsPlayer;
		int Score;
		int Points;
		int Powerup;
		int Damage;
		int Smarts;
		int Health;
		int Direction;
		int FacingDir;
		Rect MoveRect;
		Rect HitRect;
		Rect AttackRect;
		int SpeedX;
		int SpeedY;
		int _field_16C;
		int _field_170;
		int MoveClawX;
		int MoveClawY;
		int _field_17C;
		union {
			SpecialFlags_t SpecialFlags;
			int _field_180;
		};
		int _field_184;
		int _field_188;
		int _field_18C;
		int I;
		void* Image;
		GraphA* Graph;
		void* Sound;
		int _field_1A0;
		int EditorID;
		int IsGameplayObject;
		int _field_1AC;
		int _field_1B0;
		void* Animation;
		int _field_1B8;
		int _field_1BC;
		int _unkn_bool1;
		int _field_1C4;
		int _unkn_bool2;
		int _field_1CC;
		int _field_1D0;
		int _field_1D4;
		int _field_1D8;
		int _field_1DC;
		union {
			struct node* Childs;
			int* _field_1E0;
		};
	} ObjectA;
]]

ffi.metatype("ObjectA", 
    {
	    __index = function(self, key)
			-- get ObjectV field:
		    local ok, result = pcall(function()
		        return self._v[key]
		    end)
		    if ok then
		        return result
		    end
			-- get object's custom data:
		    local data = _objects_data[tonumber(ffi.cast("int", self))]
		    if data then
		        local result = data[key]
		        if result ~= nil then
			        return result
		        end
		    end
			-- object methods:
		    if _objectA[key] then
		        return _objectA[key]
			end
		end,
		__newindex = function(self, key, val)
			-- set ObjectV field:
			local ok = pcall(function()
				return self._v[key]
			end)
			if ok then
				self._v[key] = val
				return
			end
			-- set object's custom data:
			local data = _objects_data[tonumber(ffi.cast("int", self))]
			if data then
				data[key] = val
				return
			end
			error("ObjectA __newindex " .. _GetLogicName(self) .. " " .. key .. " " .. tostring(val))
		end
	}
)

-- Ambient sound type:
ffi.cdef[[
    typedef struct CAmbientSound {
        const void* _vtable;
        const void* _buffer;
        int mainVolume;
        int appSoundsManagerVolume;
        int volume;
        bool isPlaying;
        Rect rect;
        Rect rect2;
        int field_38;
        const void *_listNode;
    } CAmbientSound;
]]

-- Base level data:
ffi.cdef[[
	typedef struct LevelBasedData {
		int LevelNb;
		char SpringBoardAnimationIdle[32];
		char SpringBoardAnimationSpring[32];
		int DeathTileType;
		Rect SpringBoardDefRect;
		Rect TogglePegDefRect;
		Rect ElevatorDefRect;
		Rect CrumblingPegDefRect;
		Rect SteppingStoneDefRect;
		Rect BigElevatorDefRect;
		int BreakPlankWidth;
		int field_AC;
		int SplashY;
		int MPSkinnerPosX;
		int MPSkinnerPosY;
		int field_BC;
		int field_C0;
	} LevelBasedData;
]]

-- New PlayerData:
ffi.cdef[[
    typedef struct NewPDataType {
		int Direction;
		int Attack;
		int Throw;
		int Lift;
		int ProjectileUse;
		int _f_14;
		int Death;
		int Attack2;
		int Attack3;
		int LoadedFromSavePoint;
		int _f_28;
		int ClimbDir;
		int ActiveSecondWeapon;
		int _f_34;
		int _f_38;
		int AttackType;
		int FallHeight;
		int SpawnScore;
		int SpawnHealth;
		int SpawnPointX;
		int SpawnPointY;
		int AttackOffsetX;
		int AttackOffsetY;
		int JumpHeight;
		int JumpStartY;
		int JumpPeakY;
		int ClimbPeakY;
		int Attack4;
		int PistolAmmo;
		int MagicAmmo;
		int DynamiteAmmo;
		int Lives;
		int AttemptNb;
		int ConveyorBeltForce;
		int CollectedCoin;
        int CollectedGoldbar;
        int CollectedRing;
        int CollectedChalice;
        int CollectedCross;
        int CollectedScepter;
        int CollectedGecko;
        int CollectedCrown;
        int CollectedSkull;
        int _f_AC;
        int GameCollectedCoin;
        int GameCollectedGoldbar;
        int GameCollectedRing;
        int GameCollectedChalice;
        int GameCollectedCross;
        int GameCollectedScepter;
        int GameCollectedGecko;
        int GameCollectedCrown;
        int GameCollectedSkull;
        int _f_D4;
        Rect LiftRect;
        int AttackCount;
        int ScoreToExtraLife;
        int LiftTime;
        int ThrowTime;
        int _f_F8;
        int LookUpTime;
        int DynThrowTime;
        int DynThrowMinTime;
        int DynThrowMaxTime;
        int JumpTime;
        int LookDownTime;
        int RunningSpeedTime;
		int JumpPressTime;
		int _f_11C;
		int AFKTime;
		int _f_124;
		int _f_128;
		ObjectA* Lifted;
		ObjectA* CatnipGlitter;
	} NewPDataType;
]]

-- Old PlayerData (needs to stay for the backward compatibility):
ffi.cdef[[
    typedef struct PData {
	    int Dir;
	    int _unkn2;
	    int _unkn3;
	    int _unkn4;
	    int _unkn5;
	    int _unkn6;
	    int _unkn7;
	    int _unkn8;
	    int _unkn9;
	    int _unkn10;
	    int _unkn11;
	    int _unkn12;
	    int _unkn13;
	    int _unkn14;
	    int _unkn15;
	    int _unkn16;
	    int _unkn17;
	    int _unkn18;
	    int _unkn19;
	    int SpawnPointX;
	    int SpawnPointY;
	    int _unkn22;
	    int _unkn23;
	    int _unkn24;
	    int _unkn25;
	    int _unkn26;
	    int _unkn27;
	    int _unkn28;
	    int PistolAmmo;
	    int MagicAmmo;
	    int TNTAmmo;
	    int Lives;
	    int AttemptNb;
	    int _unkn34;
	    int _unkn35;
	    int _unkns[35];
	    int _unkn71;
	    int _unkn72;
	    int _unkn73;
	    int _unkn74;
	    int _unkn75;
	    int _unkn76;
	    int _CGlit;
    } PData;
]]

-- the metatype that links both old and new PData:
ffi.metatype("PData", 
	{
		__index = function(self, key)
			local good, result = pcall(function()
				return ffi.cast("NewPDataType*", self)[key]
			end)
			if good then
				return result
			end 
			local ok = pcall(function()
				return self[key]
			end)
			if ok then
				return self[key]
			end
		end,
		__newindex = function(self, key, val)
			local good = pcall(function()
				return ffi.cast("NewPDataType*", self)[key]
			end)
			if good then
				ffi.cast("NewPDataType*", self)[key] = val
				return
			end
			if self[key] then
				self[key] = val
				return
			end
			error("PData __newindex " .. key .. " " .. tostring(val))
		end
	}
)

-- Plane type:
ffi.cdef[[
    typedef struct CPlane {
        void* const _vtable;
        const int ID;
        PlaneFlags_t Flags;
        int* const _Game_;
        int _f_10;
        int _f_14;
        int _f_18;
        int _f_1C;
        int* Tiles;
        int* Rows;
        const int Width;
        const int Height;
        const int WidthPx;
        const int HeightPx;
        const int TileWidth;
        const int TileHeight;
        Rect ScreenA;
        Rect Screen;
        Rect DefTileRect;
        int ScreenAWidth;
        int ScreenAHeight;
        int ScreenACenterX;
        int ScreenACenterY;
        int Z;
        int ScreenCenterX;
        int ScreenCenterY;
        const int _f_8C;
        const int _f_90;
        int SpeedX;
        int SpeedY;
        int* _f_9C;
        void* Tileset;
        const int _f_A4;
        const int _f_A8;
        const int _f_AC;
        const int _f_B0;
        char Name[64];
        int _f_F4;
        int _f_F8;
        int _f_FC;
        int _f_100;
        int _f_104;
        int _f_108;
        int _f_10C;
        int _f_110;
        int _f_114;
        int _f_118;
        int _f_11C;
        int _f_120;
        int _f_124;
        int _f_128;
        int _f_12C;
        int _f_130;
        int _f_134;
        int _f_138;
        int _f_13C;
        int _f_140;
        int FillColor;
        int _f_148;
        int _f_14C;
        int _f_150;
        int _f_154;
        int _f_158;
        int _f_15C;
        int _f_160;
    } CPlane;
]]

ffi.metatype("CPlane", 
	{
		__index = function(self, key)
			-- plane methods:
			if _cplane[key] then
				return _cplane[key]
			end
			-- plane fields:
			return self[key]
		end,
		__newindex = function(self,key,val)
			if self[key] then
				self[key] = val
				return
			end
			error("CTileRange __newindex " .. key .. " " .. tostring(val))
		end
	}
)

-- TileLayer - variable length structure:
ffi.cdef[[
	typedef struct CTileLayer{
		CPlane* PRoot;
		int X;
		int Y;
		int Width;
		int Height;
		int ContentSize;
		int Content[?];
	} CTileLayer;
]]

ffi.metatype("CTileLayer", 
	{
		__index = function(self, key)
			if _tileLayer[key] then
				return _tileLayer[key]
			end
			return self[key]
		end,
		__newindex = function(self,key,val)
			if self[key] then
				self[key] = val
				return
			end
			error("CTileRange __newindex " .. key .. " " .. tostring(val))
		end
	}
)

-- Tiles attributes:
ffi.cdef[[
    typedef struct SingleTileA {
        const int Type;
        const int TileWidth;
        const int TileHeight;
        int Attribute;
        const int _unknown;
    } SingleTileA;
    
    typedef struct DoubleTileA {
        const int Type;
        const int TileWidth;
        const int TileHeight;
        int Attribute;
        int RectAttribute;
        Rect TileRect;
    } DoubleTileA;

    typedef struct MaskTileA {
        const int Type;
        const int TileWidth;
        const int TileHeight;
        const int Attribute;
        const int _unknown1;
        int* Mask;
        const int _unknown2;
        const int _unknown3;
        const int _unknown4;
    } MaskTileA;
]]

-- Claw controls:
ffi.cdef[[
    typedef struct CControlsMgr{
        void* const _f_0;
        int InputState1;
        int InputState2;
        int InputState3;
        struct {
            int Jump;
            int Attack;
            int Projectile;
            int ToggleProjectile;
            int Unused;
            int Lift;
            int Pistol;
            int Magic;
            int Dynamite;
            int Special;
        } Controller;
        struct {
            int Left;
            int Right;
            int Up;
            int Down;
            int Jump;
            int Attack;
            int Projectile;
            int ToggleProjectile;
            int Unused;
            int Lift;
            int Pistol;
            int Magic;
            int Dynamite;
            int Special;
        } Keyboard;
        int _f_70;
        void* const _vtable;
        void* const _f_78;
        int _f_7C;
        int _f_80;
        void* const _f_84;
        void* const _f_88;
        int _f_8C;
        int _f_90;
    } CControlsMgr;
]]

-- Doubly linked list's node:
ffi.cdef[[
    typedef struct node {
        struct node* next;
        struct node* prev;
        struct ObjectA* object;
    } node;
]]

-- Win32 Input structures:
ffi.cdef[[
	typedef struct MouseInput {
		int dx;
		int dy;
		unsigned int mouseData;
		unsigned int dwFlags;
		unsigned int time;
		void* dwExtraInfo;
	} MouseInput;
	
	typedef struct KeybInput {
		short wVk;
		short wScan;
		unsigned int dwFlags;
		unsigned int time;
		void* dwExtraInfo;
	} KeybInput;

	typedef struct Input {
		unsigned int iType;
		union {
			MouseInput mi;
			KeybInput ki;
		};
	} Input;
]]

-- Various C functions:
ffi.cdef[[
	bool LineTo(int hdc, int x, int y);
	bool Rectangle(int hdc, Rect);
	bool Ellipse(int hdc, Rect);
	bool Polygon(int hdc, Point*, int);
	bool Arc(int, int, int, int, int, int, int, int, int);
	int CombineRgn(void*, void*, void*, int);
	void* CreateEllipticRgn(int, int, int, int);
	void* GetStockObject(int);
	bool MoveToEx(int, int, int, Point*);
	void* CreateSolidBrush(int);
	void* CreateHatchBrush(int, int);
	bool SelectObject(int, void*);
	bool DeleteObject(void*);
	int SetBkMode(int, int);
	void* CreatePen(int, int, int);
	bool SetTextColor(int, int);
	bool TextOutA(int, int, int, const char*, int);
	int DrawTextA(int, const char*, int, Rect*, unsigned int);
	int FillRect(int, Rect*, void*);
    void* CreateFontA(int, int, int, int, int, int, int, int, int, int, int, int, int, const char*);
    void* CreateRectRgn(int, int, int, int);
    bool FillRgn(int hdc, void*, void*);
	void* CreatePolygonRgn(Point*, int, int);
	bool PtInRegion(void*, int, int);
	bool RectInRegion(void*, Rect*);
  
	int GetActiveWindow();
    int GetDlgItem(int, int);
	int SetDlgItemTextA(int, int, const char*);
	int SetDlgItemInt(int, int, int, int);
	bool EndDialog(int, int);
	int SetFocus(int);
	int LoadIconA(int,const char*);
    bool GetWindowRect(int, Rect*);
    bool SetWindowPos(int, int, int, int, int, int, unsigned int);
    int CreateWindowExA(int, const char*, const char*, int, int, int, int, int, int, int, int, int);
    bool DestroyWindow(int);
    long GetWindowLongA(int, int);
    int LoadImageA(int, const char*, unsigned int, int, int, unsigned int);
    int ShowWindow(int, int);
    int EnableWindow(int, bool);
	int DialogBoxParamA(int, const char*, int, int, int);
	unsigned int GetDlgItemTextA(int, int, int, int);
	bool UpdateWindow(int);
	int MessageBoxA(void *w, const char *txt, const char *cap, int type);
	int MapWindowPoints(int, int, Rect*, int);
	int GetParent(int);
	bool GetClientRect(int, Rect*);

    bool GetCursorPos(Point*);
	int ShowCursor(int);
	bool GetKeyboardState(unsigned char*);
	short GetAsyncKeyState(int);
	unsigned int SendInput(unsigned int, Input*, int);

	int PostMessageA(int, int, int, int);
	int SendMessageA(int, int, int, int);

	const char* GetCommandLineA();
	int* LoadLibraryA(const char*);
	int* GetProcAddress(int*, const char*);
]]
