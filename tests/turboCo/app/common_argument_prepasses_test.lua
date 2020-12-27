local common_argument_prepasses = dofile("./gitlib/turboCo/app/common_argument_prepasses.lua")

local prepass_help_argument = common_argument_prepasses.prepass_help_argument

describe("Common argument prepasses", function()
    describe("when prepassing help arguments", function()
        local definitions = {
            {
                long_name = "arg_1",
                description = "Does thing 1.",
            },
            {
                long_name = "arg_2",
                short_name = "a",
            },
            {
                short_name = "s",
                description = "Does all of the best things and I need to keep making this sentence"
                        .. " really long just in case it does anything weird.",
            },
        }
        local real_print
        local last_printed
        local error_triggered = false

        before_each(function()
            real_print = _G.print
            _G.print = function(...)
                last_printed = ...
            end
            _G.error = function()
                error_triggered = true
            end
        end)

        after_each(function()
            _G.print = real_print
            last_printed = nil
            error_triggered = false
        end)

        it("should print help instructions when help argument specified", function()
            prepass_help_argument(definitions, {
                help = true,
            })

            assert.are.equal(
                    "Usage:"
                            .. "\n\n--arg_1     Does thing 1."
                            .. "\n\n--arg_2, -a "
                            .. "\n\n-s          Does all of the best things and I need to keep"
                            .. " making this sentence really long just in case it does anything"
                            .. " weird.",
                    last_printed)
            assert.is_true(error_triggered)
        end)

        it("should do nothing when no help argument specified", function()
            prepass_help_argument(definitions, {
                arg_2 = true,
            })

            assert.is_nil(last_printed)
            assert.is_false(error_triggered)
        end)

        it("should do nothing when help argument is false", function()
            prepass_help_argument(definitions, {
                help = false,
            })

            assert.is_nil(last_printed)
            assert.is_false(error_triggered)
        end)
    end)
end)
