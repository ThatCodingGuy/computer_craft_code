while true do
    local x, y, z = gps.locate()
    print("Press enter to go")
    local input = read()

    if y < 120 then
        local delta = 222 - y
        for i = 1, delta, 1 do
            turtle.up()
        end
    else
        local delta = y - 63
        for i = delta, 0, -1 do
            turtle.down()
        end
    end
end