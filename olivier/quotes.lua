--Get historical quotes of the day

local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

local running = true
local screen = peripheral.find("monitor")
screen.clear()

local screenTopBuffer = ScreenBuffer.createFullScreenAtTopWithHeight(screen, 2)
screenTopBuffer.writeCenterLn("Quotes of the Day", colors.lightBlue, colors.gray)
screenTopBuffer.writeFullLineLn("-", colors.lightBlue, colors.gray)

local screenScrollingBuffer = ScreenBuffer.createFullScreenFromTop(screen, 2)

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
    screenScrollingBuffer.writeCenterLn(quote['title'], color)
    screenScrollingBuffer.writeCenterLn("Date: " .. quote['date'])
    screenScrollingBuffer.ln()
    screenScrollingBuffer.writeWrapLn(quote['content'], color)
    screenScrollingBuffer.ln()
    screenScrollingBuffer.writeLeftLn("Author: " .. quote['author'])
    screenScrollingBuffer.ln()
  end
end

function handleKey(eventData)
  local key = eventData[2]
  if key == keys.up then
    screenScrollingBuffer.scrollUp()
  elseif key == keys.down then
    screenScrollingBuffer.scrollDown()
  elseif key == keys.left then
    screenScrollingBuffer.scrollLeft()
  elseif key == keys.right then
    screenScrollingBuffer.scrollRight()
  elseif key == keys.pageUp then
    screenScrollingBuffer.pageUp()
  elseif key == keys.pageDown then
    screenScrollingBuffer.pageDown()
  elseif key == keys.leftCtrl or key == keys.rightCtrl then
    screenScrollingBuffer.clear()
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
print("Press CTRL to exit cleanly")

local eventHandler = EventHandler.create()

eventHandler.addHandle("key", handleKey)

while running do
  eventHandler.pullEvent()
end