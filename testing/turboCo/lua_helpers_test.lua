local lua_helpers = require("turboCo.lua_helpers")

describe("Lua helpers", function()
    describe("constructor", function()
        local Prototype = {
            a = 0,
            b = "something"
        }

        it("should return a new instance when invoked without parameters", function()
            Prototype.new = lua_helpers.constructor

            local instance1 = Prototype:new()
            local instance2 = Prototype:new()
            instance1.a = 10
            instance1.b = "something else"
            instance2.a = 20
            instance2.b = "more things"

            assert.are.equal(0, Prototype.a)
            assert.are.equal("something", Prototype.b)
            assert.are.equal(10, instance1.a)
            assert.are.equal("something else", instance1.b)
            assert.are.equal(20, instance2.a)
            assert.are.equal("more things", instance2.b)
        end)

        it("should execute init function when invoked with parameters", function()
            function Prototype:new(a, b)
                return lua_helpers.constructor(Prototype, function(self)
                    self.a = a
                    self.b = b
                end)
            end

            local instance1 = Prototype:new(10, "something else")
            local instance2 = Prototype:new(20, "more things")

            assert.are.equal(0, Prototype.a)
            assert.are.equal("something", Prototype.b)
            assert.are.equal(10, instance1.a)
            assert.are.equal("something else", instance1.b)
            assert.are.equal(20, instance2.a)
            assert.are.equal("more things", instance2.b)
        end)
    end)

    describe("enum", function()
        it("should return same table with values in acsending order", function()
            local FakeEnum = lua_helpers.enum {
                "ONE", "TWO", "THREE"
            }

            assert.are.equal(1, FakeEnum.ONE)
            assert.are.equal(2, FakeEnum.TWO)
            assert.are.equal(3, FakeEnum.THREE)
        end)
    end)
end)
