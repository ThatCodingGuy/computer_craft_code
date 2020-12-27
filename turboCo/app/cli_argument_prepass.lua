local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A CLI argument parser that uses `parser` to parse arguments and then runs each handler in
-- `prepass_handlers` on the parsed arguments.
local CliArgumentPrepass = class({}, function(parser, prepass_handlers)
    --- Parses the CLI arguments within `args`, runs the prepass handlers, and then returns the
    -- parsed arguments. See CliArgumentParser for details on the return value.
    local function parse(args)
        local parsed_arguments = parser.parse(args)
        for _, handle in ipairs(prepass_handlers) do
            handle(parsed_arguments)
        end
        return parsed_arguments
    end

    return {
        parse = parse
    }
end)

return CliArgumentPrepass
