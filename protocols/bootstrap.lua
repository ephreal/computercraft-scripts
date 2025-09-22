-- The bootstrap protocol is used to ensure the
-- computer has everything necessary for its task
-- It can be manually downloaded by sending an
-- operation of "init" and receiving the response
local MZ = require("scripts.mz")
local mz = MZ.new()

local Protocol = {}
local protocolName = "bootstrap"

Protocol.__index = Protocol

function Protocol.new(modemSide)
    local self = {}
    self.name = protocolName
    self.hostsDir = "/hosts/"
    self.scriptDir = "/scripts/"
    self.defaultManifest = self.hostsDir .. "default.lua"

    self.modem = peripheral.wrap(modemSide)
    if not self.modem then
        print("No modem found. Ensure a modem is")
        print("present and try again")
    end
    setmetatable(self, Protocol)
    rednet.open(modemSide)
    rednet.host(self.name, "bootstrap-server")
    return self
end

function Protocol:init(recipient)
    local f = fs.open(self.scriptDir .. "bootstrap.lua", "r")
    local data = f.readAll()
    f.close()
    rednet.send(recipient, data, self.name)
end

function Protocol:getDefaultManifest()
    local manifest = ""
    if fs.exists(self.defaultManifest) then
        local file = fs.open(self.defaultManifest, "r")
        manifest = file.readAll()
        file.close()
    end
    return textutils.unserialize(manifest)
end


function Protocol:sendManifest(recipient, label)
    -- Check if this host is known
    local manifest = self:getDefaultManifest()

    if label and fs.exists(self.hostsDir .. label) then
        local manifestPath = self.hostsDir .. label .. "/manifest.lua"
        local file = fs.open(manifestPath, "r")
        if file then
            local append = textutils.unserialize(file.readAll())
            file.close()
            self:extendTable(manifest.files, append.files)
            self:extendTable(manifest.protocols, append.protocols)
            self:extendTable(manifest.modules, append.modules)
        end
    end

    local sendable = textutils.serialise(manifest)
    rednet.send(recipient, sendable, self.name)
end

function Protocol:extendTable(toExtend, newData)
    if newData then
        for _,value in ipairs(newData) do
            table.insert(toExtend, value)
        end
    end
    return toExtend
end


function Protocol:sendFile(recipient, filepath)
    if not filepath then
        rednet.send(recipient, "filepath missing", self.name)
        return
    end
    if not fs.exists(filepath) then
        rednet.send(recipient, filepath .. " does not exist", self.name)
        return
    end
    local file = fs.open(filepath, "r")
    local data = file.readAll()
    rednet.send(recipient, data, self.name)
end

function Protocol:sendModule(recipient, modpath)
    if not modpath then
        rednet.send(recipient, "modpath missing")
        return
    end
    if not fs.exists(modpath) then
        rednet.send(recipient, "modpath nonexistent")
        return
    end
    local data = mz:serialise(modpath, fs.getDir(modpath))
    rednet.send(recipient, data, self.name)
end


function Protocol:listen()
    while true do
        local sender,message = rednet.receive(self.name)
        local ok, deserialized = pcall(textutils.unserialise, message)

        if message == "init" then 
            self:init(sender)
        elseif not ok  then
            rednet.send(sender, error, self.name)
        elseif not deserialized.op then
            -- an op is required for all other ops
            rednet.send(sender, "Invalid message", self.name)

        elseif deserialized.op == "setup" then
            self:sendManifest(sender, deserialized.label)
        elseif deserialized.op == "download" then
            self:sendFile(sender, deserialized.filepath)
        elseif deserialized.op == "moduleDownload" then
            self:sendModule(sender, deserialized.modpath)
        end
    end
end

return Protocol
