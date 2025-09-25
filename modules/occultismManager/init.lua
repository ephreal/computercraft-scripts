local src = debug.getinfo(1, "S").source
local dir = src:match("^@(.+)/[^/]+$")
local parent = fs.getDir(dir)
-- Add the parent dir to the path so I can import files from there
package.path = package.path .. ";" .. "/" ..parent .. "/?.lua"

-- The occultism storage controller on the network
local OCCULTISM_NAME = "occultism:storage_controller_0"
-- The long term storage location to place items in
local LONGTERM_NAME = "storagedrawers:controller_0"

function max_512()
    local occultism = peripheral.wrap(OCCULTISM_NAME)
    for slot,item in pairs(occultism.list()) do
        if item.count > 512 then
            local amount = item.count - 512
            occultism.pushItems(LONGTERM_NAME, slot, amount)
        end
    end
end

function min_256()
    local occultism = peripheral.wrap(OCCULTISM_NAME)
    local lts = peripheral.wrap(LONGTERM_NAME)
    for slot,item in pairs(occultism.list()) do
        if item.count < 256 then
            -- Check if this is in the longeterm storage
            for lts_slot,lts_item in pairs(lts.list()) do
                if item.name == lts_item.name then
                    print(item.name)
                    print(lts_item.name)
                    local amount = 256 - item.count
                    print(amount)
                    lts.pushItems(OCCULTISM_NAME, lts_slot, amount)
                end
            end
        end
    end
end

while true do
    max_512()
    min_256()
    sleep(5)
end
