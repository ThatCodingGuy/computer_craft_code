local Logger = dofile("./gitlib/turboCo/logger.lua")
local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")
local movement = dofile("./gitlib/turboCo/movement.lua")

local class = lua_helpers.class

FuelStationGroup = class({}, function(refuel_amount, observable_coords)
    local self = {
        logger = Logger.new(),
        max_distance = refuel_amount / 8,
        available_stations = {},
        reserved_stations = {},
    }

    local function update_and_resolve_stations(new_coords)
        local all_new_coords = {}
        local additions = ""
        local deletions = ""

        -- Add any new stations introduced.
        for _, coords in ipairs(new_coords) do
            all_new_coords[coords] = true
            if self.available_stations[coords] == nil
                    and self.reserved_stations[coords] == nil then
                self.available_stations[coords] = true
                additions = additions .. "\n\t[" .. coords .. "]"
            end
        end

        -- Delete any stations that don't exist anymore.
        for coords, _ in pairs(self.available_stations) do
            if all_new_coords[coords] == nil then
                self.available_stations[coords] = nil
                deletions = deletions .. "\n\t[" .. coords .. "]"
            end
        end
        for coords, _ in pairs(self.reserved_stations) do
            if all_new_coords[coords] == nil then
                self.reserved_stations[coords] = nil
                deletions = deletions .. "\n\t[" .. coords .. "]"
            end
        end

        self.logger.info(
                "New station coordinates loaded.\nAdditions: "
                        .. additions .. "\nDeletions: " .. deletions)
    end

    observable_coords.add_observer(update_and_resolve_stations)

    local function find_nearest(from_coords)
        local distance = 999999999999
        local nearest
        for station_coords, _ in pairs(self.available_stations) do
            local station_distance = movement.distance(station_coords, from_coords)
            if station_distance < distance and station_distance < self.max_distance then
                print("Station distance: " .. station_distance .. " " .. station_coords)
                nearest = station_coords
                distance = station_distance
            end
        end
        return nearest
    end

    local function reserve(station_coords)
        if self.reserved_stations[station_coords] ~= nil
                or self.available_stations[station_coords] == nil then
            return nil
        end

        self.reserved_stations[station_coords] = true
        self.available_stations[station_coords] = nil
        return station_coords
    end

    local function release(assignment_token)
        local reservation_status = self.reserved_stations[assignment_token]
        if reservation_status ~= nil then
            self.reserved_stations[assignment_token] = nil
            self.available_stations[assignment_token] = true
        end
    end

    return {
        find_nearest = find_nearest,
        reserve = reserve,
        release = release,
    }
end)

return FuelStationGroup
