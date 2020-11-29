--Get historical quotes of the day

os.loadAPI("./gitlib/turboCo/json.lua")
os.loadAPI("./gitlib/turboCo/logger.lua")
os.loadAPI("./gitlib/turboCo/monitor.lua")
os.loadAPI("./gitlib/turboCo/eventHandler.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}
local screen = monitor.getInstance()
monitor.clear(screen)

local running = true

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
    monitor.writeWrapLn(screen, quote['content'], color)
    monitor.ln(screen)
    monitor.writeLeftLn(screen, "Author: " .. quote['author'])
    monitor.ln(screen)
  end
end


function handleKey(eventData)
  local key = eventData[2]
  if key == keys.up then
    monitor.scrollUp(screen)
  elseif key == keys.down then
    monitor.scrollDown(screen)
  elseif key == keys.left then
    monitor.scrollLeft(screen)
  elseif key == keys.right then
    monitor.scrollRight(screen)
  elseif key == keys.pageUp then
    monitor.pageUp(screen)
  elseif key == keys.pageDown then
    monitor.pageDown(screen)
  elseif key == keys.x then
    monitor.clear(screen)
    running = false
  end
end


quotes = getQuotes()
if quotes ~= nil then
  for quote in pairs(quotes) do
    displayQuote(screen, quotes[quote])
  end
end

print("Press UP to scroll up, and DOWN to scroll down")
print("Press LEFT to scroll left, and RIGHT to scroll right")
print("Press PAGE_UP to page up, and PAGE_DOWN to page down")
print("Press X to exit cleanly")

eventHandler.addHandle("key", handleKey)

while running do
  eventHandle.pullEvent()
end