local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")
local cli_argument_definitions = dofile("./gitlib/turboCo/app/cli_argument_definitions.lua")

local enum = lua_helpers.enum
local number_def = cli_argument_definitions.number_def
local boolean_def = cli_argument_definitions.boolean_def
local enum_def = cli_argument_definitions.enum_def

describe("CLI argument definitions", function()
    describe("when creating number definition", function()
        local def = number_def {
            long_name = "arg_name"
        }

        it("should parse strings as numbers", function()
            assert.are.equal(1234, def.transform("arg_name", "1234"))
            assert.are.equal(43.21, def.transform("arg_name", "43.21"))
        end)

        it("should return nil when failing to parse number", function()
            assert.is_nil(def.transform("arg_name", "text"))
            assert.is_nil(def.transform("arg_name", "numb3r54nd73x7"))
        end)
    end)

    describe("when creating boolean definitions", function()
        local def = boolean_def {
            long_name = "arg_name"
        }

        it("should parse strings as booleans", function()
            assert.are.equal(def.transform("arg_name", "true"), true)
            assert.are.equal(def.transform("arg_name", "True"), true)
            assert.are.equal(def.transform("arg_name", "false"), false)
            assert.are.equal(def.transform("arg_name", "False"), false)
        end)

        it("should parse empty strings as true", function()
            assert.are.equal(def.transform("arg_name", ""), true)
        end)

        it("should parse unknown strings as nil", function()
            assert.is_nil(def.transform("arg_name", "not a boolean"))
        end)
    end)

    describe("when creating enum definitions", function()
        local FakeEnum = enum { "ONE", "TWO", "THREE" }
        local def = enum_def(FakeEnum, {
            long_name = "arg_name"
        })

        it("should parse valid enum values", function()
            assert.are.equal(FakeEnum.ONE, def.transform("arg_name", "ONE"))
            assert.are.equal(FakeEnum.ONE, def.transform("arg_name", "one"))
            assert.are.equal(FakeEnum.ONE, def.transform("arg_name", "One"))
            assert.are.equal(FakeEnum.TWO, def.transform("arg_name", "TWO"))
            assert.are.equal(FakeEnum.THREE, def.transform("arg_name", "THREE"))
        end)

        it("should return nil for invalid enum values", function()
            assert.is_nil(def.transform("arg_name", "nope"))
        end)
    end)
end)
