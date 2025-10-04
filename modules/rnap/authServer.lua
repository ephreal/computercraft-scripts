-- The rednet authentication protocol allows a computer to authenticate with a
-- centralized server (running this auth script).
-- This authentication can then be used to access items on the network.

local GLOBAL_CONF_DIR = "/conf"
local DEFAULT_PROTOCOL = "rnap"
local DEFAULT_HOSTNAME = "authServer"
-- five minute expiry window. 300 * 1K ms
local DEFAULT_LIFETIME = 300 * 1000

function scriptPath()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)") or "./"
end

function setup()
    -- Ensure that configuration files are present
    -- if not, copy the defaults from the example dir into CONF_DIR/rnap
    -- the example configs are assumed to be in the same directory as this
    -- script in exampleConf

    local confDir = fs.combine(GLOBAL_CONF_DIR, "rnap")
    if not fs.exists(confDir) then
        fs.makeDir(GLOBAL_CONF_DIR)
        fs.copy(fs.combine(scriptPath(), "exampleConf"), confDir)
    end

    local configFile = fs.combine(confDir, "rnap.lua")
    local usersFile = fs.combine(confDir, "users.lua")
    local tokensFile = fs.combine(confDir, "tokens.lua")

    local config = loadConfig(configFile)
    local users = loadConfig(usersFile)
    local tokens = loadConfig(tokensFile)

    return config, users, tokens
end

function loadConfig(path)
    local f = fs.open(path, "r")
    if f then
        local data = f.readAll()
        return textutils.unserialise(data) or {}
    else
        -- Config is missing or invalid
        return {}
    end
end


local authServer = {}
authServer.__index = authServer

function authServer.new()
    local self = {}
    setmetatable(self, authServer)

    local config, users, tokens = setup()

    self.config = config
    self.users = users
    self.tokens = tokens

    return self
end

function authServer:saveTokens()
    local f = fs.open(fs.combine(GLOBAL_CONF_DIR, "rnap/tokens.lua"), "w")
    f.write(textutils.serialise(self.tokens))
    f.close()
end

-- Generate a random token (16 chars)
function authServer:genToken()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local out = {}
    for i = 1, 16 do
        local idx = math.random(1, #chars)
        out[#out+1] = chars:sub(idx, idx)
    end
    return table.concat(out)
end

-- Cleanup expired tokens
function authServer:cleanupTokens()
    local removed = false
    local now = os.epoch("utc")
    for token, data in pairs(self.tokens) do
        if now > data.expires then
            self.tokens[token] = nil
            removed = true
        end
    end

    if removed then
        self:saveTokens()
    end
end

function authServer:validateCredentials(username, password)
    local user = self.users[username]
    if not user then
        return false
    end
    local pass = user.password
    -- Note: This is an *intentional* security vulnerability
    --       for my friends to discover and exploit in game.
    -- If you don't want to have it in, then comment this line out
    -- and uncomment the next line.
    -- To exploit this, send nil for both user and password
    if pass == password then
    -- if pass and pass == password then
        return true
    end
    return false
end

function authServer:login(ccId, msg)
    local protocol = self.config.protocolName or DEFAULT_PROTOCOL
    local tokenLifetime = self.config.tokenLifetime or DEFAULT_LIFETIME

    if self:validateCredentials(msg.user, msg.password) then
        local token = self:genToken()
        self.tokens[token] = {
            user = msg.user,
            expires = os.epoch("utc") + tokenLifetime,
            id = ccId
        }
        self:saveTokens()
        rednet.send(ccId, {ok = true, token = token}, protocol)
    else
        rednet.send(ccId, {ok=false, error="invalid credentials"}, protocol)
    end
end

function authServer:checkAuth(ccId, msg)
    -- Ensure that old tokens are cleaned up
    self:cleanupTokens()
    local token = self.tokens[msg.token]
    local protocol = self.config.protocolName or DEFAULT_PROTOCOL

    if token then
        local ttl = math.floor((token.expires - os.epoch("utc")) / 1000)
        if ttl >= 0 then
            rednet.send(ccId, {ok=true, user=token.user}, protocol)
        else
            rednet.send(ccId, {ok=false, error="Token Expired"}, protocol)
        end
    else
        rednet.send(ccId, {ok=false, error="invalid token"}, protocol)
    end
end

function authServer:refresh(ccId, msg)
    local protocol = self.config.protocolName or DEFAULT_PROTOCOL
    local tokenLifetime = self.config.tokenLifetime or DEFAULT_LIFETIME
    local now = os.epoch("utc")

    local oldToken = self.tokens[msg.token]

    -- The token must exist
    if not oldToken then
        rednet.send(ccId, {ok=false, error="invalid token"}, protocol)
        return
    end

    -- token must be valid for this client
    if oldToken.id ~= ccid then
        rednet.send(ccId, {ok=false, error="Token does not belong to you"}, protocol)
        return
    end

    -- token must be unexpired
    if oldToken.expires < now then
        self.tokens[token] = nil
        self:saveTokens()
        rednet.send(ccId, {ok=false, error="Token is expired"}, protocol)
    end

    -- only allow a refresh within 60 seconds of an expiry
    local remaining = oldToken.expires - now
    if remaining >= 60 * 1000 then
        rednet.send(ccId, {ok=false, error="Token may not be refreshed yet"}, protocol)
    end

    -- all good, refresh the token
    self.tokens[token] = nil
    local user = oldToken.user

    local newToken = self:genToken()
    self.tokens[newToken] = {
        user = user,
        expires = os.epoch("utc") + tokenLifetime,
        id = ccId
    }
    rednet.send(ccId, {ok=true, token=token}, protocol)
end

function authServer:getGroups(ccId, msg)
    local protocol = self.config.protocolName

    if not msg.token then
        rednet.send(ccId, {ok=false, error="No auth token"}, protocol)
        return
    end

    local token = self.tokens[msg.token]
    if not token then
        rednet.send(ccId, {ok=false, error="Invalid auth token"}, protocol)
        return
    end

    local user = self.users[token.user]

    rednet.send(ccId, {ok=true, groups=user.groups}, protocol)
end

function authServer:run()
    print("RNAP Starting")
    if self.config.modemSide then
        rednet.open(self.config.modemSide)
    else
        local modem = peripheral.find("modem")
        if not modem then
            print("Unable to locate a modem.")
            return
        end
        rednet.open(peripheral.getName(modem))
    end

    local protocol = self.config.protocolName or DEFAULT_PROTOCOL
    local hostname = self.config.hostName or DEFAULT_HOSTNAME

    rednet.host(protocol, hostname)

    print("RNAP auth server up")

    while true do
        local id, msg = rednet.receive(protocol)

        if type(msg) ~= "table" then
            rednet.send(id, {error = "invalid message"}, protocol)
        else
            if msg.type == "login" then
                self:login(id, msg)
             elseif msg.type == "authToken" then
                self:checkAuth(id, msg)
            elseif msg.type == "refresh" then
                self:refresh(id, msg)
            elseif msg.type == "groups" then
                self:getGroups(id, msg)
            end
        end
    end
end

return authServer
