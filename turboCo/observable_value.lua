local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A value for which one can register observers. When the value changes, those observers will be
-- notified of the new value.
ObservableValue = class({}, function()
    local self = {
        value = nil,
        observers = {},
    }

    --- Adds an observer to be notified of any changes to the value.
    local function add_observer(listener)
        table.insert(self.observers, listener)
    end

    --- Sets the value on this instance.
    local function set_value(value)
        if (self.value ~= value) then
            self.value = value
            for _, observer in ipairs(self.observers) do
                observer(self.value)
            end
        end
    end

    return {
        add_observer = add_observer,
        set_value = set_value,
    }
end)

return ObservableValue
