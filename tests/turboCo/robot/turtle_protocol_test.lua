local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")
local turtle_protocol = dofile("./gitlib/turboCo/robot/turtle_protocol.lua")

describe("Turtle protocol", function()
    local turtle

    before_each(function()
        local cc_mocks = test_setup.generate_cc_mocks(mock)
        turtle = cc_mocks.turtle
    end)

    it("should successfully serialize turtle commands", function()
        assert.are.same({"dig"}, turtle.dig)
        assert.are.same({"drop", 15}, turtle.drop, 15)
    end)

    it("should successfully deserialize turtle commands", function()
    end)
end)