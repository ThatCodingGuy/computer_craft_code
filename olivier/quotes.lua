--Get historical quotes of the day

local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollHandler = dofile("./gitlib/turboCo/ui/scrollHandler.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local Page = dofile("./gitlib/turboCo/ui/page.lua")
local PageViewManager = dofile("./gitlib/turboCo/ui/pageViewManager.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

local pageNumber = 0
local numResults = 4
local numPages = nil

local pageCounterContent = nil

local screen = peripheral.find("monitor")
screen.clear()

local eventHandler = EventHandler.create()

local screenTopBuffer = ScreenBuffer.createFullScreenAtTopWithHeight{screen=screen, height=3}
screenTopBuffer.writeFullLineThenResetCursor{text=" ", color=colors.lightBlue, bgColor=colors.gray}
screenTopBuffer.writeCenterLn{text="Quotes of the Day", color=colors.lightBlue, bgColor=colors.gray}
screenTopBuffer.writeFullLineLn{text="-", color=colors.lightBlue, bgColor=colors.gray}
screenTopBuffer.render()

local screenScrollingBuffer = ScreenBuffer.createFullScreenFromTopAndBottom{screen=screen, topOffset=3, bottomOffset=1}
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
    screenBuffer.writeCenterLn{text=quote['title'], color=color}
    screenBuffer.writeCenterLn{text="Date: " .. quote['date']}
    screenBuffer.ln()
    screenBuffer.writeWrapLn{text=quote['content'], color=color}
    screenBuffer.ln()
    screenBuffer.writeLeftLn{text="Author: " .. quote['author']}
    screenBuffer.ln()
  end
end

function writeQuotes(screenBuffer)
  quotesResponse = getQuotes()
  if quotesResponse ~= nil then
    quotes = quotesResponse['quotes']
    for _,quote in pairs(quotes) do
      writeQuote(screenBuffer, quote)
    end
  end
end

function getPreviousQuotesAndSwitchPage()
  if pageNumber > 1 then
    pageNumber = pageNumber - 1
  end
  pageViewManager.switchToPreviousPage()
  pageCounterContent.updateText(" %s/%s ", pageNumber, numPages)
end

function getNextQuotesAndSwitchPage()
  if pageNumber == 0 or pageNumber < numPages then
    pageNumber = pageNumber + 1
  end
  local newPageScreenBuffer = ScreenBuffer.createFullScreenFromTopAndBottom{screen=screen, topOffset=3, bottomOffset=1}
  local newPage = Page.create{screenBuffer=newPageScreenBuffer}
  pageViewManager.addPage(newPage)
  writeQuotes(newPageScreenBuffer)
  pageViewManager.switchToNextPage()
  pageCounterContent.updateText(" %s/%s ", pageNumber, numPages)
end

local screenBottomBuffer = ScreenBuffer.createFullScreenAtBottomWithHeight{screen=screen, height=1}
screenBottomBuffer.writeFullLineThenResetCursor{text=" ", color=colors.lightBlue, bgColor=colors.gray}

local prevButton = Button.create{screenBuffer=screenBottomBuffer,
  eventHandler=eventHandler, 
  text="<-Prev", 
  textColor=colors.gray, 
  bgColor=colors.lightBlue, 
  leftClickCallback=getPreviousQuotesAndSwitchPage}

pageCounterContent = ScreenContent.create{
  screenBuffer=screenBottomBuffer,
  screenBufferWriteFunc=screenBottomBuffer.writeCenter,
  text=" 0/0 ",
  textColor=colors.gray,
  bgColor=colors.lightBlue
}
  
local nextButton = Button.create{screenBuffer=screenBottomBuffer,
  screenBufferWriteFunc=screenBottomBuffer.writeRight,
  eventHandler=eventHandler, 
  text="Next->", 
  textColor=colors.gray, 
  bgColor=colors.lightBlue, 
  leftClickCallback=getNextQuotesAndSwitchPage
}
screenBottomBuffer.render()

--Get the initial quote
getNextQuotesAndSwitchPage(screenScrollingBuffer)
pageViewManager.addPage(Page.create{screenBuffer=screenScrollingBuffer})
pageViewManager.switchToNextPage()

local exitHandler = ExitHandler.createFromScreens({term.current(), screen}, eventHandler)

print("Press UP to scroll up, and DOWN to scroll down")
print("Press LEFT to scroll left, and RIGHT to scroll right")
print("Press PAGE_UP to page up, and PAGE_DOWN to page down")
print("Press END to exit cleanly")

--Loops until exit handle quits it
eventHandler.pullEvents()