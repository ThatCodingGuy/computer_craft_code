local FakeOs = dofile("./gitlib/computercraft/testing/fake_os.lua")

describe("Fake OS", function()
    local os

    before_each(function()
        os = FakeOs.new()
        os.impersonate()
    end)

    it("should replace global os object", function()
        assert.are.same(os, _G.os)
    end)

    it("should correctly queue events at end of queue", function()
        local event_1 = { "some event", "the", "event", "fields", 123 }
        local event_2 = { "some other event", "the", "event", "fields", 123 }
        os.queueEvent(unpack(event_1))
        os.queueEvent(unpack(event_2))

        local event_1_index = os.event_queue.index_of(event_1)
        local event_2_index = os.event_queue.index_of(event_2)
        assert.is_true(os.event_queue.contains(event_1))
        assert.is_true(os.event_queue.contains(event_2))
        assert.are.equal(1, event_1_index)
        assert.are.equal(2, event_2_index)
    end)

    it("should pull single event", function()
        os.queueEvent("event 1")
        os.queueEvent("event 2")

        local pulled_event_1 = os.pullEvent()
        local pulled_event_2 = os.pullEvent()

        assert.are.same({"event 1"}, pulled_event_1)
        assert.are.same({"event 2"}, pulled_event_2)
    end)

    it("should pull events until one matches filter", function()
        os.queueEvent("event 1")
        os.queueEvent("event 2")
        os.queueEvent("event 3")

        local pulled_event = os.pullEvent("event 3")

        assert.are.same({"event 3"}, pulled_event)
        assert.is_false(os.event_queue.contains({"event 1"}))
        assert.is_false(os.event_queue.contains({"event 2"}))
    end)

    it("should return nil when there are no events to pull", function()
        assert.is_nil(os.pullEvent(""))

        os.queueEvent({"an event"})

        assert.is_nil(os.pullEvent("another event"))
    end)

    it("should queue timer event at end of queue", function()
        local timer_id_1 = os.startTimer(123)
        os.queueEvent("event")
        local timer_id_2 = os.startTimer(234)
        local event_1 = os.pullEvent()
        local event_2 = os.pullEvent()
        local event_3 = os.pullEvent()

        assert.are.same({ "timer", timer_id_1 }, event_1)
        assert.are.same({"event"}, event_2)
        assert.are.same({ "timer", timer_id_2 }, event_3)
        assert.are_not.equal(timer_id_1, timer_id_2)
    end)

    it("should remove timer event from queue when timer is canceled", function()
        local timer_id = os.startTimer(456)
        os.cancelTimer(timer_id)

        assert.is_false(os.event_queue.contains({"timer", timer_id}))
    end)

    it("should queue alarm at end of queue", function()
        local alarm_1 = os.setAlarm(123)
        os.queueEvent("event")
        local alarm_2 = os.setAlarm(234)
        local event_1 = os.pullEvent()
        local event_2 = os.pullEvent()
        local event_3 = os.pullEvent()

        assert.are.same({ "alarm", alarm_1 }, event_1)
        assert.are.same({"event"}, event_2)
        assert.are.same({ "alarm", alarm_2 }, event_3)
        assert.are_not.equal(alarm_1, alarm_2)
    end)

    it("should remove alarm event from queue when alarm is canceled", function()
        local alarm = os.setAlarm(456)
        os.cancelAlarm(alarm)

        assert.is_false(os.event_queue.contains({ "alarm", alarm }))
    end)
end)
