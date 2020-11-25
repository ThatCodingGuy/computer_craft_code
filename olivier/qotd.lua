--qotd = Quote of the Day

os.loadAPI("./gitlib/turboCo/json.lua")
os.loadAPI("./gitlib/turboCo/logger.lua")
os.loadAPI("./gitlib/turboCo/monitor.lua")

local categoryToColorMap = {}
categoryToColorMap['inspire'] = colors.green
categoryToColorMap['management'] = colors.yellow
categoryToColorMap['funny'] = colors.orange
categoryToColorMap['life'] = colors.cyan
categoryToColorMap['art'] = colors.blue

function getQuoteOfTheDay()
  local quoteResponse, err = pcall(http.get("https://interactive-cv-api.herokuapp.com/quotes/today", {["Content-Type"] = "application/json"}))
  if err then
    logger.log(err)
  end
  if quoteResponse ~= nil then
    local responseStr,err = pcall(quoteResponse.readAll())
    if err then
      logger.log(err)
    end
    if responseStr ~= nil then
      local responseObject,err = pcall(json.decode(responseStr))
      if err then
        logger.log(err)
      end
      if responseObject ~= nil then
        return responseObject['quote']
      end
    end
  end
end

function displayQuote(screen, quote)
  if quote then
    local color = categoryToColorMap[quote['category']]
    monitor.clear(screen)
    monitor.writeCenterLn(screen, "TurboCo Motivational Billboard")
    monitor.ln(screen)
    monitor.writeCenterLn(screen, quote['title'], color)
    monitor.ln(screen)
    monitor.writeLn(screen, quote['content'], color)
    monitor.ln(screen)
    monitor.writeLeftLn(screen, "Author: " .. quote['author'])
    monitor.writeLeftLn(screen, "Date: " .. quote['date'])
  end
end

local timePassed = 0
local screen = monitor.getInstance()
local quote = nil

while true do
  --Either it's time for a new quote, or the previous request failed
  if quote == nil then
    quote = getQuoteOfTheDay()
  end
  displayQuote(screen, quote)
  sleep(30) --Refresh monitor once per 30 seconds because apparently text doesn't stick long
  timePassed = timePassed + 30
  --Get a new quote once per hour
  if timePassed >= 3600 then
    timePassed = 0
    quote = nil
  end
end






