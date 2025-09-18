BOOTSTRAP_PROTOCOL = "bootstrap"
BOOTSTRAP_SERVER = "bootstrap-server"

function downloadBootstrap()
    local modem = peripheral.find("modem")
    local side = peripheral.getName(modem)
    rednet.open(side)
    local serverId = rednet.lookup(BOOTSTRAP_PROTOCOL, BOOTSTRAP_SERVER)
    rednet.send(serverId, "init", BOOTSTRAP_PROTOCOL)
    server,data = rednet.receive(BOOTSTRAP_PROTOCOL, 5)
    if data then
        bootstrap = data
        load(data)()
    end
end


downloadBootstrap()
