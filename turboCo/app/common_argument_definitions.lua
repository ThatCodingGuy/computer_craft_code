--- CLI argument definition factories for common transformations on CLI arguments.

local function copy_definition(definition, convert_default)
    local copy = {}
    for key, value in pairs(definition) do
        copy[key] = value
    end
    if definition.default ~= nil then
        copy.default = convert_default(definition.default)
    end
    return copy
end

--- A CLI argument definition whose value should be a number.
-- @param definition The definition of the argument, without specifying the value for the transform
-- function.
local function number_def(definition)
    local copy = copy_definition(definition, tostring)
    copy.transform = function(key, value)
        return tonumber(value)
    end
    return copy
end

--- A CLI argument definition whose value should be a boolean.
-- @param definition The definition of the argument, without specifying the value for the transform
-- function.
local function boolean_def(definition)
    local copy = copy_definition(definition, tostring)
    copy.transform = function(key, value)
        local lowercase_value = value:lower()
        if lowercase_value == "false" then
            return false
        elseif lowercase_value == "true" then
            return true
        elseif lowercase_value == "" then
            return true
        end
        return nil
    end
    return copy
end

--- A CLI argument definition whose value should be an enum.
-- @param definition The definition of the argument, without specifying the value for the transform
-- function.
local function enum_def(enum_type, definition)
    local copy = copy_definition(
            definition,
            function(default)
                return enum_type[default]
            end)
    copy.transform = function(key, value)
        local enum_value = enum_type[value:upper()]
        if enum_value == nil then
            return nil
        end
        return enum_value
    end
    return copy
end

return {
    number_def = number_def,
    boolean_def = boolean_def,
    enum_def = enum_def,
}
