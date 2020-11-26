-- Spins in a circle an shears all sheep around the turtle. Note, placing
-- dropping shears on the ground will shear any sheep in that square. Spinning
-- and placing don't require fuel.
 
os.loadAPI("/gitlib/carlos/inventory.lua")

rednet.open("left")

last_export_time = nil
wool_count = 0
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
    if last_export_time == nil or (os.time() - last_export_time) > 20 then
        print("exporting stats")
        rednet.broadcast({total_wool=wool_count}, "shear_stats")
        last_export_time = os.time()
    end
    sleep(1)
end