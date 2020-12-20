local events = dofile("./gitlib/turboCo/event/events.lua")
local FakeOs = dofile("./gitlib/computercraft/testing/fake_os.lua")

describe("Events", function()
    local os
    local last_event_data
    local caller = {
        callback = function(event_data)
            last_event_data = event_data
        end
    }

    before_each(function()
        os = FakeOs.new()
        os.impersonate()
        spy.on(caller, "callback")
    end)

    after_each(function()
        caller.callback:revert()
    end)

    describe("when calling listen", function()
        it("calls the callback when event type matches and requeues unmatched events", function()
            os.queueEvent("some event", "some data")
            os.queueEvent("another event", "some data", "please")
            os.queueEvent("this event", 123, 456)

            events.listen(caller.callback, "this event")

            assert.spy(caller.callback).was.called(1)
            assert.are.same({ "this event", 123, 456 }, last_event_data)
            assert.are.equal(1, os.event_queue.index_of({ "some event", "some data" }))
            assert.are.equal(2, os.event_queue.index_of({ "another event", "some data", "please" }))
        end)
    end)

    describe("when calling schedule", function()
        it("calls the callback when event is timer and ID matches and requeues unmatched events", function()
            os.queueEvent("some event")

            events.schedule(caller.callback, 9999)()

            assert.spy(caller.callback).was.called(1)
            assert.spy(caller.callback).was.called_with()
            assert.is_true(os.event_queue.contains({"some event"}))
        end)

        it("skips the callback when event timer ID does not match", function()
            os.queueEvent("timer", 765)

            events.schedule(caller.callback, 9999)()

            assert.spy(caller.callback).was.called(1)
        end)

        it("sleeps for correct amount of time", function()
            spy.on(os, "startTimer")

            events.sleep(9999)

            assert.spy(os.startTimer).was.called_with(9999)

            os.startTimer:revert()
        end)
    end)

    it("waits for inventory change event", function()
        os.queueEvent("turtle_inventory")

        events.wait_for_inventory_change()
    end)
end)
