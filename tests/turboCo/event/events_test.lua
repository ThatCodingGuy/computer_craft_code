local events = dofile("./gitlib/turboCo/event/events.lua")
local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")

describe("Events", function()
    local os
    local caller = {
        callback = function()
        end
    }
    local return_value
    local get_return_value = function()
        return return_value
    end

    before_each(function()
        return_value = nil
        os = test_setup.generate_cc_mocks(mock).os
        os.pullEvent = function(event_type)
            return get_return_value()
        end
        spy.on(caller, "callback")
    end)

    after_each(function()
        caller.callback:revert()
    end)

    describe("when calling listen", function()
        it("calls the callback when event type matches", function()
            return_value = { "this event", 123, 456 }

            events.listen(caller.callback, "this event")

            assert.spy(caller.callback).was.called(1)
            assert.spy(caller.callback).was.called_with({ "this event", 123, 456 })
        end)
    end)

    describe("when calling schedule", function()
        local timer_id = 123
        before_each(function()
            os.startTimer = function()
                return timer_id
            end
        end)

        it("calls the callback when event is timer and ID matches", function()
            return_value = { "timer", timer_id }

            events.schedule(caller.callback, 9999)()

            assert.spy(caller.callback).was.called(1)
            assert.spy(caller.callback).was.called_with()
        end)

        it("skips the callback when event timer ID does not match", function()
            local calls = 0
            get_return_value = function()
                calls = calls + 1
                if calls == 1 then
                    return { "timer", timer_id - 1 }
                else
                    return { "timer", timer_id }
                end
            end
            events.schedule(caller.callback, 9999)()
            assert.are.equal(2, calls)
        end)

        it("sleeps for correct amount of time", function()
            spy.on(os, "startTimer")

            events.sleep(9999)

            assert.spy(os.startTimer).was.called_with(9999)

            os.startTimer:revert()
        end)
    end)

    it("waits for inventory change event", function()
        spy.on(os, "pullEvent")
        return_value = { "turtle_inventory" }

        events.wait_for_inventory_change()

        assert.spy(os.pullEvent).was.called_with("turtle_inventory")
    end)
end)
