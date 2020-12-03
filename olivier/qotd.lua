--qotd = Quote of the Day
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

local screen = peripheral.find("monitor")
local screenBuffer = ScreenBuffer.createFullScreen{screen=screen}

function getQuoteOfTheDay()
  local worked, quoteResponse, responseStr, responseObject = false, nil, nil, nil
  worked, quoteResponse = pcall(function() return http.get("https://interactive-cv-api.herokuapp.com/quotes/today", {["Content-Type"] = "application/json"}) end)
  if not worked then
    print(quoteResponse)
    return
  end
  worked, responseStr = pcall(quoteResponse.readAll)
  if not worked then
    print(responseStr)
    return
  end
  worked, responseObject = pcall(textutils.unserializeJSON, responseStr)
  if not worked then
    print(responseObject)
    return
  end
  return responseObject['quote']
end

function displayQuote(quote)
  if quote then
    local color = categoryToColorMap[quote['category']]
    screenBuffer.clear()
    screenBuffer.writeCenterLn{text="TurboCo Motivational Billboard"}
    screenBuffer.ln()
    screenBuffer.writeCenterLn{text=quote['title'], color=color}
    screenBuffer.writeCenterLn{text="Date: " .. quote['date']}
    screenBuffer.ln()
    screenBuffer.writeWrapLn{text=quote['content'], color=color}
    screenBuffer.ln()
    screenBuffer.writeLeftLn{text="Author: " .. quote['author']}
    screenBuffer.ln()
  end
end

local timePassed = 0
local quote = nil

while true do
  --Either it's time for a new quote, or the previous request failed
  if quote == nil then
    quote = getQuoteOfTheDay()
  end
  displayQuote(quote)
  sleep(30) --Refresh monitor once per 30 seconds because apparently text doesn't stick long
  timePassed = timePassed + 30
  --Get a new quote once per hour
  if timePassed >= 3600 then
    timePassed = 0
    quote = nil
  end
end






