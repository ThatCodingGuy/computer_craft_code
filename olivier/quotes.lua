--Get historical quotes of the day

local eventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua").create()
local ScrollView = dofile("./gitlib/turboCo/ui/scrollView.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local View = dofile("./gitlib/turboCo/ui/view.lua")
local PageManagerView = dofile("./gitlib/turboCo/ui/pageManagerView.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")
local httpManager = dofile("./gitlib/turboCo/httpManager.lua").create{eventHandler=eventHandler}
local Logger = dofile("./gitlib/turboCo/logger.lua")
local logger = Logger.new()
local loggingLevel = "ERROR"
if LOGGING_LEVEL then
  loggingLevel = LOGGING_LEVEL
end
Logger.print_to_output = Logger.log_to_file
Logger.log_level_filter = Logger.LoggingLevel[loggingLevel]

local json = dofile("./gitlib/turboCo/json.lua")

local categoryToColorMap = {
  inspire = colors.green,
  management = colors.yellow,
  funny = colors.orange,
  life = colors.cyan,
  art = colors.blue
}

local numResults = 10
local numPages = nil

local pageManagerView = nil
local pageCounterContent = nil
local screenTopView = nil
local screenBottomView = nil

local tArgs = { ... }
local screen = nil
if #tArgs > 0 then
  local screenSide = tArgs[1]
  if screenSide == "term" then
    screen = term.current()
  else
    screen = peripheral.wrap(screenSide)
  end
end

if screen == nil then
  screen = peripheral.find("monitor")
  if screen == nil then
    screen = term.current()
  end
end
screen.clear()
local width,height = screen.getSize()

function writeQuote(screenBuffer, quote)
  if quote then
    local color = categoryToColorMap[quote['category']]
    screenBuffer.writeCenterLn{text=quote['title'], textColor=color}
    screenBuffer.writeCenterLn{text="Date: " .. quote['date']}
    screenBuffer.ln()
    screenBuffer.writeWrapLn{text=quote['content'], textColor=color}
    screenBuffer.ln()
    screenBuffer.writeLeftLn{text="Author: " .. quote['author']}
    screenBuffer.ln()
    screenBuffer.ln()
  end
end

function handleQuotesResponse(handle, extraArgs)
  local worked, responseStr, quotesResponse
  local screenBuffer = extraArgs.screenBuffer
  worked, responseStr = pcall(handle.readAll)
  if not worked then
    print(responseStr)
    return
  end
  worked, quotesResponse = pcall(json.decode, responseStr)
  if not worked then
    print(quotesResponse)
    return
  end
  numPages = quotesResponse['num_pages']
  if quotesResponse ~= nil then
    quotes = quotesResponse['quotes']
    screenBuffer.ln()
    for _,quote in pairs(quotes) do
      writeQuote(screenBuffer, quote)
    end
  end
  screenBuffer.render()
end

function getAndWriteQuotes(screenBuffer, pageNumber, successCallback)
  local url = string.format("https://interactive-cv-api.herokuapp.com/quotes?page_number=%s&num_results=%s", pageNumber, numResults)
  local fullSuccessCallback = function(handle, args)
    handleQuotesResponse(handle, args)
    if successCallback then
      successCallback()
    end
  end
  httpManager.get({url=url, headers={["Content-Type"] = "application/json"}, successCallback=fullSuccessCallback, extraArgs={screenBuffer=screenBuffer} })
end

function createPageTrackerString()
  local pageNumber = pageManagerView.getPageIndex()
  local numCharsMissing = #tostring(numPages) - #tostring(pageNumber)
  local pageNumberStr = tostring(pageNumber)
  for i=1,numCharsMissing do
    pageNumberStr = "0" .. pageNumberStr
  end
  return string.format(" %s/%s ", pageNumberStr, numPages)
end

function updatePageTracker()
  pageCounterContent.updateText{text=createPageTrackerString()}
  screenBottomView.screenBuffer.render()
end

function createNewQuotePage(successCallback)
  local newPageScrollView = ScrollView.createFromOverrides{screen=screen, eventHandler=eventHandler, topOffset=2, bottomOffset=1, bgColor=colors.black}
  pageManagerView.addPage(newPageScrollView)
  getAndWriteQuotes(newPageScrollView.screenBuffer, pageManagerView.getPageIndex() + 1, successCallback)
end

function createFirstPage()
  pageCounterContent = ScreenContent.create{
    screenBuffer=screenBottomView.screenBuffer,
    screenBufferWriteFunc=screenBottomView.screenBuffer.writeCenter,
    text=createPageTrackerString(),
    textColor=colors.gray,
    bgColor=colors.lightBlue
  }
  pageManagerView.switchToNextPage()
  screenBottomView.screenBuffer.render()
end

function getFirstQuotes()
  createNewQuotePage(createFirstPage)
end

function getNextQuotes()
  if pageManagerView.getPageIndex() < numPages and not pageManagerView.hasNextPage() then
    createNewQuotePage()
  end
end

screenTopView = View.createFromOverrides{screen=screen, height=2, textColor=colors.lightBlue, bgColor=colors.gray}
screenTopView.screenBuffer.writeCenterLn{text="Quotes of the Day", textColor=colors.lightBlue, bgColor=colors.gray}
screenTopView.screenBuffer.writeFullLineLn{text="-", textColor=colors.lightBlue, bgColor=colors.gray}
screenTopView.screenBuffer.render()

screenBottomView = View.createFromOverrides{screen=screen, topOffset=height-1, textColor=colors.lightBlue, bgColor=colors.gray}
screenBottomView.screenBuffer.writeFullLineThenResetCursor{text=" ", }

pageManagerView = PageManagerView.create{
  eventHandler = eventHandler,
  leftButton = Button.create{
    screenBuffer=screenBottomView.screenBuffer,
    eventHandler=eventHandler,
    text=" <-Prev ",
    textColor=colors.gray,
    bgColor=colors.lightBlue
  },
  rightButton = Button.create{screenBuffer=screenBottomView.screenBuffer,
    screenBufferWriteFunc=screenBottomView.screenBuffer.writeRight,
    eventHandler=eventHandler,
    text=" Next-> ",
    textColor=colors.gray,
    bgColor=colors.lightBlue,
    leftClickCallback=getNextQuotes
  },
  postPageChangeCallback = updatePageTracker
}
screenBottomView.screenBuffer.render()

--Get the initial quote
getFirstQuotes()

local exitHandler = ExitHandler.createFromScreens({term.current(), screen}, eventHandler)

--Loops until exit handle quits it
eventHandler.pullEvents()