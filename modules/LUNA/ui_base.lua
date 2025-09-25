local basalt = require("basalt")
local moods = require("moods")
local logo = require("logo")
local MAIN_BACKGROUND   = colors.black
local MAIN_FOREGROUND   = colors.white
local HEADER_BACKGROUND = colors.gray
local HEADER_FOREGROUND = colors.yellow
local HEADER_ACCENT_BG  = colors.yellow
local HEADER_LOGO_BG    = colors.blue
local HEADER_HEIGHT     = 6

local main = basalt.getMainFrame()
    :setBackground(MAIN_BACKGROUND)
    :setForeground(MAIN_FOREGROUND)

local header = main:addFrame(
    {
        width = 26,
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
    :setBackground(HEADER_LOGO_BG)

moods.setMood(moodSection, moods.happy)

local headerMainSep = main:addFrame(
    {
        height=1,
        width=26,
        x=1,
        y=6
    }
)
    :setBackground(HEADER_ACCENT_BG)


basalt:run()
