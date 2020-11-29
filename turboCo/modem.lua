

local directions = {}
table.insert(directions, "front")
table.insert(directions, "back")
table.insert(directions, "left")
table.insert(directions, "right")
table.insert(directions, "top")
table.insert(directions, "bottom")

function openModems()
    for i = 1, #directions, 1 do
        if peripheral.getType(directions[i]) == "modem" then
            rednet.open(directions[i])
        end
    end
end

function closeModems()
    for i = 1, #directions, 1 do
        if peripheral.getType(directions[i]) == "modem" then
            rednet.close(directions[i])
        end
    end
end