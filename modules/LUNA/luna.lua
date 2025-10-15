local MoodManager = require("moodManager")
local UI = require("ui")

local Luna = {}
Luna.__index = Luna

function Luna.new()
    self = {}
    setmetatable(self, Luna)

    self.mood = MoodManager.new(UI.getMoodDisplay())

end
