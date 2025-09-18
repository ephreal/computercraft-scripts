require("File")
ChunkedFile = {}
-- Set a max file size to slightly smaller than
-- a 1/4 of a disk drive
ChunkedFile.MAX_FILE_SIZE = 3100
ChunkedFile.METADATA_DIR = "/chunkMetadata/"
ChunkedFile.NAME_LENGTH = 16
ChunkedFile.__index = ChunkedFile

function ChunkedFile:new(filename, data)
    local chunker = {}
    setmetatable(chunker, ChunkedFile)
    
    chunker.filename = filename
    chunker.files = {}
    chunker.chunks = {}
    chunker.newFile = true
    chunker.changed = true
    if data then
        chunker = chunker:chunk(data)
    end
    return chunker
end

function ChunkedFile:chunk(data)
    self:makeChunks(data)
    self:nameFiles(#self.chunks)
    -- Returning self since it seems to be
    -- necessary when importing this script
    -- into another file for some reason??
    return self
end

function ChunkedFile:makeChunks(data)
    -- Splits the passed in file into multiple
    -- chunks
    local chunkTable = {}
    local size = ChunkedFile.MAX_FILE_SIZE
    -- size = 3
    for i=1,#data,size do
        chunkTable[#chunkTable+1] = data:sub(i, i+size - 1)
    end
    self.chunks = chunkTable
end

function ChunkedFile:nameFiles(amount)
    for i=1,amount,1 do
        local name = self:randomName()
        local file = File:new(name, nil)
        self.files[i] = file
    end
end

function ChunkedFile:fileExists(filename)
    return fs.exists(ChunkedFile.METADATA_DIR .. filename)
end

function ChunkedFile:randomName()
    local nameLength = ChunkedFile.NAME_LENGTH
    local chars = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
    local name = ""
    for i=1,nameLength,1 do
        local character = math.random(1, string.len(chars) )
        name = name .. chars:sub(character, character)
    end
    return name
end

function ChunkedFile:saveChunk(chunkIndex, storageDevice)
    -- it'd be nice to extend storageDevice to be a raw
    -- peripheral in the future.
    -- get the chunk and file
    local chunk = self.chunks[chunkIndex]
    local file = self.files[chunkIndex]
    
    -- set the saveDir for this file and save
    file.saveDir = storageDevice
    if self.newFile then
        while fs.exists(file:path()) do
            file.name = self:randomName()
        end
    end
    file:write(chunk)
    
    -- Clear this out so it's not holding data in
    -- RAM indefinitely
    self.chunks[chunkIndex] = nil
    
    -- Returning self because I can't seem to
    -- access the other chunks without doing so
    -- when importing this into another script.
    -- WTF is going on???
    return self
end

function ChunkedFile:overwriteChunk(chunkIndex)
    -- We're assuming that this is a safe file to
    -- overwrite and that the file object already
    -- has it's storage dir set.
    -- Note that this is a DANGEROUS function to
    -- call willy-nilly.
    -- Only call when you are *certain* the file
    -- is yours.
    local file = self.files[chunkIndex]
    if not file or not file.saveDir then
        return
    end
    file:write(self.chunks[chunkIndex])
end

function ChunkedFile:read()
    local data = ""
    for i=1,#self.files,1 do
        local file = self.files[i]
        data = data .. file:read()
    end
    return data
end

function ChunkedFile:load(chunkedFileName)
    local metaFile = ChunkedFile.METADATA_DIR .. chunkedFileName
    -- Ensure the file exists first
    if not fs.exists(metaFile) then
        -- Just exit
        return
    end
    local chunker = ChunkedFile:new()

    local f = fs.open(metaFile, "r")
    local strdata = f.readAll()
    f.close()

    local data = load(strdata)()
    chunker.filename = data.filename

    -- Prepare the file objects
    for index,file in pairs(data.files) do
        local drive = peripheral.wrap(file.drive)
        local mountpoint = drive.getMountPath()
        local file = File:new(file.name, "/" .. mountpoint)
        chunker.files[index] = file
    end
    chunker.newFile = false
    return chunker    
end

function ChunkedFile:delete()
    -- Deletes all the chunks and removes the
    -- metadata file
    for index,file in pairs(self.files) do
        file:delete()
    end
    fs.delete(ChunkedFile.METADATA_DIR .. self.filename)
end


function ChunkedFile:update(data)
    self.chunks = {}
    self:makeChunks(data)
    
    self:checkIfMoreChunks()
    self:checkIfFewerChunks()
    return self   
end

function ChunkedFile:checkIfMoreChunks()
    while #self.chunks > #self.files do
        -- Add more files to the files list
        -- until these are equal
        local name = self:randomName()
        while self:fileExists(name) do
            name = self:randomName()
        end
        local file = File:new(name, nil)
        local index = #self.files + 1
        self.files[index] = file
    end
end

function ChunkedFile:checkIfFewerChunks()
    while #self.chunks < #self.files do
        local file = table.remove(self.files, #self.files)
        file:delete()
    end
end
function ChunkedFile:stringify()
    local data = "return {files={"
    for index,file in pairs(self.files) do
        data = data .. file:stringify() .. ","
    end
    data = data .. "},"
    data = data .. "filename=\"" .. self.filename .. "\""
        
    -- Close the initial curly brace
    data = data .. "}"
    return data
end

function ChunkedFile:saveMetadata()
    -- Chunk data save location
    local saveName = ChunkedFile.METADATA_DIR .. self.filename
    local metadata = self:stringify()
    
    local f = fs.open(saveName, "w")
    f.write(metadata)
    f.close()
end


--------TESTS---------

-- VERIFY THAT CHUNK SIZE == MAX_FILE_SIZE
-- IN CF:MAKECHUNKS
local function testNew()
    local cf = ChunkedFile:new("testFile", "ABCDEFG")
    cf:update("ABCDEFGHIJ")
    for index, chunk in pairs(cf.files) do
        cf:saveChunk(index, "/disk")
    end
    cf:saveMetadata()
end

local function testLoad()
    local cf = ChunkedFile:load("testFile")
    local data = cf:read()
    print(data)
end

local function testUpdate()
    local cf = ChunkedFile:load("testFile")
    cf:update("This is a test of the update process")
    for index, chunk in pairs(cf.files) do
        cf:saveChunk(index, "/disk")
    end
    cf:saveMetadata()
end

local function testSmallerUpdate()
    ChunkedFile.MAX_FILE_SIZE = 3
    -- Prepare a larger sized file
    local cf = ChunkedFile:new("smallUpdate", "abcdef")
    print("Size of chunks and files pre-update")
    print("Chunks: " .. #cf.chunks)
    print("Files: " .. #cf.files)
    
    for index,file in pairs(cf.files) do
        print(file.name)
        cf:saveChunk(index, "/disk")
    end
    cf:saveMetadata()

    -- Now update the file with a smaller size
    cf:update("abc")
    print(#cf.files)
    print(cf.files[1].name)
    for index,chunk in pairs(cf.files) do
        cf:overwriteChunk(index)
    end
    print("Chunks: " .. #cf.chunks)
    print("Files: " .. #cf.files)
    print("Filename: " .. cf.files[1].name)
    cf:saveMetadata()
end

local function testDelete()
    local cf = ChunkedFile:load("testFile")
    cf:delete()
end

--testNew()
--testLoad()
--testUpdate()
--testSmallerUpdate()
--testDelete()
