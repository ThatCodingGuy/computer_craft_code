turtle = dofile("./gitlib/computercraft/turtle.lua")

--- Generates mocks for the ComputerCraft API for use within tests.
--
-- Run this within the before_each declaration in your tests. Running this will return a table where
-- each entry corresponds to one of the ComputerCraft APIs.
local function generate_cc_mocks(mock)
    mock.revert(turtle)
    _G.turtle = mock(turtle, true)
    return {
        turtle = _G.turtle
    }
end

return {
    generate_cc_mocks = generate_cc_mocks
}
