-- Spins in a circle an shears all sheep around the turtle. Note, placing
-- dropping shears on the ground will shear any sheep in that square. Spinning
-- and placing don't require fuel.
 
local inventory = require("inventory")

local SECONDS_BETWEEN_EXPORTS = 20

local g_wool_count = 0
local g_last_export_time = nil
local g_should_export_stats = false
local wool_item_types = {
    "minecraft:black_wool",
    "minecraft:purple_wool"
}

local function export_stats()
    if not g_should_export_stats then
        return
    end
    if g_last_export_time == nil or
       (os.clock() - g_last_export_time) > SECONDS_BETWEEN_EXPORTS then
        print("exporting stats")
        rednet.broadcast({total_wool=g_wool_count}, "shear_stats")
        g_last_export_time = os.clock()
    end
end

if peripheral.getType("left") == "modem" then
  g_should_export_stats = true
  rednet.open("left")
end

while 1 do
    for i=1,4 do
        if not inventory.selectItemWithName("minecraft:shears")  then
            error("I have no shears")
        end
        turtle.place()
        turtle.suck()
        turtle.turnLeft()
    end
    local new_wool_count = 0
    for _, item_type in ipairs(wool_item_types) do
        new_wool_count = new_wool_count + inventory.countItemWithName(item_type)
    end
    if new_wool_count ~= g_wool_count then
        g_wool_count = new_wool_count
        print("MOAR WOOL!", g_wool_count)
    end
    export_stats()
    sleep(1)
end