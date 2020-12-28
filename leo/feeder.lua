local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local events = dofile("./gitlib/turboCo/event/events.lua")
local inventory = dofile("./gitlib/carlos/inventory.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")
local common_argument_definitions = dofile("./gitlib/turboCo/app/common_argument_definitions.lua")
local common_argument_parsers = dofile("./gitlib/turboCo/app/common_argument_parsers.lua")

local number_def = common_argument_definitions.number_def

--- Controls a turtle to feed whatever items it has in its hands to animals below it.
local COW_BREED_COOLDOWN_DEFAULT = 60 * 5.5 -- 5 minutes 30 seconds
local CHECK_FOOD_COOLDOWN_DEFAULT = 1 -- 1 second
local FOOD_LABEL = "minecraft:wheat"
local DELTAS_TO_STOP_FEEDING = 10
local cow_breed_cooldown = COW_BREED_COOLDOWN_DEFAULT
local check_food_cooldown = CHECK_FOOD_COOLDOWN_DEFAULT
local logger = Logger.new()
local event_handler = EventHandler.create()
local inform_food_strategy
local check_for_more_food
local detect_food_outages

local function has_food()
    local food_left = inventory.countItemWithName(FOOD_LABEL)
    logger.debug("There is ", food_left, " food left.")
    return food_left > 0
end

local function wait_for_food()
    while not has_food() do
        events.wait_for_inventory_change()
    end
end

local function feed_cows()
    logger.info("Feeding cows.")
    local failed_placements = 0
    while failed_placements < DELTAS_TO_STOP_FEEDING do
        inventory.selectItemWithName(FOOD_LABEL)
        if turtle.placeDown() then
            failed_placements = 0
            logger.debug("Succeeded in feeding.")
        else
            failed_placements = failed_placements + 1
            logger.debug("Failed to feed ", failed_placements, " times.")
        end
    end
    logger.debug("Done feeding.")
end

local function attempt_to_feed_cows()
    if has_food() then
        feed_cows()
        return
    end
    logger.warn("Waiting for food before feeding cows.")

    local handle_id
    handle_id = event_handler.addHandle("turtle_inventory", function()
        if has_food() then
            event_handler.removeHandle(handle_id)
            feed_cows()
        end
    end)
end

check_for_more_food = function()
    logger.warn("Ran out of food.")
    local handle_id
    handle_id = event_handler.addHandle("turtle_inventory", function()
        if has_food() then
            event_handler.removeHandle(handle_id)
            detect_food_outages()
        end
    end)
end

detect_food_outages = function()
    logger.info("Detected food.")
    local handle_id
    handle_id = event_handler.addHandle("turtle_inventory", function()
        if not has_food() then
            event_handler.removeHandle(handle_id)
            check_for_more_food()
        end
    end)
end

local function run()
    local argument_parser = common_argument_parsers.default_parser {
        number_def {
            long_name = "breed_cooldown",
            short_name = "c",
            description = "The amount of time to wait before attempting to feed the cows again.",
        }
    }
    local parsed_arguments = argument_parser.parse(arg)
    if parsed_arguments.breed_cooldown ~= nil then
        cow_breed_cooldown = parsed_arguments.breed_cooldown
    end
    logger.info(
            "Will feed cows every "
                    .. cow_breed_cooldown
                    .. " seconds and check food every "
                    .. check_food_cooldown
                    .. " seconds.")

    if has_food() then
        detect_food_outages()
    else
        check_for_more_food()
    end
    attempt_to_feed_cows()
    event_handler.scheduleRecurring(attempt_to_feed_cows, cow_breed_cooldown)
    event_handler.pullEvents()
end

run()
