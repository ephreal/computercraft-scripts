require("Controller")
local Rednas = {}

Rednas.__index = Rednas

function Rednas.new()
    local self = {}
    setmetatable(self, Rednas)
    self.controller = Controller.new()
    self.protocol = "nas"
    self.hostname = "rednas"

    rednet.open("top")
    rednet.host(self.protocol, self.hostname)
    
    return self
end

function Rednas:listen()
    print("Waiting to receive data")
    print("Hostname: " .. self.hostname)
    print("Protocol: " .. self.protocol)
    while true do
        print("Waiting to receive data")
        host, request = rednet.receive(self.protocol)
        print(request)
        if request == "save" then
            local filename, filedata = self:receiveFile(host)
            self:storeFile(filename, filedata)
        
        elseif request == "retrieve" then
            local filename = self:getFilename(host)
            local data = self.controller:read(filename)
            rednet.send(host, data, self.protocol)

        elseif request == "delete" then
            local filename = self:getFilename(host)
            self.controller:delete(filename)
        elseif request == "space" then
            rednet.send(host, self.controller:space(), self.protocol)
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
    rednet.send(host, "filename", self.protocol)
    local sender, filename = rednet.receive(self.protocol)
    return filename
end

function Rednas:receiveFile(host)
    local filename = self:getFilename(host)
    rednet.send(host, "data", self.protocol)
    local sender, data = rednet.receive(self.protocol)
    return unpack({filename, data})
end

--rednas = Rednas:new()
--rednas:listen()

return Rednas
