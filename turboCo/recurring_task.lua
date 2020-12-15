local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A task that executes periodically.
-- @param interval The minimum amount of time, in seconds, to wait before executing the task.
-- @param perform_task The task that should be executed periodically.
RecurringTask = class({}, function(interval, perform_task)
    local self = {
        next_execution_details = {
            remaining_time = 0,
            last_clock_read = 0
        },
        task = coroutine.create(function()
            perform_task()
            local start_time = os.clock()
            while true do
                local end_time = os.clock()
                local delta = end_time - start_time
                if delta < interval then
                    coroutine.yield {
                        remaining_time = interval - delta,
                        last_clock_read = end_time
                    }
                else
                    perform_task()
                    start_time = os.clock()
                    coroutine.yield {
                        remaining_time = interval,
                        last_clock_read = start_time
                    }
                end
            end
        end)
    }

    --- Starts the timer on this task.
    local function start()
        local values = { coroutine.resume(self.task) }
        self.next_execution_details = values[2]
    end

    --- Blocks on this task until it's ready to update.
    local function wait_until_update()
        local current_time = os.clock()
        local time_since_last_clock_read = current_time - self.next_execution_details.last_clock_read
        local remaining_time = self.next_execution_details.remaining_time
        if time_since_last_clock_read < remaining_time then
            local sleep_time = remaining_time - time_since_last_clock_read
            os.sleep(sleep_time)
            self.next_execution_details = {
                remaining_time = 0,
                last_clock_read = current_time + sleep_time
            }
        end
        self.next_execution_details = {
            remaining_time = remaining_time - time_since_last_clock_read,
            last_clock_read = current_time
        }
    end

    return {
        start = start,
        --- Updates this task and possibly executes its logic.
        update = start,
        wait_until_update = wait_until_update,
    }
end)

return RecurringTask
