function main(object)
	if object.State>0 and object.State<4 then object.Y = object.Y + object.State end
	if object.State > 4 then object.DrawFlags.flags = DrawFlags.NoDraw object.State = object.State-1
	elseif object.State > 0 then object.State = object.State-1 object.DrawFlags.flags = 0 end
end