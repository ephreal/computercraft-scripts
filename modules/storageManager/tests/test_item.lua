local REAL_STORAGE_FROM_TYPE = "occultism:storage_controller"
local REAL_STORAGE_TO_TYPE = "storagedrawers:controller"

local src = debug.getinfo(1, "S").source
local dir = src:match("^@(.+)/[^/]+$")
local parent = fs.getDir(dir)
-- Add the parent dir to the path so I can import files from there
package.path = package.path .. ";" .. "/" ..parent .. "/?.lua"

local Item = require("item")
local testItem = {name="minecraft:cobblestone", count=122}

-- create an item object with fake data.
-- item, slot, storage device
local item = Item.new(testItem, 5, "dummy:chest_0")

local slot = item:getTransferSlot("dummy:some_other_chest_1")
assert(slot.storageDevice == "dummy:chest_0")
assert(slot.count == 122)

-- This *will* fail
local errorPart = "(a nil value)"
local success, errorMessage = pcall(function () item:transfer("does_not_exist:at_all_1", 6) end)

-- Just make sure the error actually occurred
assert(string.gmatch(errorMessage, errorPart)())

print("Item errors after this point indicate a problem")
print("with locating a real storage device")
if not REAL_STORAGE_FROM_TYPE and not REAL_STORAGE_TO_TYPE then
    -- No devices to test with
    return
end

local from = peripheral.find(REAL_STORAGE_FROM_TYPE)
local to = peripheral.find(REAL_STORAGE_TO_TYPE)

local itemSlot = from.list()[1]
local item = Item.new(itemSlot, 1, peripheral.getName(from))
local transferred = item:transfer(peripheral.getName(to), 1)

assert(transferred == 1)
