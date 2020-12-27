local CliArgumentParser = dofile("./gitlib/turboCo/app/cli_argument_parser.lua")
local CliArgumentPrepass = dofile("./gitlib/turboCo/app/cli_argument_prepass.lua")

describe("CLI argument prepass", function()
    it("should run handlers after parsing", function()
        local handler_1_args
        local handler_2_args
        local handlers = {
            handler_1 = function(arguments)
                handler_1_args = arguments
            end,
            handler_2 = function(arguments)
                handler_2_args = arguments
            end,
        }

        local parsed_arguments = CliArgumentPrepass.new(
                CliArgumentParser.new {
                    {
                        long_name = "arg_1"
                    }
                }, {
                    handlers.handler_1,
                    handlers.handler_2,
                })                                 .parse {
            "--arg_1=qwerty",
            "positional"
        }

        assert.are.same(parsed_arguments, handler_1_args)
        assert.are.same(parsed_arguments, handler_2_args)
    end)
end)
