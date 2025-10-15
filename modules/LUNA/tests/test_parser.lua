local src = debug.getinfo(1, "S").source
local dir = src:match("^@(.+)/[^/]+$")
local parent = fs.getDir(dir)
-- Add the parent dir to the path so I can import files from there
package.path = package.path .. ";" .. "/" ..parent .. "/?.lua"

local Parser = require("parser")
local parser = Parser.new()

while true do
    term.clear()
    term.setCursorPos(1, 1)
    write("Input: ")
    local input = read()
    print(parser:parse(input))
    write("Press enter to clear the screen")
    input = read()
end
