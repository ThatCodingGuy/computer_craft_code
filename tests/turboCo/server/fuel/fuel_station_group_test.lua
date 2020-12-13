local movement = dofile("./gitlib/turboCo/movement.lua")
local ObservableValue = dofile("./gitlib/turboCo/observable_value.lua")
local FuelStationGroup = dofile("./gitlib/turboCo/server/fuel/fuel_station_group.lua")

describe("Fuel station group", function()
    local REFUEL_AMOUNT = 100
    local STATION_1_COORDS = movement.coord(2, 2, 2)
    local STATION_2_COORDS = movement.coord(8, 0, 0)
    local STATION_3_COORDS = movement.coord(1000, 2, 2)
    local INITIAL_COORDS = {
        STATION_1_COORDS, STATION_2_COORDS, STATION_3_COORDS
    }

    local observable_coords
    local stations

    before_each(function()
        observable_coords = ObservableValue.new()
        stations = FuelStationGroup.new(REFUEL_AMOUNT, observable_coords)
        observable_coords.set_value(INITIAL_COORDS)

    end)

    describe("when finding nearest station", function()
        it("should succeed when station is near enough and available", function()
            assert.are.equal(STATION_1_COORDS, stations.find_nearest(movement.coord(-1, -1, -1)))

            stations.reserve(STATION_1_COORDS)

            assert.are.equal(STATION_2_COORDS, stations.find_nearest(movement.coord(-1, -1, -1)))
        end)

        it("should return nil when station is unavailable", function()
            stations.reserve(STATION_1_COORDS)
            stations.reserve(STATION_2_COORDS)
            stations.reserve(STATION_3_COORDS)

            assert.is_nil(stations.find_nearest(movement.coord(-1, -1, -1)))
        end)

        it("should return nil when station is too far", function()
            stations.reserve(STATION_1_COORDS)
            stations.reserve(STATION_2_COORDS)

            assert.is_nil(stations.find_nearest(movement.coord(-1, -1, -1)))
        end)
    end)

    describe("when reserving stations", function()
        it("should return token when reservation succeeds", function()
            assert.is_not_nil(stations.reserve(STATION_1_COORDS))
        end)

        it("should return nil when station is not available", function()
            stations.reserve(STATION_1_COORDS)

            assert.is_nil(stations.reserve(STATION_1_COORDS))
        end)

        it("should return nil when station does not exist", function()
            assert.is_nil(stations.reserve(movement.coord(0, 0, 0)))
        end)
    end)

    describe("when releasing stations", function()
        it("should make station available", function()
            stations.reserve(STATION_1_COORDS)

            stations.release(STATION_1_COORDS)

            assert.is_not_nil(stations.reserve(STATION_1_COORDS))
        end)

        it("should do nothing when no corresponding station was reserved", function()
            stations.release(STATION_1_COORDS)
        end)
    end)

    describe("when existing coordinates are updated", function()
        local STATION_4_COORDS = movement.coord(80, 0, 0)

        local NEW_COORDS = {
            STATION_1_COORDS, STATION_4_COORDS
        }
        describe("when no reservations exist", function()
            before_each(function()
                observable_coords.set_value(NEW_COORDS)
            end)

            it("should find new stations", function()
                assert.are.equal(STATION_4_COORDS, stations.find_nearest(movement.coord(75, -1, -1)))
            end)

            it("should find unchanged stations", function()
                assert.are.equal(STATION_1_COORDS, stations.find_nearest(movement.coord(-1, -1, -1)))
            end)

            it("should not find eliminated stations", function()
                assert.is_nil(stations.find_nearest(STATION_3_COORDS))
            end)

            it("should allow reserving new stations", function()
                assert.is_not_nil(stations.reserve(STATION_4_COORDS))
            end)

            it("should allow reserving existing stations", function()
                assert.is_not_nil(stations.reserve(STATION_1_COORDS))
            end)

            it("should not allow reserving old stations", function()
                assert.is_nil(stations.reserve(STATION_3_COORDS))
            end)

            it("should release new stations", function()
                stations.reserve(STATION_4_COORDS)
                stations.release(STATION_4_COORDS)

                assert.is_not_nil(stations.reserve(STATION_4_COORDS))
            end)

            it("should release existing stations", function()
                stations.reserve(STATION_1_COORDS)
                stations.release(STATION_1_COORDS)

                assert.is_not_nil(stations.reserve(STATION_1_COORDS))
            end)

            it("should do nothing when attempting to release old stations", function()
                stations.release(STATION_2_COORDS)
            end)
        end)

        describe("when reservations exist", function()
            before_each(function()
                stations.reserve(STATION_1_COORDS)
                observable_coords.set_value(NEW_COORDS)
            end)

            it("should not allow reserving already-assigned unchanged stations", function()
                assert.is_nil(stations.reserve(STATION_1_COORDS))
            end)
        end)
    end)
end)