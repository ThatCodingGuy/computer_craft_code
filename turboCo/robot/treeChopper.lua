local Logger = dofile("./gitlib/turboCo/logger.lua")
local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")
local movement = dofile("./gitlib/turboCo/movement.lua")
local inventory = dofile("/gitlib/carlos/inventory.lua")
local common_argument_parsers = dofile("./gitlib/turboCo/app/common_argument_parsers.lua")
local common_argument_definitions = dofile("./gitlib/turboCo/app/common_argument_definitions.lua")
local refuel = dofile("./gitlib/turboCo/client/refuel.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")

local number_def = common_argument_definitions.number_def
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

local cut_tree = movement.dig_only_blocks_matching(function(item_details)
    return is_tree_log(item_details) or is_tree_leaves(item_details)
end)

local function drop_off_wood(facing, position, wood_dropoff_coordinates)
    local x, y, z = movement.split_coord(wood_dropoff_coordinates)
    facing, position = movement.navigate(position, facing, movement.coord(x, y, z))

    while inventory.countItemMatching(is_tree_log) > 0 do
        inventory.selectItemMatching(is_tree_log)
        turtle.placeDown()
    end
    return facing, position
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
        inventory.selectItemMatching(is_sapling)
        turtle.place()
    elseif is_sapling(block_data) then
        logger.info("Sapling in front. Will place bone meal if any is present.")
        inventory.selectItemWithName("minecraft:bone_meal")
        turtle.place()
    elseif is_tree_log(block_data) then
        logger.info("Tree sprouted. Clearing the tree blocks.")
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
        facing, position = drop_off_wood(facing, position, map.wood_dropoff_coordinates)
        facing, position = movement.navigate(position, facing, start_position)
        facing = movement.turn_to_face(facing, start_facing)
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
    }
    local parsed_arguments = argument_parser.parse(arg)
    if parsed_arguments.x == nil or parsed_arguments.y == nil or parsed_arguments.z == nil then
        logger.error("Please specify all of the x, y, and z coordinates of the wood drop-off "
                .. "station.")
        return
    end
    local wood_dropoff_coordinates = movement.coord(
            parsed_arguments.x, parsed_arguments.y, parsed_arguments.z)

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
                { wood_dropoff_coordinates = wood_dropoff_coordinates })
    end, 10)
    event_handler.pullEvents()
end

run()
