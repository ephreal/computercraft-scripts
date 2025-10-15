local moods = require("moods")

-- Tweak to change how quickly LUNA cycles through moods
local MAX_MOOD_RANGE = 10

local MoodManager = {}
MoodManager.__index = MoodManager

function MoodManager.new(moodContainer)
    local self = {}
    setmetatable(self, MoodManager)

    local currentMood
    local f = fs.open("/mood", "r")

    if f then
        currentMood = moods.get(f:readAll(), "happy")
        f.close()
    else
        currentMood = moods.happy
    end

    self.moodContainer = moodContainer
    self:setMood(currentMood)

    -- Positivity can go below 0 to -max_positivity
    self.positivity = 0
    self.intensity = 0
    self.energy = 7
    self.maxPositivity = MAX_MOOD_RANGE
    self.maxIntensity = MAX_MOOD_RANGE
    self.maxEnergy = MAX_MOOD_RANGE

    -- These control the thresholds for high, medium, and low
    -- positivity, intensity, and energy.
    -- Think of positivity as how "good" the interaction is,
    -- intensity as how "strong" the interaction is, and
    -- energy as how "awake" LUNA is.
    self.highPositivity = self.maxPositivity * 0.8
    self.midPositivity = self.maxPositivity * 0.6
    self.lowPositivity = self.maxPositivity * 0.1

    self.highIntensity = self.maxIntensity * 0.75
    self.midIntensity = self.maxIntensity * 0.4
    self.lowIntensity = self.maxIntensity * 0.2

    self.highEnergy = self.maxEnergy * 0.6
    self.midEnergy = self.maxEnergy * 0.4
    self.lowEnergy = self.maxEnergy * 0.1

    return self
end

function MoodManager:setMood(newMood)
    if newMood ~= self.currentMood then
        self.currentMood = newMood
        moods.setMood(self.moodContainer, self.currentMood)
    end
end

-- A simple FSM to manage the currentMood
function MoodManager:shiftMood(positivity, intensity)
    -- positivity and intensity come from the input parser
    self.positivity = math.min(self.maxPositivity, self.positivity + positivity)
    self.positivity = math.max(-self.maxPositivity, self.positivity)

    self.intensity = math.min(self.maxIntensity, self.intensity + intensity)
    self.intensity = math.max(0, self.intensity)

    -- LUNA will wake up a bit when you talk to her.
    if self.energy < 1 then
        self.energy = self.energy + .5
    end

    -- Luna will randomly gain or lose some energy based on the intensity
    -- of the interaction
    local energyShift = (math.random(-1, 1) * intensity) * .25
    self.energy = self.energy + energyShift
    self.energy = math.max(0, self.energy)
    self.energy = math.min(self.maxEnergy, self.energy)

    self:moodFsm()
end


function MoodManager:moodFsm()

    if self.energy <= self.lowEnergy then
        self:veryLowEnergyFsm()
    elseif self.energy <= self.midEnergy then
        self:lowEnergyFsm()
    elseif self.energy <= self.highEnergy then
        self:midEnergyFsm()
    elseif self.energy > self.highEnergy then
        self:highEnergyFsm()
    end
end

function MoodManager:veryLowEnergyFsm()
    -- Called when LUNAs energy hits or drops below lowEnergy
    -- Valid low energy moods:
    -- Bored
    -- Chill
    -- Frustrated
    -- Tired
    -- Sleeping

    -- LUNA will sleep if energy, and intensity are low.
    if self.energy <= self.lowEnergy
       and self.intensity <= self.lowIntensity
       and math.abs(self.positivity) <= self.lowPositivity then
        self:setMood(moods.sleeping)
    else
        -- Varies depending on the positivity and intensity
        -- Valid positivity moods
        -- Bored
        -- Chill
        -- Tired
        if self.positivity > 0 then
            if self.intensity > self.midIntensity then
                self:setMood(moods.chill)
            elseif self.intensity > 0 then
                self:setMood(moods.tired)
            else
                self:setMood(moods.bored)
            end
        -- Valid negative moods
        -- Frustrated
        -- Tired
        else
            if self.intensity > self.midIntensity then
                self:setMood(moods.frustrated)
            else
                self:setMood(moods.tired)
            end
        end
    end
end

function MoodManager:lowEnergyFsm()
    -- Called when LUNAs energy hits or drops below midEnergy
    if self.intensity <= self.midIntensity then
        if self.positivity <= self.highPositivity * -1 then
            self:setMood(moods.frustrated)
        elseif self.positivity <= self.midPositivity * -1 then
            self:setMood(moods.sad)
        elseif self.positivity <= self.lowPositivity * -1 then
            self:setMood(moods.confused)
        elseif self.positivity < 0 then
            self:setMood(moods.curious)
        elseif self.positivity <= self.lowPositivity then
            self:setMood(moods.bored)
        elseif self.positivity <= self.midPositivity then
            self:setMood(moods.chill)
        elseif self.positivity <= self.highPositivity then
            self:setMood(moods.happy)
        elseif self.positivity > self.highPositivity then
            self:setMood(moods.happy)
        else
            self:setMood(moods.smarmy)
        end
    elseif self.intensity > self.midIntensity then
        if self.positivity <= self.highPositivity * -1 then
            self:setMood(moods.angry)
        elseif self.positivity <= self.midPositivity * -1 then
            self:setMood(moods.frustrated)
        elseif self.positivity <= self.lowPositivity * -1 then
            self:setMood(moods.sad)
        elseif self.positivity < 0 then
            self:setMood(moods.confused)
        elseif self.positivity <= self.lowPositivity then
            self:setMood(moods.chill)
        elseif self.positivity <= self.midPositivity then
            self:setMood(moods.happy)
        elseif self.positivity <= self.highPositivity then
            self:setMood(moods.smarmy)
        elseif self.positivity > self.highPositivity then
            self:setMood(moods.scientific)
        else
            self:setMood(moods.chill)
        end
    end
end

function MoodManager:midEnergyFsm()
    -- Called when LUNAs energy hits or drops below highEnergy
    if self.intensity <= self.midIntensity then
        if self.positivity <= self.highPositivity * -1 then
            self:setMood(moods.angry)
        elseif self.positivity <= self.midPositivity * -1 then
            self:setMood(moods.confused)
        elseif self.positivity <= self.lowPositivity * -1 then
            self:setMood(moods.frustrated)
        elseif self.positivity < 0 then
            self:setMood(moods.curious)
        elseif self.positivity <= self.lowPositivity then
            self:setMood(moods.bored)
        elseif self.positivity <= self.midPositivity then
            self:setMood(moods.bored)
        elseif self.positivity <= self.highPositivity then
            self:setMood(moods.chill)
        elseif self.positivity > self.highPositivity then
            self:setMood(moods.scientific)
        end
    elseif self.intensity > self.midIntensity then
        if self.positivity <= self.highPositivity * -1 then
            self:setMood(moods.shocked)
        elseif self.positivity <= self.midPositivity * -1 then
            self:setMood(moods.angry)
        elseif self.positivity <= self.lowPositivity * -1 then
            self:setMood(moods.frustrated)
        elseif self.positivity < 0 then
            self:setMood(moods.confused)
        elseif self.positivity <= self.lowPositivity then
            self:setMood(moods.chill)
        elseif self.positivity <= self.midPositivity then
            self:setMood(moods.happy)
        elseif self.positivity <= self.highPositivity then
            self:setMood(moods.excited)
        elseif self.positivity > self.highPositivity then
            self:setMood(moods.affectionate)
        end
    end
end

function MoodManager:highEnergyFsm()
    -- Called when LUNAs energy goes above highEnergy
    if self.intensity <= self.midIntensity then
        if self.positivity <= self.highPositivity * -1 then
            self:setMood(moods.frustrated)
        elseif self.positivity <= self.midPositivity * -1 then
            self:setMood(moods.confused)
        elseif self.positivity <= self.lowPositivity * -1 then
            self:setMood(moods.sad)
        elseif self.positivity < 0 then
            self:setMood(moods.curious)
        elseif self.positivity <= self.lowPositivity then
            self:setMood(moods.happy)
        elseif self.positivity <= self.midPositivity then
            self:setMood(moods.playful)
        elseif self.positivity <= self.highPositivity then
            self:setMood(moods.smarmy)
        elseif self.positivity > self.highPositivity then
            self:setMood(moods.scientific)
        end
    elseif self.intensity > self.midIntensity then
        if self.positivity <= self.highPositivity * -1 then
            self:setMood(moods.shocked)
        elseif self.positivity <= self.midPositivity * -1 then
            self:setMood(moods.angry)
        elseif self.positivity <= self.lowPositivity * -1 then
            self:setMood(moods.sad)
        elseif self.positivity < 0 then
            self:setMood(moods.confused)
        elseif self.positivity <= self.lowPositivity then
            self:setMood(moods.chill)
        elseif self.positivity <= self.midPositivity then
            self:setMood(moods.playful)
        elseif self.positivity <= self.highPositivity then
            self:setMood(moods.excited)
        elseif self.positivity > self.highPositivity then
            self:setMood(moods.affectionate)
        end
    end
end


function MoodManager:moodDecay()
    -- Handles a slow transition from higher energy states
    -- to low energy states (ie: sleeping or bored)
end

return MoodManager
