local FakeOs = dofile("./gitlib/computercraft/testing/fake_os.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")

describe("Event handler", function()
    local event_handler
    local os
    local last_event_data
    local caller = {
        callback = function(event_data)
            last_event_data = event_data
        end
    }

    local function run_event_handler()
        os.queueEvent("stop running")
        event_handler.addHandle("stop running", function()
            event_handler.setListening(false)
        end)
        event_handler.pullEvents()
    end

    before_each(function()
        print("************************************")
        event_handler = EventHandler.create()
        os = FakeOs.new()
        os.impersonate()
        spy.on(caller, "callback")
    end)

    after_each(function()
        caller.callback:revert()
    end)

    it("calls the callback when event type matches", function()
        os.queueEvent("some event", "some data")
        os.queueEvent("another event", "some data", "please")
        os.queueEvent("this event", 123, 456)

        event_handler.addHandle("this event", caller.callback)
        run_event_handler()

        assert.spy(caller.callback).was.called(1)
        assert.are.same({ "this event", 123, 456 }, last_event_data)
    end)

    it("should correctly remove event handlers", function()
        local handle_1
        local handle_2
        local callbacks
        callbacks = {
            callback_1 = function()
                print("Callback 1")
                event_handler.removeHandle(handle_1)
                event_handler.removeHandle(handle_2)
            end,
            callback_2 = function()
                print("Callback 2")
            end,
        }
        spy.on(callbacks, "callback_1")
        spy.on(callbacks, "callback_2")
        handle_1 = event_handler.addHandle("some event", callbacks.callback_1)
        handle_2 = event_handler.addHandle("some event", callbacks.callback_2)
        os.queueEvent("some event")
        os.queueEvent("some event")

        run_event_handler()

        assert.spy(callbacks.callback_1).was.called(1)
        assert.spy(callbacks.callback_2).was_not.called()
    end)

    describe("when calling schedule", function()
        it("calls the callback when event is timer and ID matches",
                function()
                    event_handler.schedule(caller.callback, 9999)
                    run_event_handler()

                    assert.spy(caller.callback).was.called(1)
                    assert.spy(caller.callback).was.called_with()
                end)

        it("skips the callback when event timer ID does not match",
                function()
                    local wrong_timer_id = os.startTimer(765)
                    local assert_not_called = function(event_data)
                        if event_data[2] == wrong_timer_id then
                            assert.spy(caller.callback).was_not.called()
                        end
                    end

                    event_handler.schedule(caller.callback, 9999)
                    event_handler.addHandle("timer", assert_not_called)
                    run_event_handler()

                    assert.spy(caller.callback).was.called(1)
                end)
    end)

    it("schedule recurring repeats task until canceled", function()
        local call_count = 0
        local handle_id
        local callback = function()
            print("Callback")
            call_count = call_count + 1
            if call_count >= 3 then
                print("Killing callback")
                event_handler.removeHandle(handle_id)
                event_handler.setListening(false)
            end
        end

        handle_id = event_handler.scheduleRecurring(callback, 100)
        event_handler.pullEvents()

        assert.are.equal(3, call_count)
    end)
end)
