function main(object)
	if object.State < 5 then object.State = object.State + 1
	else object:Destroy() end
end