local events = dofile("./gitlib/turboCo/event/events.lua")
local inventory = dofile("./gitlib/carlos/inventory.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")

--- Controls a turtle to feed whatever items it has in its hands to animals below it.
local COW_BREED_COOLDOWN = 60 * 5.5 -- 5 minutes 30 seconds
local FOOD_CHECK_PERIOD = 30 -- 30 seconds
local FOOD_LABEL = "minecraft:wheat"
local DELTAS_TO_STOP_FEEDING = 10
local logger = Logger.new()
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
    if not has_food() then
        logger.warn("Waiting for food before feeding cows.")
        wait_for_food()
    end
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

check_for_more_food = function()
    logger.warn("Ran out of food.")
    wait_for_food()
    inform_food_strategy = detect_food_outages
end

detect_food_outages = function()
    logger.info("Detected food.")
    while has_food() do
        events.wait_for_inventory_change()
    end
    inform_food_strategy = check_for_more_food
end

local function inform_food()
    while true do
        inform_food_strategy()
    end
end

local function run()
    Logger.log_level_filter = Logger.LoggingLevel.INFO
    local feed_cows_task = RecurringTask.new(COW_BREED_COOLDOWN, feed_cows)
    if has_food() then
        inform_food_strategy = detect_food_outages
    else
        inform_food_strategy = check_for_more_food
    end
    parallel.waitForAll(inform_food, feed_cows_task.run)
end

run()
