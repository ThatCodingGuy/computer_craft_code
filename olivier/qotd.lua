--qotd = Quote of the Day

os.loadAPI("./gitlib/turboCo/json.lua")
os.loadAPI("./gitlib/turboCo/monitor.lua")

function getQuoteOfTheDay()
  local quoteResponse = http.get("https://interactive-cv-api.herokuapp.com/quotes/today", {["Content-Type"] = "application/json"})
  if quoteResponse ~= nil then
    local responseStr = quoteResponse.readAll()
    if responseStr ~= nil then
      local responseObject = json.decode(responseStr)
      if responseObject ~= nil then
        return responseObject['quote']
      end
    end
  end
end

function displayQuote(screen, quote)
  monitor.clear(screen)
  monitor.writeCenterLn(screen, "TurboCo Motivational Billboard")
  monitor.ln(screen)
  monitor.writeCenterLn(screen, quote['title'])
  monitor.ln(screen)
  monitor.writeLn(screen, quote['content'])
  monitor.ln(screen)
  monitor.writeLeftLn(screen, "Author: " .. quote['author'])
  monitor.writeLeftLn(screen, "Date: " .. quote['date'])
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
  sleep(60) --Refresh monitor once per minute because apparently text doesn't stick long
  timePassed = timePassed + 60
  --Get a new quote once per hour
  if timePassed >= 3600 then
    timePassed = 0
    quote = nil
  end
end






