-- frontdoor.lua
package.path = package.path .. ";" .. "/modules/rnap/?.lua"
local authClient = require("modules.rnap.authClient")

local REDSTONE_SIDE = "left"
local GRANT_POWER = 15
local DENY_POWER = 0
local GRANT_DURATION = 5

-- create client (will open rednet if needed)
local ok, client = pcall(authClient.new)
if not ok then
    print("Failed to initialize auth client:", client)
    return
end

local function show(msg)
    term.clear()
    term.setCursorPos(1,1)
    print(msg)
end

local function openDoor(user)
    show("Welcome " .. tostring(user))
    redstone.setAnalogOutput(REDSTONE_SIDE, GRANT_POWER)
    sleep(GRANT_DURATION)
    redstone.setAnalogOutput(REDSTONE_SIDE, DENY_POWER)
end

local function attemptLogin()
    term.clear()
    term.setCursorPos(1,1)
    write("Username: ")
    local username = read()
    write("Password: ")
    local password = read("*")

    -- try login
    local token, err = client:login(username, password)
    if not token then
        show("Login failed: " .. tostring(err))
        sleep(2)
        return
    end

    openDoor(username)
end

-- main loop
while true do
    attemptLogin()
end

