local CliArgumentParser = dofile("./gitlib/turboCo/app/cli_argument_parser.lua")
local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A CLI argument parser that parses CLI arguments and then runs each handler in `prepass_handlers`
-- on the parsed arguments.
local CliArgumentPrepass = class({}, function(definitions, prepass_handlers)
    local self = {
        parser = CliArgumentParser.new(definitions)
    }

    --- Parses the CLI arguments within `args`, runs the prepass handlers, and then returns the
    -- parsed arguments. See CliArgumentParser for details on the return value.
    local function parse(args)
        local parsed_arguments = self.parser.parse(args)
        for _, handle in ipairs(prepass_handlers) do
            handle(definitions, parsed_arguments)
        end
        return parsed_arguments
    end

    return {
        parse = parse
    }
end)

return CliArgumentPrepass
