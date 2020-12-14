local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class
local enum = lua_helpers.enum

local LoggingLevel = enum {
    "DEBUG", "INFO", "WARNING", "ERROR"
}
local print_to_output = print
local log_level_filter = LoggingLevel.WARNING

-- Make sure there's a single global instance of the Logger module.
if _G.Logger ~= nil then
    return _G.Logger
end

--- A simple logger that allows writing messages to stdout.
-- @param print_to_stdout An optional function that prints the contents to whatever output should be
-- used.
Logger = class({
    LoggingLevel = LoggingLevel,
    print_to_output = print_to_output,
    log_level_filter = log_level_filter,

}, function()
    local function debug(message)
        if Logger.log_level_filter <= Logger.LoggingLevel.DEBUG then
            Logger.print_to_output("D: " .. message)
        end
    end
    local function info(message)
        if Logger.log_level_filter <= Logger.LoggingLevel.INFO then
            Logger.print_to_output("I: " .. message)
        end
    end
    local function warn(message)
        if Logger.log_level_filter <= Logger.LoggingLevel.WARNING then
            Logger.print_to_output("W: " .. message)
        end
    end
    local function error(message)
        if Logger.log_level_filter <= Logger.LoggingLevel.ERROR then
            Logger.print_to_output("E: " .. message)
        end
    end

    return {
        debug = debug,
        info = info,
        warn = warn,
        error = error,
    }
end)

_G.Logger = Logger
return _G.Logger
