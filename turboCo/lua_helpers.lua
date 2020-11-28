--- Library for wrapping commonly-used patterns around Lua's basic functions.

local lua_helpers = {}

--- Allows creating a class.
-- @param statics A table containing static definitions for the class.
-- @param definition The definition of the class, expressed as a function. The function may take any
-- number of parameters as its invocation acts as the constructor. The function must return a table
-- containing the public members of the class.
--
function lua_helpers.class(statics, definition)
    statics.new = definition
    return statics
end

--- Allows defining enums without specifying their values.
-- This will automatically assign integer values to the enums in ascending order starting from 1
-- onwards.
-- @param values The table of names to give to the enums. Specify this as a simple table of strings
-- without assigning them values.
-- @return The original enum table, `values`, with its values assigned.
--
function lua_helpers.enum(values)
    local num_values = #values
    for i = 1, num_values do
        values[values[i]] = i
    end
    return values
end

return lua_helpers
