--- Contains helpers for scheduling tasks on events as they're received.

local Logger = dofile("./gitlib/turboCo/logger.lua")
local logger = Logger.new()

local function pull_events(event_type)
    while true do
        local event_data = {os.pullEvent()}
        logger.debug("Pulled event data: " .. event_data[1])
        if event_data[1] == event_type then
            return event_data
        end
        os.queueEvent(unpack(event_data))
    end
end

--- Waits for an event of type `event_type` to occur and then calls `callback`.
-- `callback` is expected to be able to handle whatever event parameters are passed to it.
local function listen(callback, event_type)
    callback(pull_events(event_type))
end

--- Waits for a turtle inventory change event to occur.
local function wait_for_inventory_change()
    listen(function()
    end, "turtle_inventory")
end

--- Schedules `callback` to run after `delay` seconds, once the program blocks on the returned
-- handler.
-- @param callback The parameterless function to call when the timer is triggered.
-- @return A handler that should be called once the current coroutine is ready to be blocked. The
-- handler will eventually call `callback` depending on how much time is left before the call should
-- be scheduled.
local function schedule(callback, delay)
    local timer_id = os.startTimer(delay)
    return function()
        repeat
            local received_timer_id = pull_events("timer")[2]
        until received_timer_id == timer_id
        callback()
    end
end

--- Blocks this coroutine for `delay` seconds.
-- This implementation improves on the Computercraft sleep command as it only consumes its own
-- events from the event queue rather than pulling and invalidating all intermediate events.
local function sleep(delay)
    schedule(function()
    end, delay)()
end

return {
    listen = listen,
    wait_for_inventory_change = wait_for_inventory_change,
    schedule = schedule,
    sleep = sleep,
}
