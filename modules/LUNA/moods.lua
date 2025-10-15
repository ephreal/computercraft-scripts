-- Sets the mood of LUNA
local TEXT_COLOR = colors.white

local AFFECTIONATE = {
    text="(^.^)",
    backgroundColor=colors.pink
}
local ANGRY = {
    text="!(ÒÓ)!",
    backgroundColor=colors.red
}
local BORED = {
    text="(._.)",
    backgroundColor=colors.gray
}
local CHILL = {
    text="(0_0)",
    backgroundColor=colors.blue
}
local CONFUSED = {
    text="~(00)~",
    backgroundColor=colors.black
}
local CURIOUS = {
    text = "(o_O)?",
    backgroundColor=colors.cyan
}
local EXCITED = {
    text = "(^_^)/",
    backgroundColor=colors.orange
}
local FRUSTRATED = {
    text="\\(»_«)/",
    backgroundColor=colors.red
}
local HAPPY = {
    text="(@_@)",
    backgroundColor=colors.green
}
local PLAYFUL = {
    text="(o~o)",
    backgroundColor=colors.green
}
local SAD = {
    text="(;_;)",
    backgroundColor=colors.blue
}
local SHOCKED = {
    text = "(O_O!)",
    backgroundColor = colors.orange
}
local SCIENTIFIC = {
    text="(«¤-¤)¬",
    backgroundColor=colors.gray
}
local SLEEPING = {
    text = "(~_~)zZ",
    backgroundColor=colors.black
}
local SMARMY = {
    text="(@¿@)",
    backgroundColor=colors.brown
}
local TIRED = {
    text="(-_-)",
    backgroundColor=colors.black
}

local function setMood(container, mood)
    -- remove any current mood from the container
    container:clear()
    container:setBackground(mood.backgroundColor)
    -- Add the new mood
    local moodContainer = container:addLabel(
        {
            text=mood.text,
            x=2,
            y=3,
            width=8,
            height=1
        }
    )
        :setBackground(mood.backgroundColor)
        :setForeground(TEXT_COLOR)
end

return {
    setMood = setMood,
    affectionate = AFFECTIONATE,
    angry = ANGRY,
    bored = BORED,
    chill = CHILL,
    confused = CONFUSED,
    curious = CURIOUS,
    excited = EXCITED,
    frustrated = FRUSTRATED,
    happy = HAPPY,
    playful = PLAYFUL,
    sad = SAD,
    scientific = SCIENTIFIC,
    shocked = SHOCKED,
    sleeping = SLEEPING,
    smarmy = SMARMY,
    tired = TIRED,
}

