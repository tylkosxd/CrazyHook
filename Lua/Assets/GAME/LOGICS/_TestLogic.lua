
local switch = {
    [0] = function(self)
        ActivateDebugText()
        snRes(1,18,74)
        self.testNumber = 1
        self.Flags.AlwaysActive = true
        self.checker = CreateObject{Image = "GAME_SOUNDICON", MoveRect = {-10, -10, 10, 10}, Logic = "DoNothing", Z=9000, PhysicsType = 8}
        if not self.path then
            self.path = "Assets\\GAME\\LOGICS\\Test\\Test.lua"
        end
        self.State = 1
    end,
    [1] = function(self)
        self.State = KeyPressed"F5" and 2 or 1
    end,
    [2] = function(self)
        local testNb = self.testNumber
        local test, err = loadfile(self.path)
        assert(test, err)
        local temp = setmetatable({}, {__index = _G})
        setfenv(test, temp)
        test()
        temp["test"](self, testNb)
        self.testNumber = testNb + 1
        self.State = 3
    end,
    [3] = function(self)
        self.State = not KeyPressed"F5" and 1 or 3
    end
}

function main(self)
    switch[self.State](self)
    debug_text[1] = "Test number: " .. self.testNumber
end
