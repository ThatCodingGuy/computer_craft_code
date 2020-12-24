--- Library for wrapping commonly-used patterns around Lua's basic functions.

--- Allows creating a class.
-- @param statics A table containing static definitions for the class.
-- @param definition The definition of the class, expressed as a function. The function may take any
-- number of parameters as its invocation acts as the constructor. The function must return a table
-- containing the public members of the class.
--
local function class(statics, definition)
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
local function enum(values)
    local num_values = #values
    for i = 1, num_values do
        values[values[i]] = i
    end
    return values
end

--- Returns an array containing tokens extracted from `text` by separating it using `delimiter`.
-- Note that `delimiter` is parsed as a regex pattern.
local function split(text, delimiter)
    local fragments = {}
    local current_index = 1
    local next_index_start, next_index_end = text:find(delimiter)
    while next_index_start ~= nil do
        table.insert(fragments, text:sub(current_index, next_index_start - 1))
        current_index = next_index_end + 1
        next_index_start, next_index_end = text:find(delimiter, current_index)
    end
    fragments[#fragments + 1] = text:sub(current_index)
    return fragments
end

return {
    class = class,
    enum = enum,
    split = split,
}
