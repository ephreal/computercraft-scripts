require("Disk")
require("ChunkedFile")

Controller = {}
Controller.__index = Controller

function Controller:new()
    local controller = {}
    setmetatable(controller, Controller)
    
    controller.disks = {}
    controller.filenames = {}
    controller:initDisks()
    controller:initFiles()
    return controller
end

function Controller:initDisks(amount)
    -- Generate a list of peripherals connected
    -- to the computer that have "drive" in the
    -- peripheral name
    local drives = {}
    for i,val in pairs(peripheral.getNames()) do
        if val:match("drive") then
            table.insert(drives, val)
        end
    end
    for i,val in pairs(drives) do
        local drive = peripheral.wrap(val)
        self.disks[i] = Disk:new(drive)
    end
end

function Controller:initFiles()
    -- Populates the files table with a list of all
    -- the files in the metadata storage dir
    for index,filename in ipairs(fs.list(ChunkedFile.METADATA_DIR)) do
        self.filenames[index] = filename
    end
end


function Controller:read(filename)
    local file = self:loadFile(filename)
    if not file then
        return ""
    end
    return file:read()
end

function Controller:save(filename, data)
    -- Make sure a file with this name
    -- doesn't already exist
    local existingFile = self:loadFile(filename)
    if existingFile then
        print("file exists")
        return
    end
    
    -- Proceed with saving the file
    -- Start with a new ChunkedFile and chunk the
    -- data into it.
    local file = ChunkedFile:new(filename)
                 :chunk(data)
    
    -- Go through each chunk of data, then find and
    -- save the data to a disk drive with enough
    -- space to hold the file.
    for i=1,#file.chunks,1 do
        local chunk = file.chunks[i]
        local disk = self:getAvailableDisk(chunk)
        file:saveChunk(i, disk)
    end
    file:saveMetadata()
    
    local fileIndex = #self.filenames + 1
    self.filenames[fileIndex] = file.filename
end


function Controller:delete(filename)    
    -- Load the chunked file
    local file = self:loadFile(filename)
    if not file then
        return
    end
    
    file:delete()
end

function Controller:loadFile(filename)
    -- Ensure the file exists
    for index,name in pairs(self.filenames) do
        if name == filename then
            local file = ChunkedFile:load(filename)
            return file
        end
    end
    -- Explicitly return nil to ensure checks
    -- are handled properly.
    return nil
end

function Controller:update(filename, data)
    -- Updates the file with the name specified by
    -- filename to have the data in `data`
    local file = self:loadFile(filename)
    if not file then
        return
    end
    
    file:update(data)
    print("Overwriting data: " .. data)
    for i,f in pairs(file.files) do
        if f.saveDir == nil then
            f.saveDir = self:getAvailableDisk()
        end
        file:overwriteChunk(i)
    end
end

function Controller:space()
    local free = 0
    for index, disk in pairs(self.disks) do
        free = free + disk:space()
    end
    
    return free
end

function Controller:getAvailableDisk(data)
    -- Gets the first available storage location
    -- for the data available.
    -- This data size should be <= the max
    -- file size: ChunkedFile.MAX_FILE_SIZE
    local size = string.len(data)
    
    -- Iterate through the disks and find a free
    -- disk
    for i=1,#self.disks,1 do
        local disk = self.disks[i]
        if disk:space() > size then
            return disk.fsPath
        end
    end
end



local function testInit()
    local controller = Controller:new(20)
end

local function testNew()
    ChunkedFile.MAX_FILE_SIZE = 3
    local controller = Controller:new()
    controller:save("testControllersSave", "Twas brilling and the slithey toves...")
    for index,file in pairs(controller.filenames) do
        print(file)
    end
end

local function testLoad()
    local controller = Controller:new()
    local x = controller:loadFile("testControllersSave")
    print("controllerFilename: " .. x.filename)
end

local function testUpdate()
    -- Verifies that files can be updated properly.
    -- Use testNew() to create a file for this if
    -- it doesn't already exist.
    ChunkedFile.MAX_FILE_SIZE = 3
    local controller = Controller:new()
    controller:update("testControllersSave", "123")
end

local function testDelete()
    local controller = Controller:new()
    local x = controller:loadFile("testControllersSave")
    x:delete()
end


local function testSpace()
    local controller = Controller:new()
    print(controller:space())
end

--testInit()
--testNew()
--testLoad()
--testUpdate()
--testDelete()
--testSpace()
