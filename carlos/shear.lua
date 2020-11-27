-- Spins in a circle an shears all sheep around the turtle. Note, placing
-- dropping shears on the ground will shear any sheep in that square. Spinning
-- and placing don't require fuel.
 
os.loadAPI("/gitlib/carlos/inventory.lua")

SECONDS_BETWEEN_EXPORTS = 20

wool_count = 0
last_export_time = nil
should_export_stats = false

function export_stats()
    if not should_export_stats then
        return
    end
    if last_export_time == nil or
       (os.clock() - last_export_time) > SECONDS_BETWEEN_EXPORTS then
        print("exporting stats")
        rednet.broadcast({total_wool=wool_count}, "shear_stats")
        last_export_time = os.clock()
    end
end

if peripheral.getType("left") == "modem" then
  should_export_stats = true
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
    new_wool_count = inventory.countItemWithName("minecraft:black_wool")
    if new_wool_count ~= wool_count then
        wool_count = new_wool_count
        print("MOAR WOOL!", wool_count)
    end
    export_stats()
    sleep(1)
end