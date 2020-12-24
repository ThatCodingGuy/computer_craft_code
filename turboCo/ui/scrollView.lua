local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollBar = dofile("./gitlib/turboCo/ui/scrollbar.lua")

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
  local screen, xStartingScreenPos, yStartingScreenPos, width, height, bgColor = 
        args.screen, args.xStartingScreenPos, args.yStartingScreenPos,
        args.width, args.height, args.bgColor

  local screenBuffer = ScreenBuffer.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos,
    yStartingScreenPos = yStartingScreenPos,
    width = width - 1,
    height = height,
    bgColor = bgColor
  }

  local scrollBar = ScrollBar.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos + width,
    yStartingScreenPos = yStartingScreenPos,
    height = height
  }

  return createFromScreenBufferAndScrollBar{screenBuffer=screenBuffer, scrollBar=scrollBar}
end

local function createFromOverrides(args)
  local screen, leftOffset, rightOffset, topOffset, bottomOffset = args.screen,
    args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0,args.bottomOffset or 0
  local width,height = screen.getSize()
  if widthOverride == nil then
    widthOverride = width - leftOffset - rightOffset
  end
  if heightOverride == nil then
    heightOverride = height - topOffset - bottomOffset
  end

  local screenBuffer = ScreenBuffer.createFromOverrides{
    screen=screen,
    leftOffset=leftOffset,
    rightOffset=rightOffset + 1,
    topOffset=topOffset,
    bottomOffset=bottomOffset,
  }

  local scrollBar = ScrollBar.create{
    screen=screen,

  }
  return createFromScreenBufferAndScrollBar{screenBuffer=screenBuffer, scrollBar=scrollBar}
end

return {
  create=create,
  createFromOverrides=createFromOverrides
}