--Get historical quotes of the day

local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/screenBuffer.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

local running = true

local monitor = peripheral.find("monitor")
monitor.write("   TEST   ")
monitor.setCursorPos(1,2)
monitor.write("----------")

local screenBuffer = ScreenBuffer.createFullScreenFromTop(monitor, 2)

function getQuotes()
  local worked, quoteResponse, responseStr, responseObject = false, nil, nil, nil
  worked, quoteResponse = pcall(function() return http.get("https://interactive-cv-api.herokuapp.com/quotes", {["Content-Type"] = "application/json"}) end)
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
    screenBuffer.scrollUp()
  elseif key == keys.down then
    screenBuffer.scrollDown()
  elseif key == keys.left then
    screenBuffer.scrollLeft()
  elseif key == keys.right then
    screenBuffer.scrollRight()
  elseif key == keys.pageUp then
    screenBuffer.pageUp()
  elseif key == keys.pageDown then
    screenBuffer.pageDown()
  elseif key == keys.x then
    screenBuffer.clear()
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

local eventHandler = EventHandler.create()

eventHandler.addHandle("key", handleKey)

while running do
  eventHandler.pullEvent()
end