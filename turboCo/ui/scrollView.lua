local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollBar = dofile("./gitlib/turboCo/ui/scrollBar.lua")
local logger = dofile('./gitlib/turboCo/logger.lua').new()

local function createFromScreenBufferAndScrollBar(args)
  logger.debug("args.scrollBar: ", args.scrollBar)
  local self = {
    eventHandler = args.eventHandler,
    screenBuffer=args.screenBuffer,
    scrollBar=args.scrollBar,
    mouseScrollHandleId = nil
  }

  local wasScrolledOn = function(x, y)
    local screenStartingPos = self.screenBuffer.getScreenStartingPos()
    local width,height = self.screenBuffer.getWidth(), self.screenBuffer.getHeight()
    local maxPosX, maxPosY = screenStartingPos.x + width - 1, screenStartingPos.y + height - 1
    return x >= screenStartingPos.x and x <= maxPosX and y >= screenStartingPos.y and y <= maxPosY
  end
  
  local mouseScrolled = function(eventData)
    local scrollDirection, x, y = eventData[2], eventData[3], eventData[4]
    if wasScrolledOn(x, y) then
      if scrollDirection > 0 then
        self.screenBuffer.scrollDown()
      else
        self.screenBuffer.scrollUp()
      end
    end
  end

  local getScreenBuffer = function()
    return self.screenBuffer
  end

  local makeActive = function()
    if not self.mouseScrollHandleId then
      self.scrollBar.makeActive()
      self.mouseScrollHandleId = self.eventHandler.addHandle("mouse_scroll", mouseScrolled)
    end
  end

  local makeInactive = function()
    self.scrollBar.makeInactive()
    if self.mouseScrollHandleId then
      self.eventHandler.removeHandle(self.mouseScrollHandleId)
      self.mouseScrollHandleId = nil
    end
  end

  makeActive()

  return {
    getScreenBuffer=getScreenBuffer,
    makeActive=makeActive,
    makeInactive=makeInactive
  }
end

local function create(args)
  local screen, eventHandler, xStartingScreenPos, yStartingScreenPos, width, height, textColor, bgColor = 
        args.screen, args.eventHandler, args.xStartingScreenPos, args.yStartingScreenPos,
        args.width, args.height, args.textColor, args.bgColor

  local screenBuffer = ScreenBuffer.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos,
    yStartingScreenPos = yStartingScreenPos,
    width = width - 1,
    height = height,
    textColor = textColor,
    bgColor = bgColor
  }

  local scrollBar = ScrollBar.create{
    screen = screen,
    eventHandler = eventHandler,
    trackingScreenBuffer = screenBuffer,
    xStartingScreenPos = xStartingScreenPos + width - 1,
    yStartingScreenPos = yStartingScreenPos,
    height = height
  }

  return createFromScreenBufferAndScrollBar{eventHandler=eventHandler, screenBuffer=screenBuffer, scrollBar=scrollBar}
end

local function createFromOverrides(args)
  local screen, eventHandler, textColor, bgColor, leftOffset, rightOffset, topOffset, bottomOffset = args.screen,
    args.eventHandler, args.textColor, args.bgColor, args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0,args.bottomOffset or 0
  local width,_ = screen.getSize()

  local screenBuffer = ScreenBuffer.createFromOverrides{
    screen=screen,
    eventHandler=eventHandler,
    textColor=textColor,
    bgColor=bgColor,
    leftOffset=leftOffset,
    rightOffset=rightOffset + 1,
    topOffset=topOffset,
    bottomOffset=bottomOffset,
  }

  local scrollBar = ScrollBar.createFromOverrides{
    screen=screen,
    eventHandler=eventHandler,
    trackingScreenBuffer=screenBuffer,
    leftOffset=width - 1 - rightOffset,
    topOffset=topOffset,
    bottomOffset=bottomOffset
  }
  logger.debug("scrollBar: ", scrollBar)

  return createFromScreenBufferAndScrollBar{eventHandler=eventHandler, screenBuffer=screenBuffer, scrollBar=scrollBar}
end

return {
  create=create,
  createFromOverrides=createFromOverrides
}