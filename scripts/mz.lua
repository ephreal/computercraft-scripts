-- module zipper
-- compiles/decompiles a module into a single file
-- for rednet transfer
-- No compression occurs

MZ = {}
MZ.__index = MZ

-- Returns a new module zipper
function MZ.new()
    local self = {}
    setmetatable(self, MZ)
    return self
end

-- Lists the files and dirs at a path
-- returns the files and dirs to the caller
function MZ:listDir(path)
    local files = {}
    local dirs = {}
    for _,listing in ipairs(fs.list(path)) do
        local entry = path .. "/" .. listing
        if fs.isDir(entry) then
            table.insert(dirs, entry)
        else
            table.insert(files, entry)
        end
    end
    return files, dirs
end

-- Compiles a module into a single file for transfer
-- The compiled data is stored in a table which must be
-- serialized prior to sending over the network.
function MZ:compile(modulePath, removePathPrefix)
    if not removePathPrefix then
        removePathPrefix = ""
    end
    local files,dirs = self:listDir(modulePath)
    local data = {}
    local localPath = string.gsub(modulePath, removePathPrefix, "")
    for _,file in ipairs(files) do
        local fileData = {}
        local f = fs.open(file, 'r')
        fileData['contents'] = f.readAll()
        f.close()
        
        fileData['name'] = fs.getName(file)
        fileData['localDir'] = fs.getDir(fs.combine(localPath, fs.getName(file)))
        table.insert(data, fileData)
    end

    for _,dir in ipairs(dirs) do
        local entries = self:compile(dir, removePathPrefix)
        for _,entry in ipairs(entries) do
            table.insert(data, entry)
        end
    end
    return data
end

-- Extracts a module and handles all necessarry steps to
-- save it's files within the destination provided.
-- The data passed in should be a table created by
-- MZ:compile.
function MZ:decompile(data, destination)
    if not destination then
        destination = ""
    end

    if not fs.exists(destination) then
        fs.makeDir(destination)
    end

    for _,file in ipairs(data) do
        local dir = file['localDir']
        local dest = fs.combine(destination, dir)
        local filePath = fs.combine(dest, file.name)
        if not fs.exists(dest) then
            fs.makeDir(dest)
        end
        
        local f = fs.open(filePath, "w")
        f.write(file['contents'])
        f.close()
    end
end

-- Helper function to handle automatic compilation and
-- network serialization.
function MZ:serialise(modulePath, removePathPrefix)
    local data = self:compile(modulePath, removePathPrefix)
    return textutils.serialise(data)
end

-- Helper function the handle automatic extraction and
-- network deserialization
function MZ:deserialise(data, destination)
    local deserialised = textutils.unserialise(data)
    self:decompile(deserialised, destination)
end


return MZ
