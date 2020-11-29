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
  local worked, quoteResponse, responseStr, responseObject = false, nil, nil, nil
  worked, quoteResponse = pcall(function() return http.get("https://interactive-cv-api.herokuapp.com/quotes/today", {["Content-Type"] = "application/json"}) end)
  if not worked then
    logger.log(quoteResponse)
    return
  end
  worked, responseStr = pcall(quoteResponse.readAll)
  if not worked then
    logger.log(responseStr)
    return
  end
  worked, responseObject = pcall(json.decode, responseStr)
  if not worked then
    logger.log(responseObject)
    return
  end
  return responseObject['quote']
end

function displayQuote(screen, quote)
  if quote then
    local color = categoryToColorMap[quote['category']]
    monitor.clear(screen)
    monitor.writeCenterLn(screen, "TurboCo Motivational Billboard")
    monitor.ln(screen)
    monitor.writeCenterLn(screen, quote['title'], color)
    monitor.writeCenterLn(screen, "Date: " .. quote['date'])
    monitor.ln(screen)
    monitor.writeWrapLn(screen, quote['content'], color)
    monitor.ln(screen)
    monitor.writeLeftLn(screen, "Author: " .. quote['author'])
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






