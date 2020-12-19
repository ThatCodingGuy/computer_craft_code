local events = dofile("./gitlib/turboCo/event/events.lua")
local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A task that executes periodically.
-- @param interval The minimum amount of time, in seconds, to wait before executing the task.
-- @param perform_task The task that should be executed periodically.
-- @param event_handler The EventHandler instance used for registering timer events.
RecurringTask = class({}, function(interval, perform_task)
    local self = {
        timer_id = nil,
        is_running = false,
    }

    --- Starts running this timer. This is a blocking operation.
    local function run()
        self.is_running = true
        while self.is_running do
            perform_task()
            events.sleep(interval)
        end
    end

    --- Stops this task from running in the future.
    local function stop()
        self.is_running = false
    end

    return {
        run = run,
        stop = stop,
    }
end)

return RecurringTask
