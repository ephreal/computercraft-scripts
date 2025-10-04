-- simple rnap client
local PROTOCOL = "rnap"
local SERVERNAME = "authServer"
local RECEIVE_TIMEOUT = 5

local authClient = {}
authClient.__index = authClient


function authClient.new()
    local self = {}
    setmetatable(self, authClient)

    -- open rednet if it's not already active
    if not rednet.isOpen() then
        local modem = peripheral.find("modem")
        if not modem then
            return "No modem found"
        end
        local side = peripheral.getName(modem)
        rednet.open(side)
    end

    self.timeout = RECEIVE_TIMEOUT
    self.protocol = PROTOCOL
    self.serverId = rednet.lookup(PROTOCOL, SERVERNAME)

    if not self.serverId then
        error("Unable to locate RNAP server")
    end

    return self
end

function authClient:login(user, password)
    local msg = {
        type="login",
        user=user,
        password=password
    }

    rednet.send(self.serverId, msg, self.protocol)
    local id, response = rednet.receive(self.protocol, self.timeout)
    if not response then
        return nil, "No response from auth server"
    elseif not response.ok then
        return nil, response.error or "An unknown error occurred"
    end
    return response.token
end


function authClient:checkAuth(token)
    local msg = {
        type="authToken",
        token=token
    }

    rednet.send(self.serverId, msg, self.protocol)
    local id, response = rednet.receive(self.protocol, self.timeout)

    if not response then
        return nil, "No response from auth server"
    elseif not response.ok then
        return nil, response.error or "An unknown error occurred"
    end

    -- The user is currently authenticated
    return true
end

function authClient:refresh(token)
    local msg = {
        type="refresh",
        token=token
    }

    rednet.send(self.serverId, msg, self.protocol)
    local id, response = rednet.receive(self.protocol, self.timeout)

    if not response then
        return nil, "No response from auth server"
    elseif not response.ok then
        return nil, response.error or "An unknown error occurred"
    end

    return response.token
end

function authClient:getGroups(token)
    local msg = {
        type="groups",
        token=token
    }
    rednet.send(self.serverId, msg, self.protocol)
    local id, response = rednet.receive(self.protocol, self.timeout)

    if not response then
        return nil, "No response from auth server"
    elseif not response.ok then
        return nil, response.error or "An unknown error occurred"
    end

    return response.groups
end

return authClient
