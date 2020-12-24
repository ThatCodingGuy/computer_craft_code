local CliArgumentParser = dofile("./gitlib/turboCo/app/cli_argument_parser.lua")

describe("CLI argument parser", function()
    it("should parse long arguments", function()
        local parser = CliArgumentParser.new {
            {
                long_name = "arg_1",
            },
            {
                long_name = "arg_2",
            },
            {
                long_name = "arg_3",
            },
            {
                long_name = "arg_4",
            },
        }

        assert.are.same({
            arg_1 = "lol",
            arg_2 = "123",
            arg_4 = "true",
        }, parser.parse {
            "--arg_1=lol",
            "--arg_2=123",
            "--arg_4",
            "=",
            "true",
        })
    end)

    it("should parse short arguments", function()
        local parser = CliArgumentParser.new({
            {
                short_name = "a",
            },
            {
                short_name = "b",
            },
            {
                short_name = "c",
            },
        })

        assert.are.same({
            a = "lol",
            b = "123",
            c = "true",
        }, parser.parse({
            "-a",
            "=",
            "lol",
            "-b=123",
            "-c",
            "=",
            "true",
        }))
    end)

    it("should ignore quotes", function()
        local parser = CliArgumentParser.new {
            {
                long_name = "arg_1",
            },
            {
                long_name = "arg_2",
            },
        }

        assert.are.same({
            arg_1 = "lol",
            arg_2 = "123",
        }, parser.parse {
            "--arg_1='lol'",
            "--arg_2=\"123\"",
        })
    end)

    it("should pass positional arguments along", function()
        local parser = CliArgumentParser.new {}

        assert.are.same({
            positional_arguments = {
                "abc",
                "123",
                "qwe=",
                "nope",
            },
        }, parser.parse {
            "abc",
            "123",
            "qwe=",
            "nope",
            "="
        })
    end)

    it("should return empty string for unparsable arguments", function()
        local parser = CliArgumentParser.new {
            {
                short_name = "a",
            },
            {
                long_name = "looong",
            },
            {
                long_name = "thing",
            },
            {
                short_name = "t",
            },
            {
                long_name = "last",
            },
        }

        assert.are.same({
            a = "",
            looong = "thing",
            thing = "",
            t = "",
            last = "",
            positional_arguments = {
                "others"
            }
        }, parser.parse {
            "-a=",
            "--looong",
            "=",
            "thing",
            "--thing",
            "-t",
            "--last",
            "=",
            "--invalid",
            "others"
        })
    end)

    it("should override repeated arguments", function()
        local parser = CliArgumentParser.new {
            {
                short_name = "a",
            },
            {
                long_name = "long",
            },
        }

        assert.are.same({
            a = "two",
            long = "2",
        }, parser.parse {
            "-a=one",
            "--long=1",
            "-a=two",
            "--long=2",
        })
    end)

    it("should ignore arguments without short or long name", function()
        local parser = CliArgumentParser.new {
            {
            },
            {
                long_name = "long",
            },
        }

        assert.are.same({
            long = "1",
        }, parser.parse {
            "--long=1",
        })
    end)

    it("should ignore unspecified CLI arguments", function()
        local parser = CliArgumentParser.new {}

        assert.are.same({
        }, parser.parse {
            "--unspecified=1",
        })
    end)

    it("should parse arguments with short and long name, using long name", function()
        local parser = CliArgumentParser.new {
            {
                short_name = "l",
                long_name = "long",
            },
        }

        assert.are.same({
            long = "1",
        }, parser.parse {
            "--long=1",
        })
        assert.are.same({
            long = "1",
        }, parser.parse {
            "-l=1",
        })
    end)
end)
