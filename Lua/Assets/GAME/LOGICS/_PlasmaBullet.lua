function main(self)
    if self.State == 0 then
        FireBullet(self)
        self.Damage = 25
        self.ObjectTypeFlags = 0x2000000
        self.SpecialFlags.FireShot = true
        self:SetImage"GAME_PROJECTILES_PLASMASWORD"
    else
        FireBullet(self)
    end
end
