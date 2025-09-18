-- a disk "class" for use in the rednas
Disk = {}
Disk.__index = Disk

function Disk:new(networkDrive)
    local disk = {}
    setmetatable(disk, Disk)

    disk.drive = networkDrive
    disk.fsPath = disk.drive.getMountPath()
    disk.id = disk.drive.getDiskID()
    if not disk.id then
        local name = peripheral.getName(disk.drive)
        print("Warning: " .. name .. " has no disk")
    end
    return disk
    
end

function Disk:space()
    if not self.id then
        print("Warning: " .. name .. " has no disk")
        return 0
    end
    return fs.getFreeSpace(self.fsPath)
end

local function testSpace()
    local x = Disk:new(peripheral.wrap("drive_0"))
    print(x:space())
end

--x = Disk:new("drive_0")
--print(x.fsPath)
--print(x:files())

--testSpace()
