
-- By convention, x/y/z can either be relative or global
--
-- Relative
-- x to the right, -x to the left.
-- z is in front, -y is behind.
-- y is up, -z is down.
--
-- Global 
-- West is +x
-- East is -x
-- Up is +y
-- Down is -y
-- North is +z
-- South is -z
--
--
-- Some function expect a block callback.
-- block_callback(block_data, direction)
-- It must maintain the facing it started with, and the turtle
-- must stop where it started, or in the block it was called for.
-- It returns true if it moved, false if it didn't

EAST = "EAST"
WEST = "WEST"
NORTH = "NORTH"
SOUTH = "SOUTH"

FORWARD = "FORWARD"
UP = "UP"
DOWN = "DOWN"

local UNVISITED = 1
local EMPTY = 2
local BLOCK = 3

local walkable_block = {}


function filter(x, fun)
    local results = {}
    for i=1, #x, 1 do
        if fun(x[i]) then
            table.insert(results, x[i])
        end
    end

    return results
end

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

function split_coord(coords)
    result = {}
    for v in string.gmatch(coords, "(-?%w+)") do
        table.insert(result, tonumber(v))
    end
    return result[1], result[2], result[3]
end

function distance(coord1, coord2)
    local x1, y1, z1 = split_coord(coord1)
    local x2, y2, z2 = split_coord(coord2)
    return math.abs(x2-x1) + math.abs(y2-y1) + math.abs(z2-z1)
end


function turn_to_face(current, target)
    local directions = {}
    directions[NORTH] = EAST
    directions[EAST] = SOUTH
    directions[SOUTH] = WEST
    directions[WEST] = NORTH

    while not current == target do
        turtle.turnRight()
        current = directions[current]
    end
end

function figure_out_facing()
    -- TODO: Handle case when covered in gravel/sand.

    local start_position_x, start_position_y, start_position_z = gps.locate()
    if not start_position_x then
        error("GPS not connected.")
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

    error("Robot can't move, refuel or unstuck")
    return
end

function pathfind_with_map(start, destination, map)
    -- This runs a BFS of path using map to find the path to take.
    -- It returns the nodes in order of visitation.

    if start == destination then
        return {}
    end

    local queue = {}
    local visited = {}
    visited[start] = 1

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
            
            if target == destination then
                local new_path = copy(path)
                table.insert(new_path, target)
                return new_path
            end

            if map[target] and not visited[target] then
                local new_path = copy(path)
                table.insert(new_path, target)
                visited[target] = 1
                table.insert(queue, new_path)
            end
        end  
    end

    error("No path found in map.")
    return
end

function force_dig(block_data, direction)
    local success = false
    if direction == UP then
        while not success do
            turtle.digUp()
            success = turtle.up()
        end
        return true
    elseif direction == DOWN then
        while not success do
            turtle.digDown()
            success = turtle.down()
        end
        return true
    elseif direction == FORWARD then
        while not success do
            turtle.dig()
            success = turtle.forward()
        end
        return true
    else
        error("no direction passed to force_dig")
    end

end

function visit_adjacent(current, adjacent, facing, block_callback)
    -- This moves the robot to the adjacent coord specified
    -- It returns the facing and position. It will call block_callback if there is a block
    -- then return.
    local current_x, current_y, current_z = split_coord(current)
    local adjacent_x, adjacent_y, adjacent_z = split_coord(adjacent)

    if current_x == adjacent_x and current_y == adjacent_y and current_z == current_z then
        return facing
    end
    
    if current_y - adjacent_y == 1 then
        found, block_data = turtle.inspectDown()
        if found then
            local moved = block_callback(block_data, DOWN)
            if moved then 
                return facing, adjacent
            end
            return facing, current
        else
            local moved = turtle.down()
            if moved then
                return facing, adjacent
            else
                return facing, current
            end
        end
    end
    if current_y - adjacent_y == -1 then
        if found then
            local moved = block_callback(block_data, UP)
            if moved then 
                return facing, adjacent
            end
            return facing, current
        else
            local moved = turtle.up()
            if moved then
                return facing, adjacent
            else
                return facing, current
            end
        end
    end

    local found = false
    if current_x - adjacent_x == 1 then
        turn_to_face(facing, EAST)
        facing = EAST
        found = true
    end
    if current_x - adjacent_x == -1 then
        turn_to_face(facing, WEST)
        facing = WEST
        found = true
    end

    if current_z - adjacent_z == 1 then
        turn_to_face(facing, SOUTH)
        facing = SOUTH
        found = true
    end
    if current_z - adjacent_z == -1 then
        turn_to_face(facing, NORTH)
        facing = NORTH
        found = true
    end

    if not found then
        error("blocks not adjacent, error")
    end

    blockExists, blockData = turtle.inspect()
    if blockExists then
        local moved = block_callback(blockData, FORWARD)
        if moved then 
            return facing, adjacent
        end
        return facing, current
    else
        local moved = turtle.forward()
        if moved then
            return facing, adjacent
        else
            return facing, current
        end
    end
end

function get_adjacent_blocks(position)
    local x, y, z = split_coord(position)
    local coords = {}
    table.insert(coords, coord(x+1, y, z))
    table.insert(coords, coord(x-1, y, z))
    table.insert(coords, coord(x, y+1, z))
    table.insert(coords, coord(x, y-1, z))
    table.insert(coords, coord(x, y, z+1))
    table.insert(coords, coord(x, y, z-1))
    return coords
end


function explore_area(area, block_callback)
    -- This runs a BFS of path using map to find the path to take.
    -- It returns the nodes in order of visitation.

    print("Explore area")
    local start_x, start_y, start_z = gps.locate()
    if not start_x then
        error("Could not connect to gps")
        return
    end

    print("Facing")

    local facing = figure_out_facing()
    if not facing then
        error("Could not determine facing")
        return
    end

    local position = coord(start_x, start_y, start_z)

    local explored = {}
    explored[position] = EMPTY

    local to_explore = {}
    print("Pre-adjacent")
    local adjacent = get_adjacent_blocks(position)
    print("Adjacent "..#adjacent)
    local function is_in_area(x) return area[x] end
    local function is_not_explored(x) return not explored[x] end
    adjacent = filter(adjacent, is_in_area)
    print("Area "..#adjacent)
    adjacent = filter(adjacent, is_not_visisted)
    print("Visited "..#adjacent)

    
    for i=1, #adjacent, 1 do
        table.insert(to_explore, adjacent[i])
    end

    
    print("Exploring "..#to_explore)

    while #to_explore > 0 do
        local node = table.remove(to_explore, 1)

        if not explored[node] then
            print("Pathfinding")
            -- If we're besides the node just visit it
            if distance(position, node) > 1 then
                -- If we're not, find an adjacent empty block we've visisted,
                -- then go there before digging it.
                local node_adjacent = get_adjacent_blocks(node)
                local function is_empty(x) return explored[x] == EMPTY end
                node_adjacent = filter(node_adjacent, is_explored)
                if not #node_adjacent then
                    -- Should be impossible to hit this
                    error("no adjacent empty nodes to target in explored")
                    return
                end


                -- Force move to the correct spot besides node to be adjacent
                -- Call the callback for any blocks encountered, and force dig if they're
                -- Still there after. 
                local walkable_map = filter(explored, is_empty)
                local path = pathfind_with_map(current, node_adjacent[1], walkable_map) 
                for i = 1, #path, 1 do
                    facing, position = visit_adjacent(position, node, facing, block_callback)
                    if not node == position then
                        visit_adjacent(position, node, facing, force_dig)
                    end
                end
            end

            print("Adjacent")

            facing, position = visit_adjacent(position, node, facing, block_callback)
            explored[position] = EMPTY

            if not node == position then
                explored[node] = EMPTY
                local node_adjacent = get_adjacent_blocks(position)
                local function is_in_area(x) return area[x] end
                local function is_not_explored(x) return not explored[x] end

                node_adjacent = filter(node_adjacent, is_in_area)
                node_adjacent = filter(node_adjacent, is_not_visisted)
                for i = 1, #node_adjacent, 1 do
                    table.insert(to_explore, node_adjacent[i])
                end
            else 
                explored[node] = BLOCK
            end
        end
    end

    print("Done exploring")
    return
end


function scan_area(width, depth, block_callback)
    -- +width to the right, -width to the left
    -- +depth forward, -depth backwards
    -- block_callback is called with block data whenever a collision occurs.

    local direction = figure_out_facing()
    if not direction then
        error("Could not determine facing")
        return
    end

    local start_x, start_y, start_z = gps.locate()
    if not start_x then
        error("Could not connect to gps")
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

    explore_area(area, block_callback)
end