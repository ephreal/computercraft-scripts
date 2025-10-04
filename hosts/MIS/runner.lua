package.path = package.path .. ";" .. "/scripts/?.lua"
package.path = package.path .. ";" .. "/modules/rnap/?.lua"
local bootstrap = require("bootstrap")

authServer = require("modules.rnap.authServer")
auth = authServer.new()
auth:run()
