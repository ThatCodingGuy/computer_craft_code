--Get historical quotes of the day

local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollHandler = dofile("./gitlib/turboCo/ui/scrollHandler.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local Page = dofile("./gitlib/turboCo/ui/page.lua")
local PageViewManager = dofile("./gitlib/turboCo/ui/pageViewManager.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

pageNumber = 1
numResults = 4
numPages = nil

local screen = peripheral.find("monitor")
screen.clear()

local eventHandler = EventHandler.create()

local screenTopBuffer = ScreenBuffer.createFullScreenAtTopWithHeight(screen, 3)
screenTopBuffer.writeFullLineThenResetCursor(" ", colors.lightBlue, colors.gray)
screenTopBuffer.writeCenterLn("Quotes of the Day", colors.lightBlue, colors.gray)
screenTopBuffer.writeFullLineLn("-", colors.lightBlue, colors.gray)
screenTopBuffer.renderScreen()

local screenScrollingBuffer = ScreenBuffer.createFullScreenFromTopAndBottom(screen, 3, 1)
local scrollHandler = ScrollHandler.create(screenScrollingBuffer, eventHandler)
scrollHandler.makeActive()

local pageViewManager = PageViewManager.create(eventHandler)
pageViewManager.setScrollHandler(scrollHandler)

function getQuotes()
  local worked, quoteResponse, responseStr, responseObject = false, nil, nil, nil
  local url = string.format("https://interactive-cv-api.herokuapp.com/quotes?page_number=%s&num_results=%s", pageNumber, numResults)
  worked, quoteResponse = pcall(function() return http.get(url, {["Content-Type"] = "application/json"}) end)
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
  numPages = responseObject['num_pages']
  return responseObject
end

function writeQuote(screenBuffer, quote)
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

function writeQuotes(screenBuffer)
  quotesResponse = getQuotes()
  if quotesResponse ~= nil then
    quotes = quotesResponse['quotes']
    for quote in pairs(quotes) do
      writeQuote(screenBuffer, quotes[quote])
    end
  end
end

function getPreviousQuotesAndSwitchPage()
  if pageNumber > 1 then
    pageNumber = pageNumber - 1
  end
  pageViewManager.switchToPreviousPage()
end

function getNextQuotesAndSwitchPage()
  if pageNumber < numPages then
    pageNumber = pageNumber + 1
  end
  local newPageScreenBuffer = ScreenBuffer.createFullScreenFromTopAndBottom(screen, 3, 1)
  local newPage = Page.create(newPageScreenBuffer)
  pageViewManager.addPage(newPage)
  writeQuotes(newPageScreenBuffer)
  pageViewManager.switchToNextPage()
end

writeQuotes(screenScrollingBuffer)
pageViewManager.addPage(Page.create(screenScrollingBuffer))
pageViewManager.switchToNextPage()


local screenBottomBuffer = ScreenBuffer.createFullScreenAtBottomWithHeight(screen, 1)
screenBottomBuffer.writeFullLineThenResetCursor(" ", colors.lightBlue, colors.gray)
local prevButton = Button.create(screenBottomBuffer, eventHandler, "<-Prev", colors.gray, colors.lightBlue, getPreviousQuotesAndSwitchPage)
local nextButton = Button.create(screenBottomBuffer, eventHandler, "Next->", colors.gray, colors.lightBlue, getNextQuotesAndSwitchPage)
screenBottomBuffer.renderScreen()

local exitHandler = ExitHandler.createFromScreens({term.current(), screen}, eventHandler)

print("Press UP to scroll up, and DOWN to scroll down")
print("Press LEFT to scroll left, and RIGHT to scroll right")
print("Press PAGE_UP to page up, and PAGE_DOWN to page down")
print("Press END to exit cleanly")

--Loops until exit handle quits it
eventHandler.pullEvents()