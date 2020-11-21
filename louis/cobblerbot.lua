
function emtpyInventory()
    print("dropping inventory!")
    local sucked = false
    for i=1,16 do
        repeat
            turtle.turnRight()
            turtle.select(i)
            turtle.drop(64)
            sleep(5)
            turtle.turnLeft()
            sucked = turtle.suck()
            if (sucked==true) then
                print("Oh! Looks like the chess is full!")
                print("I guess my masters didn't need my cobble...")
                sleep(600)
            end
        until (sucked==false)
    end
    turtle.select(1)
end

function getBearings()
    print("Going to get my bearings after booting")
    local facingCobble
    repeat
        turtle.turnRight()
        local success, data = turtle.inspect()
        if success then
            print(data.name)
            if (data.name == "minecraft:cobblestone") then
                facingCobble = true
            end
        end
    until (facingCobble)
    print("There's some cobblestone!")
    print("Lets get busy!")
end

getBearings()
while(true)
do
    blockspawned = turtle.detect()
    if blockspawned == true then
        print("Digging cobble!")
        print("It fills me with joy")
        turtle.dig()
    end
    if (turtle.getItemCount(16)==64) then
        print("My investory is full")
        print("Going to drop my cobble for my masters!")
        emptyInventory()
        print("All done! I'm sure my masters will love it!")
    end
end