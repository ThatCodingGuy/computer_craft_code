


-- Preconditions:
-- Turtle is on the edge of a chunk, at the desired height
-- A chest is behind the turtle, with sufficient storage to store everything.
-- The turtle has enough fuel to run the entire line

local function dropAll()
    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.drop()
    end
end

local function inventorySlotsRemaining()
    count = 0
    for i = 1, 16, 1 do
        if turtle.getItemCount(i) == 0 then
            count = count + 1
        end
    end
    return count
end

local function forceForward(blocks)
    while blocks > 0 do
        success = turtle.forward()
        if success then
            blocks = blocks - 1
        else 
            turtle.dig()
        end
    end
end

local function forceUp(blocks)
    while blocks > 0 do
        success = turtle.up()
        if success then
            blocks = blocks - 1
        else 
            turtle.digUp()
        end
    end
end

local function bore()
    while true do
        isAir, blockData = turtle.inspectDown()
        if isAir then
            moved = turtle.down()
            if moved then
                down = down + 1
            end
        else
            turtle.digDown()

            if inventorySlotsRemaining() == 0 then
                forceUp(down)
                return false
            end

            if blockData.name == "minecraft:bedrock" then
                forceUp(down)
                return true
            end
        end
    end

    return true
end

i = 0
while true do
    done = bore()
    if done then
        if i == 15 then
            break;
        end
        forceForward(1)
        i = i + 1
    else
        turtle.turnRight()
        turtle.turnRight()
        forceForward(i)
        dropAll()
        turtle.turnRight()
        turtle.turnRight()
        forceForward(i)
    end
end

turtle.turnRight()
turtle.turnRight()
forceForward(i)
dropAll()


    

