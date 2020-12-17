local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local inventory = dofile("./gitlib/carlos/inventory.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")

--- Controls a turtle to feed whatever items it has in its hands to animals below it.
local COW_BREED_COOLDOWN = 60 * 5.5 -- 5 minutes 30 seconds
local FOOD_CHECK_PERIOD = 30 -- 30 seconds
local FOOD_LABEL = "minecraft:wheat"
local DELTAS_TO_STOP_FEEDING = 10
local logger = Logger.new()

local function get_food_count()
    return inventory.countItemWithName(FOOD_LABEL)
end

local function wait_for_food()
    if get_food_count() > 0 then
        return
    end

    logger.info("Ran out of food. Waiting for more...")
    while get_food_count() <= 0 do
        os.sleep(FOOD_CHECK_PERIOD)
    end
end

local function feed_cows()
    if get_food_count() <= 0 then
        logger.warn("Should have fed cows, but no food was available. Abandoning.")
        return
    end

    logger.info("Feeding cows.")
    local failed_placements = 0
    while failed_placements < DELTAS_TO_STOP_FEEDING do
        inventory.selectItemWithName(FOOD_LABEL)
        if turtle.placeDown() then
            failed_placements = failed_placements + 1
        else
            failed_placements = 0
        end
    end
    wait_for_food()
end

local function run()
    Logger.log_level_filter = Logger.LoggingLevel.INFO
    RecurringTask.new(COW_BREED_COOLDOWN, feed_cows, EventHandler.create()).run()
end

run()
