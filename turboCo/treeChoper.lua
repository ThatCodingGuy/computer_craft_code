
os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/carlos/inventory.lua")

function treeChop(position, adjacent, facing, direction, block_data, map)
    local start_position = position
    local start_facing = facing


    if block_data.name == "minecraft:birch_log" then
        -- Trees grow up to 7 high, with a width of 5
        -- Tree is in adjacent

        local tree_x, tree_y, tree_z = movement.split_coord(adjacent)
        local tree_area = {}
        for x = tree_x - 2, tree_x + 2, 1 do
            for z = tree_z - 2, tree_z + 2, 1 do
                for y = tree_y, tree_y + 7, 1 do
                    tree_area[movement.coord(x, y, z)] = 1
                end
            end
        end

        print("Set up area")
        facing, position = movement.explore_area(tree_area, position, facing, movement.force_dig)
        print("Done exploring: "..facing.." "..position)
        facing, position = movement.navigate(position, facing, start_position)
        facing = movement.turn_to_face(facing, start_facing)


        inventory.selectItemWithName("minecraft:birch_sapling")
        turtle.place()
    end

    print("wait")
    sleep(1)

    return facing, position
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
        facing, current = movement.visit_adjacent(current, tree_spot, facing, treeChop, {})
    end
end

refuel_x, refuel_y, refuel_z, tree_spot_x, tree_spot_y, tree_spot_z = ...
run(movement.coord(refuel_x, refuel_y, refuel_z), movement.coord(tree_spot_x, tree_spot_y, tree_spot_z))

-- -95 65 431
-- -94 64 425