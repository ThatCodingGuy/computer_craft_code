local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A task that executes periodically.
-- @param interval The minimum amount of time, in seconds, to wait before executing the task.
-- @param perform_task The task that should be executed periodically.
-- @param event_handler The EventHandler instance used for registering timer events.
RecurringTask = class({}, function(interval, perform_task, event_handler)
    local self = {
        timer_id = nil,
    }

    function run_task(event_data)
        if event_data[2] ~= self.timer_id then
            return
        end

        perform_task()
        self.timer_id = os.startTimer(interval)
    end

    --- Starts running this timer. This is a blocking operation.
    local function run()
        perform_task()
        event_handler.addHandle("timer", run_task)
        self.timer_id = os.startTimer(interval)
        event_handler.pullEvents()
    end

    return {
        run = run,
    }
end)

return RecurringTask
