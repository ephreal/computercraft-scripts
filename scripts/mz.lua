-- module zipper
-- compiles/decompiles a module into a single file
-- for rednet transfer
-- No compression occurs

MZ = {}
MZ.__index = MZ

function MZ.new()
    local self = {}
    setmetatable(self, MZ)
    return self
end

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

function MZ:serialise(modulePath, removePathPrefix)
    local data = self:compile(modulePath, removePathPrefix)
    return textutils.serialise(data)
end

function MZ:deserialise(data, destination)
    local deserialised = textutils.unserialise(data)
    self:decompile(deserialised, destination)
end


return MZ
