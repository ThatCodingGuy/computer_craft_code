local Logger = dofile("./gitlib/turboCo/logger.lua")

describe("Logger", function()
    local last_logged_text
    Logger.print_to_output = function(...)
        last_logged_text = { ... }
    end

    local logger = Logger.new()

    it("should always return same module", function()
        assert.are.equal(Logger, dofile("./gitlib/turboCo/logger.lua"))
    end)

    it("should log to output", function()
        Logger.log_level_filter = Logger.LoggingLevel.DEBUG

        logger.debug("debug text ", 34)
        assert.are.same({ "DEBUG", ": ", "debug text ", 34 }, last_logged_text)
        logger.info("info text ", "too")
        assert.are.same({ "INFO", ": ", "info text ", "too" }, last_logged_text)
        logger.warn("warning text")
        assert.are.same({ "WARNING", ": ", "warning text" }, last_logged_text)
        logger.error("error text ", 1, 2, "trois")
        assert.are.same({ "ERROR", ": ", "error text ", 1, 2, "trois" }, last_logged_text)
    end)

    it("should not log below logging level", function()
        Logger.log_level_filter = Logger.LoggingLevel.ERROR

        logger.error("error text")
        logger.debug("debug text")
        assert.are.same({"ERROR", ": ", "error text"}, last_logged_text)
        logger.info("info text")
        assert.are.same({"ERROR", ": ", "error text"}, last_logged_text)
        logger.warn("warning text")
        assert.are.same({"ERROR", ": ", "error text"}, last_logged_text)
    end)
end)
