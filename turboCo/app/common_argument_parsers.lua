--- Contains factory functions for generating CliArgumentParser instances.

local CliArgumentPrepass = dofile("./gitlib/turboCo/app/cli_argument_prepass.lua")
local common_argument_definitions = dofile("./gitlib/turboCo/app/common_argument_definitions.lua")
local common_argument_prepasses = dofile("./gitlib/turboCo/app/common_argument_prepasses.lua")

local boolean_def = common_argument_definitions.boolean_def

--- Creates the default CLI argument parser with common functionality built-in.
-- @param custom_definitions The client's custom CLI argument definitions to be used in the parser.
local function default_parser(custom_definitions)
    local final_definitions = {
        boolean_def {
            long_name = "help",
            short_name = "h",
            description = "Displays informational text about the application."
        }
    }
    for _, definition in ipairs(custom_definitions) do
        table.insert(final_definitions, definition)
    end
    return CliArgumentPrepass.new(
            final_definitions,
            {
                common_argument_prepasses.prepass_help_argument
            }
    )
end

return {
    default_parser = default_parser,
}
