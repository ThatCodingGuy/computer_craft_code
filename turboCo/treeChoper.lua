
os.loadAPI("/gitlib/turboCo/movement.lua")

function treeChop(block_data, position, adjacent, facing, direction)
    print("Chop tree")
    print(position)
    print(adjacent)
    local start_position = position
    local start_facing = facing

    print(block_data.name)

    if block_data.name == "minecraft:birch_log" then
        -- Trees grow up to 7 high, with a width of 5
        -- Tree is in adjacent

        print("here")
        local tree_x, tree_y, tree_z = movement.split_coord(adjacent)
        print("wut")

        local tree_area = {}
        for x = tree_x - 2, tree_x + 2, 1 do
            for z = tree_z - 2, tree_z + 2, 1 do
                for y = tree_z, tree_z+7, 1 do
                    print(coord(x, y, z))
                    tree_area[coord(x, y, z)] = 1
                end
            end
        end

        print("Set up area")

        facing, position = movement.explore_area(tree_area, position, facing, movement.force_dig)
        facing, position = movement.navigate(position, facing, start_position)
        movement.turn_to_face(facing, start_facing)
        facing = start_facing
    end

    print("wait")
    sleep(1)

    return false
end

function run(refuel_coords, tree_spot)
    -- Slot 1 is for saplings

    local facing = movement.figure_out_facing()
    if not facing then
        error("Could not determine facing")
        return
    end

    local start_x, start_y, start_z = gps.locate()
    if not start_x then
        error("Could not connect to gps")
        return
    end
    local current = movement.coord(start_x, start_y, start_z)


    -- We always position ourselves to the south
    local turtle_x, turtle_y, turtle_z = movement.split_coord(tree_spot)
    local turtle_spot = movement.coord(turtle_x + 1, turtle_y, turtle_z)


    facing, current = movement.navigate(current, facing, refuel_coords)
    movement.refuel()
    facing, current = movement.navigate(current, facing, turtle_spot)

    while true do
        facing, current = movement.visit_adjacent(current, tree_spot,  facing, treeChop)
    end
end

refuel_x, refuel_y, refuel_z, tree_spot_x, tree_spot_y, tree_spot_z = ...
run(movement.coord(refuel_x, refuel_y, refuel_z), movement.coord(tree_spot_x, tree_spot_y, tree_spot_z))