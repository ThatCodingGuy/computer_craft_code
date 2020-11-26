
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
-- Prototype : block_callback(block_data, current, adjacent, facing, direction, map)
-- It must maintain the facing it started with, and the turtle
-- must stop where it started, or in the block it was called for.
-- It returns true if it moved, false if it didn't
--
-- block_data is the block adjacent to the robot
-- current is the current coord of the robot
-- adjacent is the coord of the block
-- facing is the direction the robot is facing
-- direction is the direction the block is in relative to the robot
-- map is the known explored area so far



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
        local valid = fun(x[i])
        if valid then
            table.insert(results, x[i])
        end
    end
    return results
end

function filter_map_keys(x, fun)
    local results = {}
    for k, v in pairs(x) do
        local valid = fun(k, v)
        if valid then
            results[k] = x[k]
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

function get_empty_slot_count()
    local count = 0
    for i = 1, 16, 1 do
        local x = turtle.getItemCount(i)
        if x == 0 then
            count = count + 1
        end
    end
    return count
end

function empty_inventory()
    local count = 0
    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.dropDown()
    end
    return count
end

function refuel()
    turtle.suckUp(64)
    turtle.refuel()
end

local directions = {}
directions[NORTH] = EAST
directions[EAST] = SOUTH
directions[SOUTH] = WEST
directions[WEST] = NORTH


function turn_to_face(current, target)
    if current == target then
        return
    end

    if current == NORTH and target == WEST then
        turtle.turnLeft()
        return
    end

    if current == WEST and target == SOUTH then
        turtle.turnLeft()
        return
    end

    if current == SOUTH and target == EAST then
        turtle.turnLeft()
        return
    end

    if current == EAST and target == NORTH then
        turtle.turnLeft()
        return
    end

    while current ~= target do
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

    return false
end


function force_dig(block_data, current, adjacent, facing, direction)
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

function no_dig(block_data, current, adjacent, facing, direction)
    -- Never try to break a block
    return false
end

function visit_adjacent(current, adjacent, facing, block_callback, map)
    -- This moves the robot to the adjacent coord specified
    -- It returns the facing and position. It will call block_callback if there is a block
    -- then return.
    --  map is optional, just pass it in if the block_callback needs to use a map
    local current_x, current_y, current_z = split_coord(current)
    local adjacent_x, adjacent_y, adjacent_z = split_coord(adjacent)

    if current_x == adjacent_x and current_y == adjacent_y and current_z == adjacent_z then
        return facing, current
    end
    
    if current_y - adjacent_y == 1 then
        found, block_data = turtle.inspectDown()
        if found then
            local moved = block_callback(block_data, current, adjacent, facing, DOWN, map)
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
        found, block_data = turtle.inspectUp()
        if found then
            local moved = block_callback(block_data, current, adjacent, facing, UP, map)
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

    found, block_data = turtle.inspect()
    if found then
        local moved = block_callback(block_data, current, adjacent, facing, FORWARD, map)
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

function visit(position, target, facing, block_callback, walkable_map)
    -- This moves the robot the coord specific
    -- It returns the facing and position. 
    -- If we're besides the node just visit it
    if distance(position, target) > 1 then
        -- If we're not, find an adjacent empty block we've visisted,
        -- then go there before digging it.
        local target_adjacent = get_adjacent_blocks(target)
        local function is_valid(x) return walkable_map[x] end
        target_adjacent = filter(target_adjacent, is_valid)

        local adjacent_block = target_adjacent[1]

        -- Force move to the correct spot besides node to be adjacent
        -- Call the callback for any blocks encountered, and force dig if they're
        -- Still there after. 
        local path = pathfind_with_map(position, target, walkable_map) 
        facing, position = follow_path(position, path, facing, block_callback, walkable_map)
        
    end
    facing, position = visit_adjacent(position, target, facing, block_callback, walkable_map)
    return facing, position
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


function follow_path(position, path, facing, block_callback, walkable_map)
    for i = 1, #path, 1 do
        facing, position = visit_adjacent(position, path[i], facing, block_callback, walkable_map)
        if not node == position then
            facing, position = visit_adjacent(position, path[i], facing, force_dig)
        end
    end
    return facing, position
end


function explore_area(area, block_callback)
    -- This runs a BFS of path using map to find the path to take.
    -- It returns the nodes in order of visitation.

    local start_x, start_y, start_z = gps.locate()
    if not start_x then
        error("Could not connect to gps")
        return
    end


    local facing = figure_out_facing()
    if not facing then
        error("Could not determine facing")
        return
    end

    local position = coord(start_x, start_y, start_z)

    local explored = {}
    explored[position] = EMPTY

    local to_explore = {}
    local adjacent = get_adjacent_blocks(position)

    local function is_in_area(x) return area[x] end
    local function is_not_explored(x) return not explored[x] end
    adjacent = filter(adjacent, is_in_area)
    adjacent = filter(adjacent, is_not_explored)

    for i=1, #adjacent, 1 do
        table.insert(to_explore, adjacent[i])
    end

    while #to_explore > 0 do
        local node = table.remove(to_explore, 1)
        local function is_empty(x) return explored[x] == EMPTY end
        local walkable_map = filter_map_keys(explored, is_empty)

        if not explored[node] then
            facing, position = visit(position, node, facing, block_callback, walkable_map)
            explored[position] = EMPTY

            if node == position then
                explored[node] = EMPTY
                local node_adjacent = get_adjacent_blocks(position)
                local function is_in_area(x) return area[x] end
                local function is_not_explored(x) return not explored[x] end

                node_adjacent = filter(node_adjacent, is_in_area)
                node_adjacent = filter(node_adjacent, is_not_explored)
                for i=1, #node_adjacent, 1 do
                    table.insert(to_explore, 1, node_adjacent[i])
                end
            else 
                explored[node] = BLOCK
            end
        end
    end

    print("Done exploring")
    return
end

function navigate(current, facing, destination, map_NOT_USED_RIGHT_NOW)
    -- FIXME: A path needs to exist, or the robot will forever explore

    local visited = {}
    visited[current] = EMPTY

    -- distance_map is a map of distance -> list of known blocks at that distance.
    local distance_map = {}
    local adjacent = get_adjacent_blocks(current)
    
    for i=1, #adjacent, 1 do
        local distance = distance(adjacent[i], destination)
        if not distance_map[distance] then
            distance_map[distance] = {}
        end

        table.insert(distance_map[distance], adjacent[i])
    end

    while true do
        -- At destination, return
        if current == destination then
            return facing, current
        end

        local function no_elems(k, v) return #v > 0 end
        distance_map = filter_map_keys(distance_map, no_elems)

        -- Find the shortest distance.
        local distances = {}
        for distance in pairs(distance_map) do table.insert(distances, distance) end
        table.sort(distances)
        local shortest = distances[1]

        local candidates = distance_map[shortest]
        local closest_index = 1
        local closest_distance = distance(current, candidates[closest_index])

        for i=1, #candidates, 1 do
            local candidate_distance = distance(current, candidates[i])
            if candidate_distance < closest_distance then
                closest_index = i
                closest_distance = candidate_distance
            end
        end

        -- At this point, closest is the next block we should visit.
        -- remove closest from the array
        local closest = candidates[closest_index]
        table.remove(distance_map[shortest], closest_index)

        local function is_empty(x) return visited[x] == EMPTY end
        local walkable_map = filter_map_keys(visited, is_empty)

        facing, current = visit(current, closest, facing, no_dig, walkable_map)
        if closest == current then
            
            visited[closest] = EMPTY
            local adjacent = get_adjacent_blocks(current)
            local function is_not_visited(x) return not visited[x] end
            adjacent = filter(adjacent, is_not_visited)

            for i=1, #adjacent, 1 do
                local distance = distance(adjacent[i], destination)
                if not distance_map[distance] then
                    distance_map[distance] = {}
                end
                table.insert(distance_map[distance], adjacent[i])
            end
        else 
            visited[closest] = BLOCK
        end
    end

    error("#unreachable")
end
-- dropoff_coords is the slot above the chest
function keepChurning(dropoff_coords, block_callback)

    -- TODO: Add clear nav + exit point
    local function wrapped(block_data, current, adjacent, facing, direction, map)
        local chest_distance = distance(current, dropoff_coords)
        if get_empty_slot_count() <= 1 or turtle.getFuelLevel() < chest_distance * 5 then
            print("heading to dropoff")
            local start_position = current
            local start_facing = facing
            facing, current = navigate(current, facing, dropoff_coords, {})
            empty_inventory()
            refuel()
            print("back to work")
            facing, current = navigate(current, facing, start_position, {})
            turn_to_face(facing, start_facing)
            facing = start_facing
        end

        return block_callback(block_data, current, adjacent, facing, direction, map)
    end
    return wrapped 
end


function scan_area(width, depth, height, block_callback)
    -- +width to the right, -width to the left
    -- +depth forward, -depth backwards
    -- +height up, -height down
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
    local final_y = start_y + height
    print("Scanning from "..start_x..","..start_z.." to "..final_x..","..final_z)
    
    x_offset = 1
    z_offset = 1
    y_offset = 1
    if start_x > final_x then
        x_offset = -1
    end   

    if start_z > final_z then
        z_offset = -1
    end

    if start_y > final_y then
        y_offset = -1
    end
    
    local area = {}
    for x = start_x, final_x, x_offset do
        for z = start_z, final_z, z_offset do
            for y = start_y, final_y, y_offset do
                area[coord(x, y, z)] = 1
            end
        end
    end

    explore_area(area, block_callback)
end