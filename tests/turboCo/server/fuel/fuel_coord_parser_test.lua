local movement = dofile("./gitlib/turboCo/movement.lua")
local FuelCoordParser = dofile("./gitlib/turboCo/server/fuel/fuel_coord_parser.lua")

describe("Fuel coord parser", function()
    it("should correctly parse the input file", function()
        local parser = FuelCoordParser.new("./gitlib/tests/turboCo/server/fuel/data/fake_data.txt")

        assert.are.same({
            movement.coord(123, 234, 345),
            movement.coord(987, 876, 765),
            movement.coord(1, 2, 3),
            movement.coord(4, 5, 6)
        }, parser.parse())
    end)

    it("should skip bad lines", function()
        local parser = FuelCoordParser.new("./gitlib/tests/turboCo/server/fuel/data/bad_data.txt")

        assert.are.same({
            movement.coord(1, 2, 3)
        }, parser.parse())
    end)
end)
