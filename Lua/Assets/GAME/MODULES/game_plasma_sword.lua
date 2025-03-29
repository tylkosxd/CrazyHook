--[[ This module handles the Plasma sword powerup.
Plasma sword works not only for MPPEJTI code, but also by executing ClawGivePowerup(Powerup.PlasmaSword) and when Claw picks up
the object with logic 'CustomLogic' and name '_PlasmaSword.', which is a global logic (see in Assets/GAME/LOGICS/_PlasmaSword.lua)]]

local PLASMA = {Toggle = 0, CanShoot = true}

PLASMA.Activate = function()
    -- Changing the animation, sound and imageset of the fire bullet's explosion:
    PrivateCopyCast("GAME_PLASDEATH", 0x5261A0)
    PrivateCopyCast("GAME_PLASSWORDEXPLOSION", 0x52610C)
    PrivateCopyCast("GAME_EXPLOS_PLASMA", 0x526124, true)
    -- Plasma-burn enemies when plasma is active (instead of fire):
    PrivateCast(Powerup.PlasmaSword, "int*", 0x44EE11)
    PLASMA.Toggle = 1
end

PLASMA.Disable = function()
    PrivateCopyCast("GAME_FIREDEATH", 0x5261A0)
    PrivateCopyCast("GAME_FIRESWORDEXPLOSION", 0x52610C)
    PrivateCopyCast("GAME_EXPLOS_FIRE", 0x526124, true)
    ffi.cast("char*", 0x526124)[16] = 0
    ffi.cast("char*", 0x526124)[17] = 0
    ffi.cast("int*", 0x44EE11)[0] = Powerup.FireSword
    PLASMA.Toggle = 0
end

PLASMA.Active = function()
    if PLASMA.Toggle == 0 then
        PLASMA.Activate()
    end
    if GetClawAttackType("sword") then
        PLASMA.Shoot()
        PLASMA.CanShoot = false
    else
        PLASMA.CanShoot = true
    end
end

--[[ There is a code in the executable, that disables punches/kick, when Claw has an elemental sword powerup. Plasma sword hasn't
been deleted from there.]]
PLASMA.Shoot = function()
    if PLASMA.CanShoot then
        local speed = PData().Dir == 0 and -700 or 700 -- default speed of all magic bullets
        local px = PData().Dir == 0 and GetClaw().X - PData().AttackOffsetX or GetClaw().X + PData().AttackOffsetX
        local py = GetClaw().Y + PData().AttackOffsetY
        local projectile = CreateObject{x=px, y=py, z=GetClaw().Z+1, Logic="FireBullet", SpeedX = speed, Damage = 25}
        if projectile ~= nil then
            projectile.DrawFlags.Mirror = PData().Dir ~= 0
            projectile.SpecialFlags.FireShot = true
            projectile.BumpFlags.MagicBullet = true
            projectile:SetImage"GAME_PROJECTILES_PLASMASWORD"
        end
        PlaySound"CLAW_PLASMASWORD"
    end
end

PLASMA.Main = function()
    if _CurrentPowerup[0] == Powerup.PlasmaSword then
        PLASMA.Active()
    elseif PLASMA.Toggle == 1 then
        PLASMA.Disable()
    end
end

return PLASMA