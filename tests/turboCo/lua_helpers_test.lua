local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class
local enum = lua_helpers.enum
local split = lua_helpers.split
local starts_with = lua_helpers.starts_with
local ends_with = lua_helpers.ends_with

describe("Lua helpers", function()
    describe("class", function()
        it("should return a valid prototype with constructor", function()
            local MyClass = class({
                static_var = 123,
                static_fun = function()
                    return 5
                end
            }, function(a)
                local self = {
                    b = 2
                }

                local function incrementA()
                    a = a + 1
                end

                local function incrementB()
                    self.b = self.b + 1
                end
                return {
                    getA = function()
                        return a
                    end,
                    getB = function()
                        return self.b
                    end,
                    incrementA = incrementA,
                    incrementB = incrementB
                }
            end)

            local instance1 = MyClass.new(3)
            local instance2 = MyClass.new(10)
            local a11 = instance1.getA()
            local b11 = instance1.getB()
            local a21 = instance2.getA()
            local b21 = instance2.getB()
            instance1.incrementA()
            instance1.incrementB()
            instance2.incrementA()
            instance2.incrementB()
            local a12 = instance1.getA()
            local b12 = instance1.getB()
            local a22 = instance2.getA()
            local b22 = instance2.getB()

            assert.are.equal(123, MyClass.static_var)
            assert.are.equal(5, MyClass.static_fun())
            assert.are.equal(nil, instance1.static_var)
            assert.are.equal(nil, instance1.static_fun)
            assert.are.equal(nil, instance2.static_var)
            assert.are.equal(nil, instance2.static_fun)
            assert.are.equal(3, a11)
            assert.are.equal(10, a21)
            assert.are.equal(4, a12)
            assert.are.equal(11, a22)
            assert.are.equal(2, b11)
            assert.are.equal(2, b21)
            assert.are.equal(3, b12)
            assert.are.equal(3, b22)
        end)
    end)

    describe("enum", function()
        it("should return same table with values in acsending order", function()
            local FakeEnum = enum {
                "ONE", "TWO", "THREE"
            }

            assert.are.equal(1, FakeEnum.ONE)
            assert.are.equal(2, FakeEnum.TWO)
            assert.are.equal(3, FakeEnum.THREE)
        end)
    end)

    describe("split", function()
        it("should split text into tokens, excluding the delimiter", function()
            assert.are.same({
                "some",
                "text",
                "has",
                "been",
                "split",
            },
                    split("some8text8has8been8split", "8"))
        end)

        it("should return a single-element array with the text if no delimiter exists", function()
            assert.are.same({
                "some text has been split",
            },
                    split("some text has been split", ","))
        end)

        it("should return empty strings when delimiter is preceeded or followed by nothing",
                function()
                    assert.are.same({
                        "",
                        " but rest of text",
                    },
                            split("a but rest of text", "a"))
                    assert.are.same({
                        "rest of text but",
                        "",
                    },
                            split("rest of text buta", "a"))
                end)

        it("should support multiple characters as delimiter", function()
            assert.are.same({
                "some text and a ",
                " but rest ",
                " and of text",
            },
                    split("some text and a big delimiter but rest big delimiter and of text",
                            "big delimiter"))
            assert.are.same({
                "",
                " but rest of text",
            },
                    split("big delimiter but rest of text", "big delimiter"))
            assert.are.same({
                "rest of text but ",
                "",
            },
                    split("rest of text but big delimiter", "big delimiter"))
        end)
    end)

    describe("starts with", function()
        it("should return true when prefix is contained within string at the beginning", function()
            assert.is_true(starts_with("some stuff", "so"))
            assert.is_true(starts_with("some stuff", "some "))
            assert.is_true(starts_with("some stuff", "some stuff"))
            assert.is_true(starts_with("some stuff", ""))
        end)

        it("should return false when prefix is not contained within string at the beginning",
                function()
                    assert.is_false(starts_with("some stuff", "b"))
                    assert.is_false(starts_with("some stuff", "son"))
                    assert.is_false(starts_with("some stuff", "somestuff"))
                    assert.is_false(starts_with("some stuff", "some stuff "))
                end)
    end)

    describe("ends with", function()
        it("should return true when suffix is contained within string at the end", function()
            assert.is_true(ends_with("some stuff", "ff"))
            assert.is_true(ends_with("some stuff", " stuff"))
            assert.is_true(ends_with("some stuff", "some stuff"))
            assert.is_true(ends_with("some stuff", ""))
        end)

        it("should return false when suffix is not contained within string at the end", function()
            assert.is_false(ends_with("some stuff", "x"))
            assert.is_false(ends_with("some stuff", "ctuff"))
            assert.is_false(ends_with("some stuff", "somestuff"))
            assert.is_false(ends_with("some stuff", " some stuff"))
        end)
    end)
end)
