local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

local function starts_with(s, start)
    return s:sub(1, #start) == start
end

--- A parser of program arguments provided on the command line.
-- The constructor accepts a table of definitions helping the parser find and organize the command
-- line arguments.
--
-- The definitions table is an array whose elements are themselves tables. The definition is as
-- follows:
--
-- {
--   long_name   -- The name of the command line parameter, which may consist of multiple
--                  characters. It should be preceded by two dashes (--) on the command line. If
--                  short_name is unset, then this value is required.
--   short_name  -- The name of the command line parameter consisting of a single character. It
--                  should be preceded by a single dash (-) on the command line. If long_name is,
--                  unset, then this value is required.
--   transform   -- An optional function that will be called to process a parsed argument. The
--                  transformer will receive the key and value as arguments and is expected to
--                  return the final value that should be associated with the key.
--   description -- An optional string description to document what the argument does.
-- }
local CliArgumentParser = class({}, function(definitions)
    local self = {
        long_argument_definitions = {},
        short_argument_definitions = {},
        merged_argument_definitions = {},
    }

    for _, definition in ipairs(definitions) do
        if definition.long_name ~= nil then
            self.long_argument_definitions[definition.long_name] = definition
            self.merged_argument_definitions[definition.long_name] = definition
        end

        if definition.short_name ~= nil then
            self.short_argument_definitions[definition.short_name] = definition
            if definition.long_name == nil then
                self.merged_argument_definitions[definition.short_name] = definition
            end
        end
    end

    local function parse_arg_value(args, i)
        local args_left = #args - i
        if args_left < 1 then
            return "", i + 1
        end

        local next_arg = args[i + 1]
        if not starts_with(next_arg, "=") then
            return "", i + 1
        end

        if #next_arg > 1 then
            return next_arg:sub(2), i + 2
        end

        if args_left < 2 then
            return "", i + 2
        end

        local final_arg = args[i + 2]
        if starts_with(final_arg, "--")
                or starts_with(final_arg, "-")
                or starts_with(final_arg, "=") then
            return "", i + 2
        end

        return final_arg, i + 3
    end

    local function parse_equals_arg(arg)
        local equals_index = arg:find("=")
        if equals_index == nil then
            return nil
        end

        local arg_key = arg:sub(1, equals_index - 1)
        if arg_key == "" then
            return nil
        end

        return { key = arg_key, value = arg:sub(equals_index + 1) }
    end

    local function parse_arg(arg, unparsed_args, parsed_args, i)
        if arg == "" then
            return nil
        end

        local parsed_arg = parse_equals_arg(arg)
        if parsed_arg ~= nil then
            table.insert(parsed_args, parsed_arg)
            return i + 1
        end

        local next_i
        local parsed_value
        parsed_value, next_i = parse_arg_value(unparsed_args, i)
        table.insert(parsed_args, { key = arg, value = parsed_value })
        return next_i
    end

    local function capture_arguments(args)
        local positional_arguments = {}
        local keyed_arguments = {}

        local i = 1
        while i <= #args do
            local arg = args[i]
            if starts_with(arg, "--") then
                i = parse_arg(arg:sub(3), args, keyed_arguments, i)
            elseif starts_with(arg, "-") then
                i = parse_arg(arg:sub(2), args, keyed_arguments, i)
            elseif arg == "=" then
                i = i + 1
            else
                table.insert(positional_arguments, arg)
                i = i + 1
            end
        end

        return keyed_arguments, positional_arguments
    end

    local function clean_values(keyed_arguments)
        local cleaned_arguments = {}
        for _, entry in ipairs(keyed_arguments) do
            local value = entry.value
            if value:match("^\".*\"$")
                    or value:match("^'.*'$") then
                value = value:sub(2, #value - 1)
            end
            table.insert(cleaned_arguments, { key = entry.key, value = value })
        end
        return cleaned_arguments
    end

    local function filter_keys(keyed_arguments)
        local returned_arguments = {}
        for _, argument in ipairs(keyed_arguments) do
            if self.long_argument_definitions[argument.key] ~= nil then
                returned_arguments[argument.key] = argument.value
            elseif self.short_argument_definitions[argument.key] ~= nil then
                local definition = self.short_argument_definitions[argument.key]
                local key = definition.long_name
                if key == nil then
                    key = argument.key
                end
                returned_arguments[key] = argument.value
            end
        end

        return returned_arguments
    end

    local function transform_values(keyed_arguments)
        local returned_arguments = {}
        for key, value in pairs(keyed_arguments) do
            local transform = self.merged_argument_definitions[key].transform
            local final_value = value
            if transform ~= nil then
                final_value = transform(key, value)
            end
            returned_arguments[key] = final_value
        end
        return returned_arguments
    end

    --- Returns a table containing values parsed from args associated with keys contained in the
    -- definitions held by this parser instance. Any arguments that could not be associated with one
    -- of the defined keys is made available through the positional_arguments value in the table as
    -- an array.
    local function parse(args)
        if #args == 0 then
            return {}
        end

        local keyed_arguments, positional_arguments = capture_arguments(args)
        local returned_arguments = transform_values(filter_keys(clean_values(keyed_arguments)))

        if #positional_arguments > 0 then
            returned_arguments.positional_arguments = positional_arguments
        end
        return returned_arguments
    end

    return {
        parse = parse,
    }
end)

return CliArgumentParser
