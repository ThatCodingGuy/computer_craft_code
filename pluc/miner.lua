for i = 0, 100 do
    turtle.refuel(2)
    dropAllButOne(1)
    dropAllButOne(2)
    dropAllButOne(3)
    dropAllButOne(4)
    dropAllButOne(5)

    for y = 0, 50 do
        turtle.dig()
        turtle.forward()
    end
    turtle.digUp()
    turtle.up()
    turtle.turnLeft()
    turtle.turnLeft()
    for y = 0, 50 do
        turtle.dig()
        turtle.forward()
    end
    turtle.down()
    turtle.turnRight()
    turtle.dig()
    turtle.forward()
    turtle.turnRight()

end

function dropAllButOne(slot)
    turtle.select(slot)
    turtle.drop(turtle.getItemCount() - 1)
 end