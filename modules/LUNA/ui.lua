local basalt = require("basalt")
local moods = require("moods")
local MoodManager = require("moodManager")
local logo = require("logo")
local Parser = require("parser")
local parser = Parser.new()
local strings = require("cc.strings")

local MAIN_BACKGROUND    = colors.black
local MAIN_FOREGROUND    = colors.white
local HEADER_BACKGROUND  = colors.gray
local HEADER_FOREGROUND  = colors.yellow
local HEADER_ACCENT_BG   = colors.yellow
local TAB_HEADER_BG      = colors.lightGray
local TAB_ACTIVE_BG      = colors.blue
local TAB_ACTIVE_TEXT    = colors.yellow

MAX_WIDTH = 26
local HEADER_HEIGHT      = 5
local TAB_CONTROL_Y      = HEADER_HEIGHT + 2 

-- Globals not declared at the top of the file for one reason or another
-- MOOD_MANAGER - Declared after the moodSection is initialized

local main = basalt.getMainFrame()
    :setBackground(MAIN_BACKGROUND)
    :setForeground(MAIN_FOREGROUND)

main:initializeState("chatInput", "", false)

local header = main:addFrame(
    {
        width = MAX_WIDTH,
        height = HEADER_HEIGHT,
        x = 1,
        y = 1
    }
)
    :setBackground(HEADER_BACKGROUND)
    :setForeground(HEADER_FOREGROUND)

local nameLabel = header:addLabel(
    {
        text="LUNA",
        height=1,
        x=10,
        y=3
    }
)
    :setForeground(MAIN_FOREGROUND)

local logoSection = header:addFrame(
    {
        width=7,
        height=HEADER_HEIGHT,
        x=1,
        y=1
    }
)
    :setBackground(HEADER_BACKGROUND)

logo.addLogo(logoSection)

local headerDivider = header:addFrame(
    {
        width=1,
        height=HEADER_HEIGHT,
        x=18,
        y=1
    }
)
    :setBackground(HEADER_ACCENT_BG)

local moodSection = header:addFrame(
    {
        width=8,
        height=HEADER_HEIGHT,
        x=19,
        y=1
    }
)

local MOOD_MANAGER = MoodManager.new(moodSection)

local headerMainSep = main:addFrame(
    {
        height=1,
        width=MAX_WIDTH,
        x=1,
        y=HEADER_HEIGHT + 1
    }
)
    :setBackground(HEADER_ACCENT_BG)

local tabController = main:addTabControl({
        x = 1,
        y = TAB_CONTROL_Y,
        height = 14,
        width = MAX_WIDTH,
        headerBackground=TAB_HEADER_BG,
        foreground=MAIN_BACKGROUND,
        activeTabBackground=TAB_ACTIVE_BG,
        activeTabTextColor=TAB_ACTIVE_TEXT
    }
)
    :setBackground(MAIN_BACKGROUND)

local conversationTab = tabController:newTab("Converse")
local thoughts = tabController:newTab("Thoughts")

local converse = conversationTab:addFrame({
    x = 2,
    y = 2,
    width = MAX_WIDTH - 2,
    height = 11 
})

local function getChildrenHeight(container)
    local height = 0
    for _, child in ipairs(container.get("children")) do
        if(child.get("visible"))then
            local newHeight = child.get("y") + child.get("height")
            if newHeight > height then
                height = newHeight
            end
        end
    end
    return height
end

local conversationInput = converse:addInput({
    x=1,
    y=10,
    width=MAX_WIDTH - 2,
    height = 2
})
    :setForeground(MAIN_FOREGROUND)
    :setBackground(TAB_ACTIVE_BG)
    :bind("text", "chatInput")
    :onKeyUp(function(self, value)
        -- 257 is the enter key
        if value ~= 257 then
            return
        end

        local input = self:getState("chatInput")
        local topics, positivity, intensity = parser:parse(input)
        
        local f = fs.open("/posint", "w")
        f.write("positivity: " .. positivity)
        f.write("\nintensity: " .. intensity)
        f.close()
        self:setState("chatInput", "")
        self.cursorPos = 1
        MOOD_MANAGER:shiftMood(positivity, intensity)
        addToConversation(false, input)
    end)

local conversation = converse:addFrame({
    x=1,
    y=1,
    height=9,
    width=MAX_WIDTH-2
})
    :setBackground(colors.gray)

conversation:onScroll(function(self, delta)
    local offset = math.max(0, math.min(self.get("offsetY") + delta, getChildrenHeight(self) - self.get("height")))
    self:setOffsetY(offset)
end)


function getWrappedLineCount(str, width)
    if not str or #str == 0 then return 0 end

    -- Remove any newline characters entirely
    str = str:gsub("\n", "")

    local lines = {}
    local words = strings.split(str, " ")
    local currentLine = ""

    for _, word in ipairs(words) do
        if #currentLine == 0 then
            currentLine = word
        elseif #currentLine + #word + 1 <= width then
            currentLine = currentLine .. " " .. word
        else
            table.insert(lines, currentLine)
            currentLine = word
        end
    end

    if #currentLine > 0 then
        table.insert(lines, currentLine)
    end

    return #lines, lines
end


function getConversationHeight()
    local height = 0
    local children = conversation.get("children")

    for _, child in ipairs(children) do
        height = height + child.get("height")
    end

    -- I'm not sure why I need a magic 2 here.
    -- Without it, the first item will be too high up.
    height = height + #children + 2
    return height
end


function addToConversation(isLuna, text)
    local chatSize = MAX_WIDTH - 4
    -- Get the current height of all children minus the height of the scrollbar
    -- The scrollbar will be the exact height of the current window.
    local height = getConversationHeight()
    local background = conversation:addFrame({
        x=4,
        y=height,
        width=chatSize,
        height=1
    })

    if isLuna then
        background:setBackground(colors.yellow)
    else
        -- Move the user conversation slightly left
        background.x = background.get("x") - 2
        background:setBackground(colors.blue)
    end

    local convLab = background:addLabel({
        text=text,
        width=chatSize,
        autoSize=false
    })

    if isLuna then
        convLab:setForeground(colors.black)
    else
        convLab:setForeground(colors.white)
    end

    local convHeight = getWrappedLineCount(text, chatSize)

    background:setHeight(convHeight)
    conversation:setOffsetY(conversation:getChildrenHeight() - 8)
end

addToConversation(false, "Asdf")
addToConversation(true, "hola?")
addToConversation(false, "How are you today LUNA?")
addToConversation(true, "Doing fine, danke")

thoughts:addLabel({
    x = 2,
    y = 2,
    text="I'm thinking..."
})
    :setForeground(MAIN_FOREGROUND)

basalt:run()
--return {ui=basalt, getMoodDisplay=getMoodDisplay}
