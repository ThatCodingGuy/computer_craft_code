local WallNavigator = dofile("./gitlib/leo/warehouse/wall_navigator.lua")
local test_setup = dofile("./gitlib/computercraft/testing/test_setup.lua")

describe("Wall context", function()
    local turtle

    before_each(function()
        turtle = test_setup.generate_cc_mocks(mock).turtle
    end)

    it("should correctly cycle around wall", function()
        local completed_revolutions = 0
        local context = WallNavigator.new(10, 5, function()
            completed_revolutions = completed_revolutions + 1
        end)

        for _ = 1, 8 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(8)
        assert.stub(turtle.turnRight).was.called(0)

        context.advance()
        assert.stub(turtle.forward).was.called(9)
        assert.stub(turtle.turnRight).was.called(1)

        for _ = 1, 3 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(12)
        assert.stub(turtle.turnRight).was.called(1)

        context.advance()
        assert.stub(turtle.forward).was.called(13)
        assert.stub(turtle.turnRight).was.called(2)

        for _ = 1, 8 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(21)
        assert.stub(turtle.turnRight).was.called(2)

        context.advance()
        assert.stub(turtle.forward).was.called(22)
        assert.stub(turtle.turnRight).was.called(3)

        for _ = 1, 3 do
            context.advance()
        end
        assert.stub(turtle.forward).was.called(25)
        assert.stub(turtle.turnRight).was.called(3)
        assert.are.equal(0, completed_revolutions)

        context.advance()
        assert.stub(turtle.forward).was.called(26)
        assert.stub(turtle.turnRight).was.called(4)
        assert.are.equal(1, completed_revolutions)
    end)
end)
