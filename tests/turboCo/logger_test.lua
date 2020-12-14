local Logger = dofile("./gitlib/turboCo/logger.lua")

describe("Logger", function()
    local last_logged_text
    Logger.print_to_output = function(text)
        last_logged_text = text
    end

    local logger = Logger.new()

    it("should always return same module", function()
        assert.are.equal(Logger, dofile("./gitlib/turboCo/logger.lua"))
    end)

    it("should log to output", function()
        Logger.log_level_filter = Logger.LoggingLevel.DEBUG

        logger.debug("debug text")
        assert.are.equal("D: debug text", last_logged_text)
        logger.info("info text")
        assert.are.equal("I: info text", last_logged_text)
        logger.warn("warning text")
        assert.are.equal("W: warning text", last_logged_text)
        logger.error("error text")
        assert.are.equal("E: error text", last_logged_text)
    end)

    it("should not log below logging level", function()
        Logger.log_level_filter = Logger.LoggingLevel.ERROR

        logger.error("error text")
        logger.debug("debug text")
        assert.are.equal("E: error text", last_logged_text)
        logger.info("info text")
        assert.are.equal("E: error text", last_logged_text)
        logger.warn("warning text")
        assert.are.equal("E: error text", last_logged_text)
    end)
end)
