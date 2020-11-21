
-- By convention, x/y/z are relative to you.
-- x to the right, -x to the left.
-- z is in front, -y is behind.
-- y is up, -z is down.

EAST = "EAST"
WEST = "WEST"
NORTH = "NORTH"
SOUTH = "SOUTH"


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

                for j = 0, i, 1 do 
                    turtle.turnLeft()
                end
                return WEST
            end

            if new_position_x < start_position_x then
                turtle.back()

                for j = 0, i, 1 do 
                    turtle.turnLeft()
                end
                return EAST
            end

            if new_position_z > start_position_z then
                turtle.back()

                for j = 0, i, 1 do 
                    turtle.turnLeft()
                end
                return NORTH
            end

            if new_position_z < start_position_z then
                turtle.back()

                for j = 0, i, 1 do 
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
