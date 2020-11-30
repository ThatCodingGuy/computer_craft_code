local WallContext = dofile("./gitlib/leo/warehouse/wall_context.lua")
local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")

describe("Wall context", function()
    local turtle

    before_each(function()
        turtle = test_setup.generate_cc_mocks(mock).turtle
    end)

    it("should correctly cycle around wall", function()
        local context = WallContext.new(10, 5)

        for _ = 1, 10 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(10)

        context.advance()
        assert.stub(turtle.turnRight).was.called(1)
        assert.stub(turtle.forward).was.called(11)

        for _ = 1, 4 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(15)

        context.advance()
        assert.stub(turtle.turnRight).was.called(2)
        assert.stub(turtle.forward).was.called(16)

        for _ = 1, 9 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(25)

        context.advance()
        assert.stub(turtle.turnRight).was.called(3)
        assert.stub(turtle.forward).was.called(26)

        for _ = 1, 4 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(30)

        context.advance()
        assert.stub(turtle.turnRight).was.called(4)
        assert.stub(turtle.forward).was.called(31)
    end)

    it("should elevate by one block every cycle", function()
        local context = WallContext.new(2, 3)

        for _ = 1, 7 do
            context.advance()
        end

        assert.stub(turtle.up).was.called(1)
    end)
end)
