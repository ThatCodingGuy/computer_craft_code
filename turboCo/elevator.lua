while true do
    local x, y, z = gps.locate()
    print("Press enter to go")
    local input = read()

    if y < 120 then
        local delta = 200 - y
        for i = 1, i < delta, 1 do
            turtle.up()
        end
    else
        local delta = y - 63
        for i = delta, i > 0, -1 do
            turtle.down()
        end
    end
end