local OBJS = {
    ObjectsList = {}, -- ID -> object
    ObjectsData = {}, -- object's address -> custom data table
    ObjectsNames = {}, -- object's address -> object name (ones from CreateObject)
    Methods = {} -- global functions
}

OBJS.GetLogicName = function(object)
	local name = ffi.string(object._Name)
	local addr = tonumber(ffi.cast("int", object))
	return name ~= "" and name or OBJS.ObjectsNames[addr] or "<unnamed>"
end

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
]]

ffi.metatype("ObjectA", {
    __index = function(self, key)
		-- object methods:
		if OBJS.Methods[key] then
			return OBJS.Methods[key]
		end
        -- get ObjectV field:
        local success, result = pcall(function()
            return self._v[key]
        end)
        if success then
            return result
        end
        -- get object's custom data:
        local data = OBJS.ObjectsData[tonumber(ffi.cast("int", self))]
        if data and data[key] ~= nil then
            return data[key]
        end
    end,
    __newindex = function(self, key, val)
        -- set ObjectV field:
        local success = pcall(function()
            return self._v[key]
        end)
        if success then
            self._v[key] = val
            return
        end
        -- set object's custom data:
        local data = OBJS.ObjectsData[tonumber(ffi.cast("int", self))]
        if data then
            data[key] = val
            return
        end
        error("ObjectA __newindex")
    end
})

return OBJS