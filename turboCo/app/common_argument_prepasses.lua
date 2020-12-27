--- Contains prepasses for processing common CLI arguments.

local function pad(s, max_width)
    local num_spaces = max_width - #s
    local returned = s
    for _ = 1, num_spaces do
        returned = returned .. " "
    end
    return returned
end

--- A prepass for processing the --help/-h CLI argument.
local function prepass_help_argument(definitions, arguments)
    if arguments.help ~= true then
        return
    end

    local max_arg_id_length = 0
    local argument_data = {}
    for _, definition in ipairs(definitions) do
        local arg_ids = ""
        if definition.long_name ~= nil then
            arg_ids = arg_ids .. "--" .. definition.long_name
        end
        if definition.short_name ~= nil then
            if definition.long_name == nil then
                arg_ids = "-" .. definition.short_name
            else
                arg_ids = arg_ids .. ", -" .. definition.short_name
            end
        end

        table.insert(argument_data, { arg_ids = arg_ids, description = definition.description })
        if #arg_ids > max_arg_id_length then
            max_arg_id_length = #arg_ids
        end
    end

    local help_output = "Usage:"
    for _, datum in ipairs(argument_data) do
        help_output = help_output
                .. "\n\n"
                .. pad(datum.arg_ids, max_arg_id_length + 1)
        if datum.description ~= nil then
            help_output = help_output .. datum.description
        end
    end
    print(help_output)
     -- Since Computercraft doesn't have an os.exit() function we need to force an exit here.
    error()
end

return {
    prepass_help_argument = prepass_help_argument,
}
