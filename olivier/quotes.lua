--Get historical quotes of the day

os.loadAPI("./gitlib/turboCo/json.lua")
os.loadAPI("./gitlib/turboCo/logger.lua")
os.loadAPI("./gitlib/turboCo/monitor.lua")

local categoryToColorMap = {}
categoryToColorMap['inspire'] = colors.green
categoryToColorMap['management'] = colors.yellow
categoryToColorMap['funny'] = colors.orange
categoryToColorMap['life'] = colors.cyan
categoryToColorMap['art'] = colors.blue

function getQuotes()
  local worked, quoteResponse, responseStr, responseObject = false, nil, nil, nil
  worked, quoteResponse = pcall(function() return http.get("https://interactive-cv-api.herokuapp.com/quotes", {["Content-Type"] = "application/json"}) end)
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
  return responseObject['quotes']
end

function displayQuote(screen, quote)
  if quote then
    local color = categoryToColorMap[quote['category']]
    monitor.writeCenterLn(screen, quote['title'], color)
    monitor.writeCenterLn(screen, "Date: " .. quote['date'])
    monitor.ln(screen)
    monitor.writeLn(screen, quote['content'], color)
    monitor.ln(screen)
    monitor.writeLeftLn(screen, "Author: " .. quote['author'])
    monitor.ln(screen)
  end
end

local screen = monitor.getInstance()
monitor.clear(screen)

quotes = getQuotes()
if quotes ~= nil then
  for quote in pairs(quotes) do
    displayQuote(screen, quotes[quote])
  end
end

print("Press UP to scroll up, and DOWN to scroll down")

while true do
  local event, key, isHeld = os.pullEvent("key")
  local keyName = keys.getName( key )
  if key == keys.up then
    screen.scroll(-1)
  elseif key == keys.down then
    screen.scroll(1)
  end
end