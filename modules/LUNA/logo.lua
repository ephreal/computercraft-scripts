LOGO_COLOR = colors.white

-- adds a large "M" to the element passed in
local function addLogo(container)
    -- Segments of the big M from left to right
    local segments = {
        {height=5, width=1, x=1, y=1},
        {height=2, width=1, x=2, y=2},
        {height=2, width=1, x=3, x=3},
        {height=2, width=1, x=4, y=2},
        {height=5, width=1, x=5, y=1}
    }

    for _,segment in ipairs(segments) do
        container:addFrame(
            {
                height=segment.height,
                width=segment.width,
                x=segment.x,
                y=segment.y
            }
        )
        :setBackground(LOGO_COLOR)
    end
end

return {addLogo=addLogo}
