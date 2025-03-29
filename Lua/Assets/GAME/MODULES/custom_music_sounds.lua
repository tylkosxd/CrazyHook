--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- [[ Music and Sound module ]] -----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
-- Functions related to music and sounds.

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

local MUS = {}

MUS.GetMusicState = function(name)
    name = type(name) == "string" and string.upper(name) or ""
    local tracks = GetMusicTracks()
    if table.icontain(tracks, name) then
        local ptr = mdl_exe._GetMusic(nRes(20), name)
        return mdl_exe._GetMusicState(ptr) ~= 0
    else
        return false
    end
end

MUS.StopMusic = function(name)
	name = string.upper(name)
    local music_plays = MUS.GetMusicState(name)
	if music_plays then
	    local ptr = mdl_exe._GetMusic(nRes(20), name)
        mdl_exe._StopMusic(ptr)
    end
end

MUS.SetMusicSpeed = function(name, speed)
    name = string.upper(name)
    local music_plays = MUS.GetMusicState(name)
    if music_plays then
        mdl_exe._SetMusicSpeed(nRes(20,7), name, speed < 0 and 0 or math.floor(speed*1000))
    end
end

MUS.SetMusicVolume = function(vol)
	vol = vol > 100 and 100 or vol < 0 and 0 or vol
	mdl_exe._SetMusicVolume(vol)
end

MUS.PlaySound = function(name, volume, stereo, pitch, loop)
	local sound = mdl_exe._GetSoundA(Game(10), name)
	if not volume or volume == 1 then
		volume = mdl_exe.SoundVolume[0]
	elseif volume >= 3 then
		volume = 3*mdl_exe.SoundVolume[0]
	elseif volume <= 0 then
		volume = 0
	else
		volume = volume*mdl_exe.SoundVolume[0]
	end
	mdl_exe._PlaySound(sound, volume, stereo or 0, pitch or 0, loop or 0)
end

MUS.ReplaceSound = function(name1, name2)
    local sound1 = mdl_exe._GetSound(Game(10)+16, name1)
	local sound2 = mdl_exe._GetSound(Game(10)+16, name2)
	sound1[0] = sound2[0]
end

MUS.SwapSound = function(name1, name2)
    local sound1 = mdl_exe._GetSound(Game(10)+16, name1)
	local sound2 = mdl_exe._GetSound(Game(10)+16, name2)
    local temp = sound1[0]
	sound1[0] = sound2[0]
    sound2[0] = temp
end

MUS.RemoveSound = function(name)
    local sound1 = mdl_exe._GetSound(Game(10)+16, name)
	local sound2 = mdl_exe._GetSound(Game(10)+16, "GAME_NULL")
	sound1[0] = sound2[0]
end

MUS.StopSound = function(name)
	local sound = mdl_exe._GetSoundA(Game(10), name)
    if sound[4] then
		mdl_exe._StopSound(sound)
	end
end

MUS.EnemySound = function(object, name)
    local sound = mdl_exe._GetSoundA(Game(10), name)
    mdl_exe._EnemySound(object, sound, 0)
end

return MUS