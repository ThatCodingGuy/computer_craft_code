local View = dofile("./gitlib/turboCo/ui/view.lua")
local ScrollBar = dofile("./gitlib/turboCo/ui/scrollBar.lua")
local logger = dofile('./gitlib/turboCo/logger.lua').new()

local function createFromScreenBufferAndScrollBar(args)
  local self = {
    eventHandler = args.eventHandler,
    view=args.view,
    scrollBar=args.scrollBar,
    mouseScrollHandleId = nil
  }

  local wasScrolledOn = function(x, y)
    local screenStartingPos = self.view.screenBuffer.getScreenStartingPos()
    local width,height = self.view.screenBuffer.getWidth(), self.view.screenBuffer.getHeight()
    local maxPosX, maxPosY = screenStartingPos.x + width - 1, screenStartingPos.y + height - 1
    return x >= screenStartingPos.x and x <= maxPosX and y >= screenStartingPos.y and y <= maxPosY
  end
  
  local mouseScrolled = function(eventData)
    local scrollDirection, x, y = eventData[2], eventData[3], eventData[4]
    if wasScrolledOn(x, y) then
      if scrollDirection > 0 then
        self.view.screenBuffer.scrollDown()
      else
        self.view.screenBuffer.scrollUp()
      end
    end
  end

  local makeActive = function()
    if not self.mouseScrollHandleId then
      self.scrollBar.makeActive()
      self.mouseScrollHandleId = self.eventHandler.addHandle("mouse_scroll", mouseScrolled)
    end
    self.view.makeActive()
  end

  local makeInactive = function()
    self.scrollBar.makeInactive()
    self.view.makeInactive()
    if self.mouseScrollHandleId then
      self.eventHandler.removeHandle(self.mouseScrollHandleId)
      self.mouseScrollHandleId = nil
    end
  end

  makeActive()

  return {
    screenBuffer=self.view.screenBuffer,
    addClickable=self.view.addClickable,
    makeActive=makeActive,
    makeInactive=makeInactive
  }
end

local function create(args)
  local screen, eventHandler, xStartingScreenPos, yStartingScreenPos, width, height, textColor, bgColor = 
        args.screen, args.eventHandler, args.xStartingScreenPos, args.yStartingScreenPos,
        args.width, args.height, args.textColor, args.bgColor

  local view = View.create{
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
    trackingScreenBuffer = view.screenBuffer,
    xStartingScreenPos = xStartingScreenPos + width - 1,
    yStartingScreenPos = yStartingScreenPos,
    height = height
  }

  return createFromScreenBufferAndScrollBar{eventHandler=eventHandler, view=view, scrollBar=scrollBar}
end

local function createFromOverrides(args)
  local screen, eventHandler, textColor, bgColor, leftOffset, rightOffset, topOffset, bottomOffset = args.screen,
    args.eventHandler, args.textColor, args.bgColor, args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0,args.bottomOffset or 0
  local width,_ = screen.getSize()

  local view = View.createFromOverrides{
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
    trackingScreenBuffer=view.screenBuffer,
    leftOffset=width - 1 - rightOffset,
    topOffset=topOffset,
    bottomOffset=bottomOffset
  }

  return createFromScreenBufferAndScrollBar{eventHandler=eventHandler, view=view, scrollBar=scrollBar}
end

return {
  create=create,
  createFromOverrides=createFromOverrides
}