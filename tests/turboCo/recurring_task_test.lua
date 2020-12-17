local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")

describe("Recurring task", function()
    local os
    local timer_id
    local internal_task
    local handle_event_type
    local event_handler = {
        addHandle = function(event_type, callback)
            handle_event_type = event_type
            internal_task = callback
        end,
        pullEvent = function()
        end
    }
    local t

    before_each(function()
        os = test_setup.generate_cc_mocks(mock).os
        os.startTimer = function(_)
            return timer_id
        end
        spy.on(os, "startTimer")
        t = { do_thing = function()
        end }
        stub(t, "do_thing")
    end)

    it("should perform task and schedule next one on run", function()
        stub(event_handler, "addHandle")
        stub(event_handler, "pullEvent")
        local recurring_task = RecurringTask.new(50, t.do_thing, event_handler)

        recurring_task.run()

        assert.stub(t.do_thing).was.called(1)
        assert.stub(event_handler.addHandle).was.called()
        assert.spy(os.startTimer).was.called_with(50)
        assert.stub(event_handler.pullEvent).was.called()

        event_handler.addHandle:revert()
        event_handler.pullEvent:revert()
    end)

    it("should do nothing on irrelevant timer ID", function()
        local recurring_task = RecurringTask.new(50, t.do_thing, event_handler)
        timer_id = 123

        recurring_task.run()
        internal_task { "timer", 456 }

        assert.stub(t.do_thing).was.called(1)
    end)

    it("should run task and reschedule when receiving timer event", function()
        local recurring_task = RecurringTask.new(50, t.do_thing, event_handler)
        timer_id = 123

        recurring_task.run()
        internal_task { "timer", 123 }

        assert.stub(t.do_thing).was.called(2)
        assert.spy(os.startTimer).was.called_with(50)
        assert.spy(os.startTimer).was.called(2)
    end)
end)
