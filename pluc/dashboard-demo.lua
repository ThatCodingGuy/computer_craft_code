os.loadAPI("/gitlib/turboCo/dashboard.lua")

while true do
    while turtle.inspect() do
        dashboard.alert("Oh noes! There's a block blocking me!")
        sleep(5)
    end
    turtle.forward()
    turtle.turnRight()
    dashboard.updateRobot()
end
