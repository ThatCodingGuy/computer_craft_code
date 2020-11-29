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

local screen = peripheral.find("monitor")
screen.write("   TEST   ")
screen.setCursorPos(1,2)
screen.write("----------")

local screenBuffer = ScreenBuffer.createFullScreenFromTop(screen, 2)

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

function displayQuote(quote)
  if quote then
    local color = categoryToColorMap[quote['category']]
    screenBuffer.writeCenterLn(quote['title'], color)
    screenBuffer.writeCenterLn("Date: " .. quote['date'])
    screenBuffer.ln()
    screenBuffer.writeWrapLn(quote['content'], color)
    screenBuffer.ln()
    screenBuffer.writeLeftLn("Author: " .. quote['author'])
    screenBuffer.ln()
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
    displayQuote(quotes[quote])
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