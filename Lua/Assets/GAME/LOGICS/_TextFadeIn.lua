function main(object)
	if object.State>0 and object.State%6==1 then PlaySound("GAME_MRF", true) end
	if object.State==1 and object.Last then PlaySound("GAME_SDPT2", true) end
	if object.State > 2 then object.DrawFlags.flags = DrawFlags.NoDraw object.State = object.State-1
	elseif object.State > 0 then object.DrawFlags.flags = DrawFlags.Mirror object.State = object.State-1
	else object.DrawFlags.flags = 0 end
end