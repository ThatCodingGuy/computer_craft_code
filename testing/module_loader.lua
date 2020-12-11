local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

--- A loader object for loading up fake modules for use in testing.
--
-- Pass a table of module file names mapping to their fakes when constructing instances of this
-- class.
--
ModuleLoader = class({}, function(faked_modules)
    local self = {
        original_dofile = dofile
    }

    local function internal_dofile(module_path)
        local faked_module = faked_modules[module_path]
        if faked_module ~= nil then
            return faked_module
        end
        return self.original_dofile(module_path)
    end

    --- Installs this loader as the default Lua loader.
    --
    -- Call this within the before_each function for your tests.
    --
    local function setUp()
        _G.dofile = internal_dofile
    end

    return {
        setUp = setUp,
    }
end)

return ModuleLoader
