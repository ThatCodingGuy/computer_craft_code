
-- By convention, x/y/z are relative to you.
-- x to the right, -x to the left.
-- z is in front, -y is behind.
-- y is up, -z is down.

EAST = "EAST"
WEST = "WEST"
NORTH = "NORTH"
SOUTH = "SOUTH"

local UNVISITED = 1
local EMPTY = 2
local BLOCK = 3


function coord(x, y, z) 
    return tostring(x).."_"..tostring(y).."_"..tostring(z)
end

function figure_out_facing()
    -- TODO: Handle case when covered in gravel/sand.

    local start_position_x, start_position_y, start_position_z = gps.locate()
    if not start_position_x then
        print("GPS not connected.")
        return nil
    end

    for i=0, 4, 1 do
        local success = turtle.forward()
        local new_position_x, new_position_y, new_position_z = gps.locate()

        if success then 
            if new_position_x > start_position_x then
                turtle.back()

                for j = 0, i-1, 1 do 
                    turtle.turnLeft()
                end
                return WEST
            end

            if new_position_x < start_position_x then
                turtle.back()

                for j = 0, i-1, 1 do 
                    turtle.turnLeft()
                end
                return EAST
            end

            if new_position_z > start_position_z then
                turtle.back()

                for j = 0, i-1, 1 do 
                    turtle.turnLeft()
                end
                return NORTH
            end

            if new_position_z < start_position_z then
                turtle.back()

                for j = 0, i-1, 1 do 
                    turtle.turnLeft()
                end
                return SOUTH
            end
        end

        turtle.turnRight()
    end

    print("Robot can't move, refuel or unstuck")
    return
end


function scan_area(width, depth, block_callback)
    -- +width to the right, -width to the left
    -- +depth forward, -depth backwards
    -- block_callback is called with block data whenever a collision occurs.

    local direction = figure_out_facing()
    if not direction then
        print("Could not determine facing")
        return
    end

    local start_x, start_y, start_z = gps.locate()
    if not start_x then
        print("Could not connect to gps")
        return
    end

    local x_total = 0
    local z_total = 0
    if direction == NORTH then
        x_total = -width
        z_total = depth
    end

    if direction == SOUTH then
        x_total = width
        z_total = -depth
    end

    if direction == EAST then
        x_total = -depth
        z_total = -width
    end

    if direction == WEST then
        x_total = depth
        z_total = width
    end

    local final_x = start_x + x_total
    local final_z = start_z + z_total
    print("Scanning from "..start_x..","..start_z.." to "..final_x..","..final_z)
    
    x_offset = 1
    z_offset = 1
    if start_x > final_x then
        x_offset = -1
    end   

    if start_z > final_z then
        z_offset = -1
    end
    
    local area = {}
    for x = start_x, final_x, x_offset do
        for z = start_z, final_z, z_offset do
            table.insert(area, coord(x, start_y, z))
        end
    end

    print(area[0])
    print(area[1])

    return final_x, final_z

end