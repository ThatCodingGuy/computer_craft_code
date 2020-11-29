
os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/carlos/inventory.lua")
os.loadAPI("/gitlib/turboCo/client/refuel.lua")

local tree_blocks = {}
table.insert(tree_blocks, "minecraft:birch_log")
table.insert(tree_blocks, "minecraft:birch_leaves")

local cut_tree = movement.dig_only_blocks(tree_blocks)

function treeChop(position, adjacent, facing, direction, block_data, map)
    local start_position = position
    local start_facing = facing

    if turtle.getFuelLevel() < 1000 then
        refuel.refuel(position, facing)
    end

    if not block_data.name then
        inventory.selectItemWithName("minecraft:birch_sapling")
        turtle.place()
    elseif block_data.name == "minecraft:birch_sapling" then
        inventory.selectItemWithName("minecraft:bonemeal")
        turtle.place()
    elseif block_data.name == "minecraft:birch_log" then
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

        facing, position = movement.explore_area(tree_area, position, facing, cut_tree)
        facing, position = movement.navigate(position, facing, start_position)
        facing = movement.turn_to_face(facing, start_facing)
    end

    print("wait")
    sleep(1)

    return facing, position
end

function run()
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
    local tree_spot = movement.coord(start_x + 1, start_y, start_z)
    local turtle_x, turtle_y, turtle_z = movement.split_coord(tree_spot)

    while true do
        facing, current = movement.visit_adjacent(current, tree_spot, facing, treeChop, {})
    end
end

local dropoff = movement.coord(-93, 73, 393)
run(dropoff)

-- -99 65 431
-- -94 64 425