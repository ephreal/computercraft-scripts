local strings = require("cc.strings")

-- A single item type
local Item = {}
Item.__index = Item


-- Creates a new Item instance
-- input item must be directly from an inventory.list()
-- properties
--     Item.fullName    [string]
--     Item.totalAmount [number]
--     Item.shortName   [string]
--     Item.displayName [string]
--     Item.slots       [table]
function Item.new(item, slot, storageDeviceName)
    local self = {}
    setmetatable(self, Item)

    -- rename these to be more sensible to me
    self.fullname = item.name
    self.totalAmount = item.count

    -- Add a few more fields I want
    self.shortName = table.concat(strings.split(fullname, ":"), " ", 2)
    self.displayName = shortname
    self.slots = {}
    self:addSlot(peripheralItem, slot, storageDeviceName)

    return self
end

-- Add a new slot to the item
-- Three properties:
--     item.count         [number]
--     item.slot          [string]
--     item.storageDevice [string]
function Item:addSlot(item, slot, storageDeviceName)
    local itemSlot = {}
    itemSlot.count = item.count
    itemSlot.slot = slot
    itemSlot.storageDevice = storageDeviceName
    table.insert(self.slots, itemSlot)
end


-- Transfer some amount of this item between storages
function Item:transfer(to, amount)
    local totalTransferred = 0

    while totalTransferred < amount do
        local slot = self:getTransferSlot()
        local storage = peripheral.wrap(slot.storageDevice)
        if not slot then
            return totalTransferred
        end

        local transferred =  storage.pushItems(to, slot.slot, amount)
        if not transferred then
            return totalTransferred
        end
        
        slot.count = slot.count - transferred
        
        totalTransferred = totalTransferred + transferred

        if slot.count == 0 then
            -- Remove the slot from self.slots
            self:rebuildSlots()
        end
    end
end


-- Gets the slot with the least amount of items in it
-- This way that slot will be emptied first
function Item:getTransferSlot()
    if #self.slots < 1 then
        return nil
    end
    local slot = self.slots[1]
    for _,toCheck in ipairs(self.slots) do
        if toCheck.count < slot.count then
            slot = toCheck
        end
    end
    return slot
end


-- Rebuild self.slots and remove any that are empty
function Item:rebuildSlots()
    local slots = {}
    for _,slot in ipairs(self.slots) do
        if slot.count > 0 then
            table.insert(slots, slot)
        end
    end
    self.slots = slots
end

return Item
