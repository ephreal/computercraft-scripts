local moods = require("moods")

local moodManager = {}
moodManager.__index = moodManager

function moodManager.new(moodContainer)
    self = {}
    setmetatable(self, moodManager)

    local currentMood
    local f = fs.open("/mood")

    if not f then
        currentMood = "happy"
    else
        currentMood = f.readAll()
    end
    f.close()

    self.currentMood = moods[currentMood]
    self.moodContainer = moodContainer
end

function moodManager:updateMood()
    moods.setMood(self.moodContainer, self.currentMood)
end

-- A simple FSM to manage the currentMood
function moodManager:fsm()
    
end


