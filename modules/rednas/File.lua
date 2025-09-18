File = {}

File.__index = File

function File:new(name, path)
    local file = {}
    setmetatable(file, File)
    
    file.name = name
    file.saveDir = path
    return file
end

function File:path()
    return self.saveDir .. "/" .. self.name
end

function File:read()
    local f = fs.open(self:path(), "r")
    local data = f.readAll()
    f.close()
    
    return data
end

function File:write(data)
    local f = fs.open(self:path(), "w")
    f.write(data)
    f.close()
    return true
end

-- Helper function
function File:save(data)
    return self:write(data)    
end

function File:delete()
    fs.delete(self:path())
end

function File:stringify()
    local diskPath = fs.getDir(self:path())
    local networkDrive = self:getNetworkDrive(diskPath)
    local driveName = peripheral.getName(networkDrive)
    x = "{name=\"" .. self.name .. "\","
    x = x .. "drive=\"" .. driveName .. "\","
    x = x .. "saveDir=\"" .. self.saveDir .. "\"}"
    return x
end

function File:getNetworkDrive(diskPath)
    for i,val in pairs(peripheral.getNames()) do
        if val:match("drive") then
            local drive = peripheral.wrap(val)
            local drivePath = drive.getMountPath()
            if diskPath == drivePath then
                return drive
            end
        end
    end
end

--f = File:new("hello", "/disk")
--f:save("Hello World!")
--print(f:stringify("disk20"))
