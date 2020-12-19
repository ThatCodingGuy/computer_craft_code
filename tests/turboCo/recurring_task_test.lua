local ModuleLoader = dofile("./gitlib/testing/module_loader.lua")

local events = {
    sleep = function(delay)
    end
}
local module_loader = ModuleLoader.new {
    ["./gitlib/turboCo/event/events.lua"] = events
}
module_loader.set_up()

local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")

describe("Recurring task", function()
    before_each(function()
        spy.on(events, "sleep")
    end)

    it("should run correctly", function()
        local calls = 0
        local task
        task = RecurringTask.new(123, function()
            calls = calls + 1
            if calls == 3 then
                task.stop()
            end
        end)

        task.run()

        assert.spy(events.sleep).was.called(3)
        assert.spy(events.sleep).was.called_with(123)
        assert.are.equal(3, calls)
    end)
end)
