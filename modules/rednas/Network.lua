require("Controller")
local Rednas = {}
protocol = "home"

Rednas.__index = Rednas

function Rednas:new()
    local rednas = {}
    setmetatable(rednas, Rednas)
    rednas.controller = Controller:new()
    rednet.open("top")
    rednet.host(protocol, "rednas")
    
    return rednas
end

function Rednas:listen()
    while true do
        print("Waiting to receive data")
        host, request = rednet.receive(protocol)
        print(request)
        if request == "save" then
            local filename, filedata = self:receiveFile(host)
            self:storeFile(filename, filedata)
        
        elseif request == "retrieve" then
            local filename = self:getFilename(host)
            local data = self.controller:read(filename)
            rednet.send(host, data, protocol)

        elseif request == "delete" then
            local filename = self:getFilename(host)
            self.controller:delete(filename)
        elseif request == "space" then
            rednet.send(host, self.controller:space(), protocol)
        end
    end
end

function Rednas:storeFile(filename, data)
    local file = self.controller:loadFile(filename)

    if file then
        self.controller:update(filename, data)
    else
        self.controller:save(filename, data)
    end
end

function Rednas:getFilename(host)
    rednet.send(host, "filename", protocol)
    local sender, filename = rednet.receive(protocol)
    return filename
end

function Rednas:receiveFile(host)
    local filename = self:getFilename(host)
    rednet.send(host, "data", protocol)
    local sender, data = rednet.receive(protocol)
    return unpack({filename, data})
end

rednas = Rednas:new()
rednas:listen()
