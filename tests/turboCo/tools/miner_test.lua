local keys = dofile("./gitlib/computercraft/keys.lua")
local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")
local Miner = dofile("./gitlib/turboCo/tools/miner.lua")
local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

local FakeEventHandler = class({}, function(input_keys)
    local self = {
        is_listening = true,
        handler = nil
    }

    return {
        setListening = function(is_listening)
            self.is_listening = is_listening
        end,
        addHandle = function(event_type, handler)
            self.handler = handler
        end,
        pullEvents = function()
            local current_key_index = 1
            while self.is_listening do
                local current_index = current_key_index
                if current_index <= #input_keys then
                    current_key_index = current_key_index + 1
                end
                self.handler { "key", input_keys[current_index] }
            end
        end,
    }
end)

describe("Miner", function()
    local os
    local turtle

    before_each(function()
        local setup = test_setup.generate_cc_mocks(mock)
        os = setup.os
        turtle = setup.turtle
    end)

    it("should call correct handlers upon input", function()
        local miner = Miner.new(FakeEventHandler.new {
            keys.up,
            keys.down,
            keys.left,
            keys.right,
            keys.pageUp,
            keys.pageDown,
            keys.space,
            keys.w,
            keys.s,
            keys.backspace
        })

        miner.start()

        assert.stub(turtle.forward).was.called(1)
        assert.stub(turtle.back).was.called(1)
        assert.stub(turtle.turnLeft).was.called(1)
        assert.stub(turtle.turnRight).was.called(1)
        assert.stub(turtle.up).was.called(1)
        assert.stub(turtle.dig).was.called(1)
        assert.stub(turtle.digUp).was.called(1)
        assert.stub(turtle.digDown).was.called(1)
        assert.stub(turtle.down).was.called(1)
    end)
end)
