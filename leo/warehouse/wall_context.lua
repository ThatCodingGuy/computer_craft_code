local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")
local dashboard = dofile("./gitlib/turboCo/dashboard.lua")

local class = lua_helpers.class
local enum = lua_helpers.enum

--- An enum determining which of the four walls the current context is centered upon.
--
local WallSide = enum {
    "NORTH", "SOUTH", "EAST", "WEST"
}

---
-- @param north_south_length The length of the walls on the northern and southern sides of the
-- warehouse.
-- @param east_west_length The length of the walls on the eastern and western sides of the
-- warehouse.
--
WallContext = class({
}, function(north_south_length, east_west_length)
    local self = {
        current_wall_side = WallSide.NORTH,
        current_block = 1,
    }

    local function current_wall_length()
        if self.current_wall_side == WallSide.NORTH or self.current_wall_side == WallSide.SOUTH then
            return north_south_length
        else
            return east_west_length
        end
    end

    local function compute_next_wall()
        if self.current_wall_side == WallSide.NORTH then
            return WallSide.EAST
        elseif self.current_wall_side == WallSide.EAST then
            return WallSide.SOUTH
        elseif self.current_wall_side == WallSide.SOUTH then
            return WallSide.WEST
        else
            return WallSide.NORTH
        end
    end

    --- Advances the turtle along the wall by one block.
    --
    -- If the turtle reaches a corner, this will also ensure that the turtle properly navigates it.
    --
    local function advance()
        if self.current_block > current_wall_length() then
            dashboard.log("wtf", "Turtle has exceeded the length of the wall.")
        end

        if self.current_block == current_wall_length() then
            turtle.turnRight()
            self.current_block = 1
            self.current_wall_side = compute_next_wall()
        end

        turtle.forward()
        self.current_block = self.current_block + 1
    end

    return {
        advance = advance
    }
end)

return WallContext
