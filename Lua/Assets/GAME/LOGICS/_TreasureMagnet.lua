function _GetDist(obj)
    return math.sqrt(math.abs(GetClaw().X - obj.X)^2 + math.abs(GetClaw().Y - obj.Y)^2)
end

function _AttractGold(obj)
    local claw = GetClaw()
    local dMax = 240
    local limit = 200
    local dMaxSq = dMax*dMax
    local magnetF = 600000
    if obj.ObjectTypeFlags == 0x40000 then
        local d = _GetDist(obj)
        if d < limit then
            if obj.Logic == TreasurePowerup or obj.Logic == GlitterlessPowerup then
                local dx = (GetClaw().X - obj.X)/d
                local dy = (GetClaw().Y - obj.Y)/d
                obj.X, obj.Y = math.ceil(obj.X + magnetF*dx/dMaxSq), math.ceil(obj.Y + magnetF*dy/dMaxSq)
                if tonumber(ffi.cast("int", obj.GlitterPointer)) ~= 0 then
                    obj.GlitterPointer.X, obj.GlitterPointer.Y = obj.X, obj.Y
                end
                if obj.State > 5 then
                    obj.DrawFlags.NoDraw = true
                end
            end
            if obj.Logic == BouncingGoodie then
                obj.PhysicsType = 1
            end
        end
    end
end


function main(self)


        if self.State == 0 then
            self.Flags.AlwaysActive = true
            self.DrawFlags.NoDraw = true
            self.State = 1000
        end

        if self.State == 1000 then
            self.State = 1001
        elseif self.State == 1001 then
            self.State = 1000
        end

        if self.State == 2000 then
            self.State = 2001
        end

        if self.State == 2001 then       
            LoopThroughObjects(_AttractGold)
        end

        if self.State == 3000 then
            self.State = 1000
        end
end
