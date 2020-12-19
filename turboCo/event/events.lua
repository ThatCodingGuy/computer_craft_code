--- Contains helpers for scheduling tasks on events as they're received.

--- Waits for an event of type `event_type` to occur and then calls `callback`.
local function listen(callback, event_type)
    callback(os.pullEvent(event_type))
end

--- Schedules `callback` to run after `delay` seconds, once the program blocks on the returned
-- handler.
-- @return A handler that should be called once the current coroutine is ready to be blocked. The
-- handler will eventually call `callback` depending on how much time is left before the call should
-- be scheduled.
local function schedule(callback, delay)
    local timer_id = os.startTimer(delay)
    return function()
        repeat
            local event_data = os.pullEvent("timer")
            local received_timer_id = event_data[2]
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
    schedule = schedule,
    sleep = sleep,
}
