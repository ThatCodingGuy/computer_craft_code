local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A task that executes periodically.
-- @param interval The minimum amount of time, in seconds, to wait before executing the task.
-- @param perform_task The task that should be executed periodically.
RecurringTask = class({}, function(interval, perform_task)
    local self = {
        task = coroutine.create(function()
            perform_task()
            local start_time = os.clock()
            while true do
                local end_time = os.clock()
                if end_time - start_time < interval then
                    coroutine.yield()
                else
                    perform_task()
                    start_time = os.clock()
                end
            end
        end)
    }

    --- Starts the timer on this task.
    local function start()
        coroutine.resume(self.task)
    end

    return {
        start = start,
        --- Updates this task and possibly executes its logic.
        update = start,
    }
end)

return RecurringTask
