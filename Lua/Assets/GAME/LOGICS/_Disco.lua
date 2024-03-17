function main(object)
	if not object.Flags.Destroy then
		object.Flags.AlwaysActive,object.X,object.Y = true,GetClaw().X,GetClaw().Y
		local troll = CreateObject {x=object.X, y=object.Y, z=1000, logic="CustomLogic", name="Disco_sub"}
		troll:SetImage("CLAW")
		troll:SetFrame(GetClaw().I)
		troll.DrawFlags = GetClaw().DrawFlags
	end
end