-- To make your own plugin create the text file with the extension ".lua" in this folder.

-- This file is a blueprint.

-- Create a table that will hold the plugin's functions:
local PLUGIN = {}

-- Function with the name "menu" will work in the menu:
PLUGIN.menu = function()
	-- Caveat: any object created in the menu must be created with flags=0
end

-- Function with the name "map" works in other cases. Notice that it takes a single argument (ptr).
-- This function is called by the Chameleon, a single universal hook, that has been "implanted" in various stages of the game.
-- Chameleon has its state _chameleon[0], which is different in every stage:
PLUGIN.map = function(ptr)

	local cham = _chameleon[0]

	if cham == chamStates.LoadingStart then
		-- This is true at the moment you choose a level to play. It is also a good place to register a cheat code.
	end
	
	if cham == chamStates.LoadingAssets then
		-- This is true at the moment the game loads the assets for the level (sounds, images, anis and logics).
	end
	
	if cham == chamStates.LoadingObjects then
		-- This is true when the objects placed in WWD file are being created.
		-- It's an iterator over those object. To get the object's address do this: 
        local addr = tonumber(ffi.cast("int", ptr))
		-- To get the pointer to the object do this:
        local object = ffi.cast("ObjectA*", addr)
	end
	
	if cham == chamStates.LoadingEnd then
		-- This is true when the level is fully loaded and ready to start.
	end
	
	if cham == chamStates.OnPostMessage then
		-- This is true when the message to the game has been sent.
		-- To get the message ID do this:
		local id = tonumber(ffi.cast("int", ptr))
		-- To see most of the available IDs check the _message table (enumeration) in Constants module.
	end
	
	if cham == chamStates.Gameplay then
		-- This is true in level gameplay (when the player can move).
		-- This is called in a loop and you can get the Device Context to draw on the screen with WinGDI functions:
		local hdc = tonumber(ffi.cast("int", ptr))
		-- Those C functions can be called with ffi.C. The list of available functions can be found in chCdecl module (directory Assets\GAME\MODULES\).
		-- To use other functions they must be defined first using ffi.cdef.
	end
	
end

-- Return the table at the end. The plugin won't work if you don't do this.
return PLUGIN