local keys = dofile("./gitlib/computercraft/keys.lua")
local os = dofile("./gitlib/computercraft/os.lua")
local turtle = dofile("./gitlib/computercraft/turtle.lua")

--- Generates mocks for the ComputerCraft API for use within tests.
--
-- Run this within the before_each declaration in your tests. Running this will return a table where
-- each entry corresponds to one of the ComputerCraft APIs.
local function generate_cc_mocks(mock)
    mock.revert(os)
    mock.revert(turtle)
    _G.keys = mock(keys, true)
    _G.os = mock(os, true)
    _G.turtle = mock(turtle, true)
    return {
        os = _G.os,
        turtle = _G.turtle,
    }
end

local function impersonate_os_api_loader()
    _G.os.loadAPI = function(file_path)
        return dofile("." .. file_path)
    end
end

return {
    generate_cc_mocks = generate_cc_mocks,
    impersonate_os_api_loader = impersonate_os_api_loader,
}
