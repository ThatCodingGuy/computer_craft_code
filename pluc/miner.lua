function dropAllButOne(slot)
    turtle.select(slot)
    turtle.drop(turtle.getItemCount() - 1)
end

function force()
    while turtle.inspect() do
        turtle.dig()
    end
    turtle.forward()
end

function forceUp()
    while turtle.inspectUp() do
        turtle.digUp()
    end
    turtle.up()
end

function forceDown()
    while turtle.inspectDown() do
        turtle.digDown()
    end
    turtle.down()
end

function cleanup()
    turtle.refuel(2)
    dropAllButOne(2)
    dropAllButOne(3)
    dropAllButOne(4)
    dropAllButOne(5)
    dropAllButOne(6)
    turtle.select(1)
end

for i = 0, 100 do
    cleanup()
    for y = 0, 50 do
        force()
    end
    forceUp()
    turtle.turnLeft()
    turtle.turnLeft()
    for y = 0, 50 do
        force()
    end
    forceDown()
    turtle.turnRight()
    force()
    turtle.turnRight()
end
