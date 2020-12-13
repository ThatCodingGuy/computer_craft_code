local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")

describe("Recurring task", function()
    local os
    local clock_time = 0

    local function advance_clock(interval)
        clock_time = clock_time + interval
    end

    before_each(function()
        os = test_setup.generate_cc_mocks(mock).os
        os.clock = function()
            return clock_time
        end
    end)

    it("Should yield when timer not expired", function()
        local task_performed = false
        local task = RecurringTask.new(100, function()
            task_performed = true
        end)

        task.start()
        advance_clock(99)
        task.update()

        assert.are.equal(false, task_performed)
    end)

    it("Should execute task when timer expires", function()
        local task_performed = false
        local task = RecurringTask.new(100, function()
            task_performed = true
        end)

        task.start()
        advance_clock(100)
        task.update()

        assert.are.equal(true, task_performed)
    end)
end)
