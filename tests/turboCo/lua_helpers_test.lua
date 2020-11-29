local lua_helpers = require("turboCo.lua_helpers")
local class = lua_helpers.class
local enum = lua_helpers.enum

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
end)
