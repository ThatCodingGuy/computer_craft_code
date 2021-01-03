local Logger = dofile("./gitlib/turboCo/logger.lua")
local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")
local movement = dofile("./gitlib/turboCo/movement.lua")
local inventory = dofile("/gitlib/carlos/inventory.lua")
local common_argument_parsers = dofile("./gitlib/turboCo/app/common_argument_parsers.lua")
local common_argument_definitions = dofile("./gitlib/turboCo/app/common_argument_definitions.lua")
local refuel = dofile("./gitlib/turboCo/client/refuel.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")

local number_def = common_argument_definitions.number_def
local boolean_def = common_argument_definitions.boolean_def
local starts_with = lua_helpers.starts_with
local ends_with = lua_helpers.ends_with

local logger = Logger.new()

local function is_tree_leaves(item_details)
    return starts_with(item_details.name, "minecraft:") and ends_with(item_details.name, "leaves")
end

local function is_tree_log(item_details)
    return starts_with(item_details.name, "minecraft:") and ends_with(item_details.name, "log")
end

local function is_sapling(item_details)
    return starts_with(item_details.name, "minecraft:") and ends_with(item_details.name, "sapling")
end

local function is_tree_block(item_details)
    return is_tree_leaves(item_details) or is_tree_log(item_details)
end

local function is_bone_meal(item_details)
    return starts_with(item_details.name, "minecraft:")
            and ((
            ends_with(item_details.name, "dye")
                    and item_details.damage == 15)
            or ends_with("bone_meal"))
end

local dig_tree_blocks = movement.dig_only_blocks_matching(is_tree_block)

local function drop_off_wood(facing, position, wood_dropoff_coordinates)
    local x, y, z = movement.split_coord(wood_dropoff_coordinates)
    facing, position = movement.navigate(position, facing, movement.coord(x, y, z))

    while inventory.countItemMatching(is_tree_log) > 0 do
        inventory.selectItemMatching(is_tree_log)
        turtle.dropDown()
    end
    return facing, position
end

local function remove_tree()
    -- Birch trees grow up to 7 high, with a width of 5.
    -- TODO: Define per-tree areas to be chopped down rather than assuming birch tree dimensions.

    -- Move the turtle to the corner of the tree area.
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnLeft()
    turtle.forward()
    turtle.forward()
    turtle.turnLeft()

    local function dig_through_column()
        for _ = 1, 4 do
            turtle.dig()
            turtle.forward()
        end
    end

    -- Move through and chop down the tree blocks.
    for _ = 1, 7 do
        for row = 1, 4 do
            dig_through_column()
            local turn
            if row % 2 == 0 then
                turn = turtle.turnRight
            else
                turn = turtle.turnLeft
            end
            turn()
            turtle.dig()
            turtle.forward()
            turn()
        end
        dig_through_column()
        turtle.digUp()
        turtle.up()
        turtle.turnLeft()
        turtle.turnLeft()
    end

    -- As the algorithm is currently written, the robot will always finish facing the opposite
    -- direction that it started facing. We'll undo the last rotation here so that the robot returns
    -- to facing the same direction as it started, therefore preventing any need to calculate the
    -- new direction the robot is facing.
    turtle.turnLeft()
    turtle.turnLeft()
end

local function generic_remove_tree(facing, position, adjacent)
    local tree_x, tree_y, tree_z = movement.split_coord(adjacent)
    local tree_area = {}
    for x = tree_x - 2, tree_x + 2 do
        for y = tree_y, tree_y + 7 do
            for z = tree_z - 2, tree_z + 2 do
                tree_area[movement.coord(x, y, z)] = 1
            end
        end
    end

    return movement.explore_area(tree_area, position, facing, dig_tree_blocks)
end

local function treeChop(position, adjacent, facing, direction, block_data, map)
    local start_position = position
    local start_facing = facing

    if turtle.getFuelLevel() < 1000 then
        refuel.refuel(position, facing)
    end

    local block_in_front = "empty block"
    if block_data ~= nil then
        block_in_front = block_data.name
    end
    logger.info("Currently looking at " .. block_in_front .. ".")
    if block_data == nil then
        logger.info("No block in front. Placing a sapling.")
        if inventory.selectItemMatching(is_sapling) then
            turtle.place()
        end
    elseif is_sapling(block_data) then
        logger.info("Sapling in front. Will place bone meal if any is present.")
        if inventory.selectItemMatching(is_bone_meal) then
            turtle.place()
        end
    elseif is_tree_log(block_data) then
        logger.info("Tree sprouted. Clearing the tree blocks.")

        if map.use_specialized_algorithm then
            remove_tree()
            -- We calculate the new position of the turtle after it cuts down the tree.
            position = movement.gps_locate()
        else
            facing, position = generic_remove_tree(facing, position, adjacent)
        end
        facing, position = drop_off_wood(facing, position, map.wood_dropoff_coordinates)
        facing, position = movement.navigate(position, facing, start_position)
        facing = movement.turn_to_face(facing, start_facing)

        -- If there's a torch in the turtle's inventory, then we want to place it back next to the\
        -- tree
        if inventory.countItemWithName("minecraft:torch") > 0 then
            turtle.forward()
            inventory.selectItemWithName("minecraft:torch")
            turtle.place()
            turtle.back()
        end
    end

    return facing, position
end

local function run()
    local argument_parser = common_argument_parsers.default_parser {
        number_def {
            short_name = "x",
            description = "The X position of the robot above the wood drop-off station.",
        },
        number_def {
            short_name = "y",
            description = "The Y position of the robot above the wood drop-off station.",
        },
        number_def {
            short_name = "z",
            description = "The Z position of the robot above the wood drop-off station.",
        },
        boolean_def {
            long_name = "use_specialized_algorithm",
            short_name = "a",
            description = "A boolean specifying whether to use a tree-chopper-specific algorithm "
                    .. "for digging the tree blocks or not. True by default, otherwise uses the "
                    .. "generic exploration algorithm in movement.lua.",
            default = true
        },
    }
    local parsed_arguments = argument_parser.parse(arg)
    if parsed_arguments.x == nil or parsed_arguments.y == nil or parsed_arguments.z == nil then
        logger.error("Please specify all of the x, y, and z coordinates of the wood drop-off "
                .. "station.")
        return
    end
    local wood_dropoff_coordinates = movement.coord(
            parsed_arguments.x, parsed_arguments.y, parsed_arguments.z)
    local use_specialized_algorithm = parsed_arguments.use_specialized_algorithm

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

    local tree_x = start_x
    local tree_y = start_y
    local tree_z = start_z
    if facing == "NORTH" then
        tree_z = tree_z - 1
    elseif facing == "SOUTH" then
        tree_z = tree_z + 1
    elseif facing == "EAST" then
        tree_x = tree_x + 1
    elseif facing == "WEST" then
        tree_x = tree_x - 1
    end

    local current = movement.coord(start_x, start_y, start_z)
    local tree_spot = movement.coord(tree_x, tree_y, tree_z)

    local event_handler = EventHandler.create()
    event_handler.scheduleRecurring(function()
        facing, current = movement.visit_adjacent(
                current,
                tree_spot,
                facing,
                treeChop,
                {
                    wood_dropoff_coordinates = wood_dropoff_coordinates,
                    use_specialized_algorithm = use_specialized_algorithm,
                })
    end, 10)
    event_handler.pullEvents()
end

run()
