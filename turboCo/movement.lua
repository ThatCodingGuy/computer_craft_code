
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

function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
end
  
  

function coord(x, y, z) 
    return x.." "..y.." "..z
end

function split_coord(coord)
    result = {}
    for k, v in string.gmatch(coord, "%a+") do
        table.insert(result, 1, to_number(v))
    end
    return result[1], result[2], result[3]
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

function pathfind(start, destination, map, block_callback)
    -- This runs a BFS of path using map to find the path to take.
    -- It returns the nodes in order of visitation.

    if start == destination then
        return {}
    end

    local queue = {}
    local visited = {}
    table.insert(visited, start)

    local start_path = {}
    table.insert(start_path, start)
    table.insert(queue, start_path)
    

    while #queue > 0 do
        local path = table.remove(queue, 1)

        -- Check foward, backward, left, right, up, down
        local last_elem = path[#path]
        local x, y, z = split_coord(last_elem)

        local coords = {}
        table.insert(coords, coord(x+1, y, z))
        table.insert(coords, coord(x-1, y, z))
        table.insert(coords, coord(x, y+1, z))
        table.insert(coords, coord(x, y-1, z))
        table.insert(coords, coord(x, y, z+1))
        table.insert(coords, coord(x, y, z-1))

        for i=1, #coords, 1 do
            local target = coords[i]
            if map[target] and not visited[target] then
                local new_path = copy(path)
                table.insert(new_path, target)

                if target == destination then
                    return new_path
                end

                table.insert(queue, new_path)
            end
        end  
    end

    print("No path found in map.")
    return
end

function visit_path(path, block_callback)
    -- This function visits all points on a path.
    -- They must all be connected, and ordered in a way 
    -- where each cell is visitable going only through
    -- previously visited cells.
    
    local direction = figure_out_facing()
    if not direction then
        print("Could not determine facing")
        return
    end

    local current_x, current_y, current_z = gps.locate()
    local map = {}
    map[coord(current_x, current_y, current_z)] = 1

    while #path > 0 do
        local next = table.remove(path, 1)
        x, y, z = split_coord(next)
        print("Visiting "..x..", "..y..", "..z)
        map[coord(x, y, z)] = 1
    end
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
    
    local path = {}
    for x = start_x, final_x, x_offset do
        for z = start_z, final_z, z_offset do
            table.insert(path, coord(x, start_y, z))
        end
    end

    print("Path of length: "..#path)
    visit_path(path, block_callback)

    return final_x, final_z

end