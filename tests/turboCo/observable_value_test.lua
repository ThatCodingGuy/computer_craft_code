local ObservableValue = dofile("./gitlib/turboCo/observable_value.lua")

describe("Observable value", function()
    local call_arg
    local times_called
    local function observer(new_value)
        call_arg = new_value
        times_called = times_called + 1
    end

    before_each(function()
        call_arg = nil
        times_called = 0
    end)

    it("should update listeners with new value", function()
        local value = ObservableValue.new()

        value.add_observer(observer)
        value.set_value(12345)

        assert.are.equal(1, times_called)
        assert.are.equal(12345, call_arg)
    end)

    it("should not update listeners if values are equal", function()
        local value = ObservableValue.new()

        value.add_observer(observer)
        value.set_value(12345)
        value.set_value(12345)

        assert.are.equal(1, times_called)
    end)
end)