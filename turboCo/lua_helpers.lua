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

--- Fixes the stupid table.concat implementation which doesn't like non-strings and non-numbers
local function join(tab, sep)
    if sep == nil then
      sep = ""
    end
    sep = tostring(sep)
    local str = ""
    local first = true
    for _, value in ipairs(tab) do
      if first then
        first = false
      else
        str = str .. sep
      end
      str = str .. tostring(value)
    end
    return str
  end
  
--- a contains function for tables. nuff said.
-- @return Does the table have the given value
local function contains(tab, val)
    for _, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

--helper function for tostring
local function table_print (tt, indent, done)
    done = done or {}
    indent = indent or 0
    if type(tt) == "table" then
      local sb = {}
      for key, value in pairs (tt) do
        table.insert(sb, string.rep (" ", indent)) -- indent it
        if type (value) == "table" and not done [value] then
          done [value] = true
          table.insert(sb, key .. " = {\n");
          table.insert(sb, table_print (value, indent + 2, done))
          table.insert(sb, string.rep (" ", indent)) -- indent it
          table.insert(sb, "}\n");
        elseif "number" == type(key) then
          table.insert(sb, string.format("\"%s\"\n", tostring(value)))
        else
          table.insert(sb, string.format(
              "%s = \"%s\"\n", tostring (key), tostring(value)))
         end
      end
      return table.concat(sb)
    else
      return tt .. "\n"
    end
  end
  
--Universal tostring, prints tables well
local function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

return {
    class = class,
    enum = enum,
    split = split,
    join = join,
    contains = contains,
    to_string = to_string
}
