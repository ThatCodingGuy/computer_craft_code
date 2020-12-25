local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollBar = dofile("./gitlib/turboCo/ui/scrollBar.lua")

local function createFromScreenBufferAndScrollBar(args)
  local self = {
    screenBuffer=args.screenBuffer,
    scrollBar=args.scrollBar
  }

  local getScreenBuffer = function()
    return self.screenBuffer
  end

  local makeActive = function()
    self.scrollBar.makeActive()
  end

  local makeInactive = function()
    self.scrollBar.makeInactive()
  end

  return {
    getScreenBuffer=getScreenBuffer,
    makeActive=makeActive,
    makeInactive=makeInactive
  }
end

local function create(args)
  local screen, xStartingScreenPos, yStartingScreenPos, width, height, color, bgColor = 
        args.screen, args.xStartingScreenPos, args.yStartingScreenPos,
        args.width, args.height, args.color, args.bgColor

  local screenBuffer = ScreenBuffer.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos,
    yStartingScreenPos = yStartingScreenPos,
    width = width - 1,
    height = height,
    color = color,
    bgColor = bgColor
  }

  local scrollBar = ScrollBar.create{
    screen = screen,
    trackingScreenBuffer = screenBuffer,
    xStartingScreenPos = xStartingScreenPos + width - 1,
    yStartingScreenPos = yStartingScreenPos,
    height = height
  }

  return createFromScreenBufferAndScrollBar{screenBuffer=screenBuffer, scrollBar=scrollBar}
end

local function createFromOverrides(args)
  local screen, eventHandler, color, bgColor, leftOffset, rightOffset, topOffset, bottomOffset = args.screen,
    args.eventHandler, args.color, args.bgColor, args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0,args.bottomOffset or 0
  local width,_ = screen.getSize()

  local screenBuffer = ScreenBuffer.createFromOverrides{
    screen=screen,
    color=color,
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

  return createFromScreenBufferAndScrollBar{screenBuffer=screenBuffer, scrollBar=scrollBar}
end

return {
  create=create,
  createFromOverrides=createFromOverrides
}