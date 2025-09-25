-- Sets the mood of LUNA
local TEXT_COLOR = colors.white

local ANGRY = {
    text="!(ÒÓ)!",
    backgroundColor=colors.red
}
local CHILL = {
    text="(0_0)",
    backgroundColor=colors.blue
}
local CONFUSED = {
    text="~(00)~",
    backgroundColor=colors.black
}
local FRUSTRATED = {
    text="\\(»_«)/",
    backgroundColor=colors.red
}
local HAPPY = {
    text="(@_@)",
    backgroundColor=colors.green
}
local SCIENTIFIC = {
    text="(«¤-¤)¬",
    backgroundColor=colors.gray
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
  angry = ANGRY,
  chill = CHILL,
  confused = CONFUSED,
  frustrated = FRUSTRATED,
  happy = HAPPY,
  scientific = SCIENTIFIC,
  smarmy = SMARMY,
  tired = TIRED,
}

