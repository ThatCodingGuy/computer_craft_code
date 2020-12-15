local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")

describe("Recurring task", function()
    local os
    local clock_time = 0

    local function advance_clock(interval)
        clock_time = clock_time + interval
    end

    before_each(function()
        clock_time = 0
        os = test_setup.generate_cc_mocks(mock).os
        os.clock = function()
            return clock_time
        end
    end)

    it("should yield when timer not expired", function()
        local task_performed_count = 0
        local task = RecurringTask.new(100, function()
            task_performed_count = task_performed_count + 1
        end)

        task.start()
        advance_clock(99)
        task.update()

        assert.are.equal(1, task_performed_count)
    end)

    it("should execute task when timer expires", function()
        local task_performed_count = 0
        local task = RecurringTask.new(100, function()
            task_performed_count = task_performed_count + 1
        end)

        task.start()
        advance_clock(100)
        task.update()

        assert.are.equal(2, task_performed_count)
    end)

    it("should wait correct amount of time when blocking on task", function()
        local sleep_calls = {}
        _G.sleep = function(time_to_sleep)
            table.insert(sleep_calls, time_to_sleep)
        end
        local task = RecurringTask.new(100, function()
        end)

        task.wait_until_update()
        assert.are.equal(0, #sleep_calls)
        task.wait_until_update()
        assert.are.equal(0, #sleep_calls)
        task.update()

        task.wait_until_update()
        assert.are.equal(1, #sleep_calls)
        assert.are.equal(100, sleep_calls[1])
        advance_clock(100)

        task.wait_until_update()
        assert.are.equal(1, #sleep_calls)

        advance_clock(100)
        task.wait_until_update()
        assert.are.equal(1, #sleep_calls)
        task.update()

        advance_clock(50)
        task.wait_until_update()
        assert.are.equal(2, #sleep_calls)
        assert.are.equal(50, sleep_calls[2])
        advance_clock(50)

        task.wait_until_update()
        assert.are.equal(2, #sleep_calls)
    end)
end)
