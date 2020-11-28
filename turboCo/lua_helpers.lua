--- Library for wrapping commonly-used patterns around Lua's basic functions.

local lua_helpers = {}

--- Allows creating a constructor for a class.
-- @param class The prototype instance used as the base for instances of a class.
-- @param init An optional function that runs setup code as part of the constructor. The function
-- provides a single parameter that represents the newly-constructed object.
-- @return The instance of the class.
function lua_helpers.constructor(class, init)
    local object_metatable = {}
    setmetatable(object_metatable, class)
    class.__index = class

    if (init) then init(object_metatable) end

    return object_metatable
end

return lua_helpers
