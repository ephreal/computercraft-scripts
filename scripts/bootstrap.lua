local Bootstrap = {}
Bootstrap.__index = Bootstrap


function Bootstrap.new(modemSide)
    local self = {}
    setmetatable(self, Bootstrap)
    
    self.name = os.getComputerLabel()
    self.modem = peripheral.wrap(modemSide)
    self.protocol = "bootstrap"
    self.serverName = "bootstrap-server"
    self.timeout = 5
    self.downloadDir = "/downloads/"
    self.manifestPath = self.downloadDir .. "manifest"
    
    if not self.modem then
        print("No modem found")
        return nil
    end
    
    if not fs.exists(self.downloadDir) then
        fs.makeDir(self.downloadDir)
    end

    -- open rednet and search for the bootstrap server
    rednet.open(modemSide)
    self.serverId = rednet.lookup(self.protocol, self.serverName)
    
    return self
end

function Bootstrap:setup()
    -- queries the bootstrap server to ask
    -- for any items this device needs
    -- (identified by os.getDeviceLabel)
    rednet.send(
        self.serverId,
        textutils.serialise(
            {
                op="setup",
                label=self.name
            }
        ),
        self.protocol
    )
    -- Wait for the bootstrap server to reply
    local sender,manifest = rednet.receive(self.protocol, self.timeout)
    
    if sender then
        self:backupManifest()
        local file = fs.open(self.manifestPath, "w")
        file.write(manifest)
        file.close()
        -- File manifest successfully downloaded
        return true
    end
    return false
end

function Bootstrap:backupManifest()
    if fs.exists(self.manifestPath) then
        if fs.exists(self.manifestPath .. ".bak") then
            fs.delete(self.manifestPath .. ".bak")
        end
        fs.move(self.manifestPath, self.manifestPath .. ".bak")
    end
end

function Bootstrap:download(filename, savePath, serverPath)
    rednet.send(self.serverId,
        textutils.serialise({filepath=serverPath, op="download"}),
        self.protocol)
    print("Downloading " .. filename)
    local sender,data = rednet.receive(self.protocol, self.timeout)
    local saveName = savePath .. "/" .. filename
    
    if data then
        if not fs.exists(savePath) then
            fs.makeDir(savePath)
        end
        local file = fs.open(saveName, "w")
        file.write(data)
        file.close()
        -- File successfully downloaded
        return true
    end
    return false
end

function Bootstrap:downloadModule(modpath, installPath)
    -- MZ must have been downloaded and installed
    local f = fs.open("/scripts/mz.lua", "r")
    local MZ = load(f.readAll())()
    f.close()
    local mz = MZ.new()
    rednet.send(self.serverId,
        textutils.serialise({modpath=modpath, op="moduleDownload"}),
        self.protocol
    )
    local server,module = rednet.receive(self.protocol, self.timeout)
    if module then
        local success, message = pcall(function() mz:deserialise(module, installPath) end)
        if not success then
            print("Module install failed")
            print(message)
        end
    end
end


-- manifest comparison is *NOT* being used yet
-- I'm going to skip this optimization for now
-- and keep this here as a reminder to add it
-- sometime.
function Bootstrap:compareManifests(old, new)
    -- generates a manifest containing any differences
    -- that need to be downloaded
    if not old then
        return new
    end
    local diff = {}
    local oldDefaults = old.defaults
    local newDefaults = new.defaults
    local oldHost = old.host
    local newHost = new.host

    diff['defaults'] = self:compareManifestEntries(oldDefaults, newDefaults)
    diff['host'] = self:compareManifestEntries(oldHost, newHost)
    return diff
end

function Bootstrap:compareManifestEntries(old, new)
    local categories = {"protocols", "files", "modules"}
    local diff = {}
    for _,category in ipairs(categories) do
        local oldCategory = old[category]
        local newCategory = new[category]
        diff[category] = {}
    end

    return diff
end

function Bootstrap:readManifest()
    if not fs.exists(self.manifestPath) then
        return {}
    end

    local file = fs.open(self.manifestPath, "r")
    local manifest = file.readAll()
    file.close()
    return textutils.unserialise(manifest)
end

function Bootstrap:downloadFromManifest(manifest)
    -- Download standalone files first. These will
    -- include the default files required for everything
    -- else to work
    for _,file in ipairs(manifest['files']) do
        self:download(file.filename, file.savepath, file.serverpath)
    end

    for _,module in ipairs(manifest['modules']) do
        print("Installing " .. module.modname)
        self:downloadModule(module.modpath, module.installDir)
    end
end

-- Find the modem
local modem = peripheral.find("modem")
local bootstrap = Bootstrap.new(peripheral.getName(modem))
bootstrap:setup()
local manifest = bootstrap:readManifest()
bootstrap:downloadFromManifest(manifest)
