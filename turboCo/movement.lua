
-- By convention, x/y/z are relative to you.
-- x to the right, -x to the left.
-- y is in front, -y is behind.
-- z is up, -z is down.

EAST = "EAST"
WEST = "WEST"
NORTH = "NORTH"
SOUTH = "SOUTH"

function figure_out_facing()
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
                return EAST
            end

            if new_position_x < start_position_x then
                return WEST
            end

            if new_position_y > start_position_y then
                return NORTH
            end

            if new_position_y < start_position_y then
                return SOUTH
            end
        end
    end

    print("Robot can't move, refuel or unstuck")
    return
end
