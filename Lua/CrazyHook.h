
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

typedef struct node {
    struct node* next;
    struct node* prev;
    struct ObjectA* object;
} node;

typedef int (*Logic)(struct ObjectA*);

typedef struct { int flags; } DrawFlags_t;

typedef struct { int flags; } Flags_t;

typedef struct { int flags; } SpecialFlags_t;

typedef struct { int flags; } CollisionFlags_t;

typedef struct { int flags; } InfosFlags_t;

typedef struct { int flags; } PlaneFlags_t;

/* CGraphV struct is bound to the CGraphA with LuaJIT's metatype. Any field of CGraphV is accessible directly from CGraphA, e.g.:
instead of "graph._v.Color" in Lua (in C: "(CGraphA*)graph -> _v -> Color"), one can simple use "graph.Color". */
typedef struct CGraphV {
    int _f_0;
    int _f_4;
    int _f_8;
    void* ImgData;
    int _f_10;
    int Flag;
    int Color;
    int* ColorTable;
} CGraphV;

typedef struct CGraphA {
    void* const _vtable;
    int ID;
    int _field_8;
    int* const _Game_;
    int Width;
    int Height;
    int CenterX;
    int CenterY;
    int OffsetX;
    int OffsetY;
    int _field_28;
    int _field_2C;
    CGraphV* _v;
} CGraphA;

typedef struct CImage {
    void* const _vtable;
    const int ID;
    int _f_8;
    void* const _Game_;
    void* _f_10;
    CGraphA** Images;
    const int NumImages;
    const int NumImages;
    int _f_20;
    const char Name[64];
    const int FirstImageNum;
    const int LastImageNum;
} CImage;


/* PData and CPlayerData structs are bound to each other with LuaJIT's metatype. You can think of it as a C union, althought a simple
union wouldn't handle such bounding. PData must stay for the backwards-compatibility.*/
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

typedef struct CPlayerData {
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
    struct ObjectA* Lifted;
    struct ObjectA* CatnipGlitter;
} CPlayerData;

/* ObjectV struct is bound to the ObjectA with LuaJIT's metatype. Any field of ObjectV is accessible directly from ObjectA, e.g.:
instead of "object._v.State" in Lua (in C: "(ObjectA*)object -> _v -> State"), one can simple use "object.State". */
typedef struct ObjectV {
    const void *_vtable;
    int _field_4;
    int _field_8;
    int _field_C;
    Logic Logic;
    union {
        struct PData* _p; // Claw only
        int* _d; // objects other than Claw
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
    void* const _vtableA;
    const int ID;
    Flags_t Flags;
    int* const _Game_;
    int _field_10;
    int _field_14;
    int OSX;
    int OSY;
    Rect OnScreenBox;
    int OnScreenWidth;
    int OnScreenHeight;
    int OnScreen;
    union {
        int _f_3C;
        void* const _Game_9;
    };
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
    CImage* Image;
    CGraphA* Graph;
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
        node* Childs;
        int* _field_1E0;
    };
} ObjectA;

typedef struct CColor {
    unsigned char Red;
    unsigned char Green;
    unsigned char Blue;
    unsigned char Alpha;
} CColor;

typedef struct CPalette {
    struct CColor Color[256];
} CPalette;

typedef struct CPlane {
    void* const _vtable;
    const int ID;
    PlaneFlags_t Flags;
    int* const _Game_;
    const float RelativeX;
    const float RelativeY;
    float MovementX;
    float MovementY;
    int* Tiles;
    const int* Rows;
    const int Width;
    const int Height;
    const int WidthPx;
    const int HeightPx;
    const int TileWidth;
    const int TileHeight;
    const Rect ScreenA;
    const Rect Screen;
    const Rect DefTileRect;
    const int ScreenAWidth;
    const int ScreenAHeight;
    const int ScreenACenterX;
    const int ScreenACenterY;
    int Z;
    const int ScreenCenterX;
    const int ScreenCenterY;
    const int Log2TileWidth;
    const int Log2TileHeight;
    int SpeedX;
    int SpeedY;
    int* _f_9C;
    CImage** Tileset;
    const int _f_A4;
    const int _f_A8;
    const int _f_AC;
    void* const _f_B0;
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
} CPlane;

/*
typedef struct CTileLayer{
    struct CPlane* PRoot;
    int X;
    int Y;
    const int Width;
    const int Height;
    const int ContentSize;
    int Content[?]; // LuaJIT's variable length structure
} CTileLayer;
*/

typedef struct CSingleTileA {
    const int Type;
    const int Width;
    const int Height;
    int Attribute;
    const int _unknown;
} CSingleTileA;

typedef struct CDoubleTileA {
    const int Type;
    const int Width;
    const int Height;
    int Attribute;
    int RectAttribute;
    Rect TileRect;
} CDoubleTileA;

typedef struct CMaskTileA {
    const int Type;
    const int Width;
    const int Height;
    const int Attribute;
    const int _unknown;
    int* Mask;
} CMaskTileA;

typedef struct CWwdHeaderSmall {
    int offset[4];
    const char name[64];
    const char author[64];
    const char date[64];
} CWwdHeaderSmall;

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
} LevelBasedData;

typedef struct CBasePickups {
    int AmmoBigBag;
    int Ammo;
    int AmmoBag;
    int Catnip1;
    int Catnip2;
    int Food;
    int BigPotion;
    int SmallPotion;
    int MediumPotion;
    int MagicGlow;
    int MagicStar;
    int MagicClaw;
} CBasePickups;

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