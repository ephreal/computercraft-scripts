-- Global vars for rednet lookup and usage
BOOTSTRAP_PROTOCOL = "bootstrap"
BOOTSTRAP_SERVER = "bootstrap-server"

function downloadBootstrap()
    -- You may have to specify a side if you have multiple
    -- modems attached to your device
    local modem = peripheral.find("modem")
    local side = peripheral.getName(modem)
    rednet.open(side)

    -- Lookup the server ID and request the bootstrap script
    local serverId = rednet.lookup(BOOTSTRAP_PROTOCOL, BOOTSTRAP_SERVER)
    rednet.send(serverId, "init", BOOTSTRAP_PROTOCOL)
    server,data = rednet.receive(BOOTSTRAP_PROTOCOL, 5)

    -- Execute immediately to setup this device
    if data then
        bootstrap = data
        load(data)()
    end
end


downloadBootstrap()
