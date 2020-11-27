--- Library for wrapping commonly-used patterns around Lua's basic functions.

local lua_helpers = {}

--- Allows creating a constructor for a class.
-- @param class The prototype instance used as the base for instances of a class.
-- @param setter An optional function that runs setup code as part of the constructor.
-- @return The instance of the class.
function lua_helpers.constructor(class, setter)
    local object_metatable = {}
    setmetatable(object_metatable, class)
    class.__index = class

    if (setter) then setter() end

    return object_metatable
end

return lua_helpers
