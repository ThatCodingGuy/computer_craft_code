local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class
local enum = lua_helpers.enum

local LoggingLevel = enum {
    "DEBUG", "INFO", "WARNING", "ERROR"
}
local log_file_path = "./log.out"
local print_to_output = print
local log_level_filter = LoggingLevel.WARNING

--Set print_to_output to this to log to a file instead
local log_to_file = function(...)
    local f = fs.open(log_file_path, 'a')
    local logStr = lua_helpers.join(arg)
    f.writeLine(logStr)
    f.close()
end

-- Make sure there's a single global instance of the Logger module.
if _G.Logger ~= nil then
    return _G.Logger
end

--- A simple logger that allows writing messages to stdout.
-- @param print_to_output An optional function that prints the contents to whatever output should be
-- used. It should accept varargs as parameters.
Logger = class({
    LoggingLevel = LoggingLevel,
    print_to_output = print_to_output,
    log_to_file = log_to_file,
    log_level_filter = log_level_filter,

}, function()
    local function log(level, ...)
        if Logger.log_level_filter <= level then
            Logger.print_to_output(Logger.LoggingLevel[level], ": ", ...)
        end
    end

    return {
        debug = function(...)
            log(Logger.LoggingLevel.DEBUG, ...)
        end,
        info = function(...)
            log(Logger.LoggingLevel.INFO, ...)
        end,
        warn = function(...)
            log(Logger.LoggingLevel.WARNING, ...)
        end,
        error = function(...)
            log(Logger.LoggingLevel.ERROR, ...)
        end,
    }
end)

_G.Logger = Logger
return _G.Logger
