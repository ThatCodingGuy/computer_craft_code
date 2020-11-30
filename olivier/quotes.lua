--Get historical quotes of the day

local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollView = dofile("./gitlib/turboCo/ui/scrollView.lua")
local ExitHandle = dofile("./gitlib/turboCo/ui/exitHandle.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

local screen = peripheral.find("monitor")
screen.clear()

local eventHandler = EventHandler.create()

local screenTopBuffer = ScreenBuffer.createFullScreenAtTopWithHeight(screen, 3)
screenTopBuffer.writeFullLineThenResetCursor(" ", colors.lightBlue, colors.gray)
screenTopBuffer.writeCenterLn("Quotes of the Day", colors.lightBlue, colors.gray)
screenTopBuffer.writeFullLineLn("-", colors.lightBlue, colors.gray)

local screenScrollingBuffer = ScreenBuffer.createFullScreenFromTop(screen, 3)
local scrollView = ScrollView.create(screenScrollingBuffer, eventHandler)
scrollView.makeActive()

local exitHandle = ExitHandle.createFromScreens({term.current(), screen}, eventHandler)

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

quotes = getQuotes()
if quotes ~= nil then
  for quote in pairs(quotes) do
    displayQuote(quotes[quote])
  end
end

print("Press UP to scroll up, and DOWN to scroll down")
print("Press LEFT to scroll left, and RIGHT to scroll right")
print("Press PAGE_UP to page up, and PAGE_DOWN to page down")
print("Press END to exit cleanly")

--Loops until exit handle quits it
eventHandler.pullEvents()