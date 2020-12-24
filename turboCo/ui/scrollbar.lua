local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/button.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")

local function create(args)
  local screen, eventHandler, trackingScreenBuffer, xStartingScreenPos, yStartingScreenPos = 
        args.screen, args.eventHandler, args.trackingScreenBuffer,
        args.xStartingScreenPos, args.yStartingScreenPos

  local scrollBarScreenBuffer = ScreenBuffer.create{
    screen = screen,
    xStartingScreenPos = args.xStartingScreenPos,
    yStartingScreenPos = args.yStartingScreenPos,
    width = 1,
    height = args.height
  }

  local scrollUpButton = Button.create{
    screenBuffer=scrollBarScreenBuffer,
    eventHandler=eventHandler, 
    text="^",
    textColor=colors.black, 
    bgColor=colors.gray,
    leftClickCallback=trackingScreenBuffer.scrollUp
  }

  local scrollDownButton = Button.create{
    screenBuffer=scrollBarScreenBuffer,
    eventHandler=eventHandler, 
    text="v",
    textColor=colors.black, 
    bgColor=colors.gray,
    leftClickCallback=trackingScreenBuffer.scrollDown
  }

  local self = {
    screen = args.screen,
    eventHandler = args.eventHandler,
    trackingScreenBuffer = args.trackingScreenBuffer,
    trackingScreenBufferDimensions = { width = 0, height = 0 },
    scrollBarScreenBuffer = scrollBarScreenBuffer,
    scrollUpButton = scrollUpButton,
    scrollDownButton = scrollDownButton,
    screenStartingPos = { x=args.xStartingScreenPos, y=args.yStartingScreenPos },
    height = args.height,
    barColor = args.barColor or colors.gray,
    trackerColor = args.trackerColor or colors.white,
    monitorTouchKeyHandlerId = nil,
    leftClickKeyHandlerId = nil,
  }

  local getBarLength = function()
    return self.height - 2
  end

  local getBarText = function()
    local barText = ""
    for i=1,getBarLength() do
      barText = barText .. " "
    end
  end
  
  local barContent = ScreenContent.create{
    screenBuffer = scrollBarScreenBuffer,
    text = getBarText(),
    bgColor = colors.lightBlue
  }

  local monitorTouchHandler = function(eventData)
    local x, y = eventData[3], eventData[4]
    if wasClicked(x, y) then
      leftClick()
    end
  end

  local mouseClickHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if wasClicked(x, y) then
      if button == 1 then
        leftClick()
      end
    end
  end

  local wasBarClicked = function(x, y)
    local maxPosY = self.currentScreenPos.y + getBarLength() - 1
    return y >= self.currentScreenPos.y and y <= maxPosY and x == self.currentScreenPos.x
  end

  local render = function()
    self.trackingScreenBuffer.render()
    self.scrollBarScreenBuffer.render()
  end

  local makeActive = function()
    self.scrollUpButton.makeActive()
    self.scrollDownButton.makeActive()
  end

  local makeInactive = function ()
    self.scrollUpButton.makeInactive()
    self.scrollDownButton.makeInactive()
  end

  local barClickCallback = function()

  end

  local screenBufferCallback = function(callbackData)
    self.screenBufferDimensions = callbackData.dimensions
  end

  self.trackingScreenBuffer.registerCallback(screenBufferCallback)
  self.eventHandler.addHandle("monitor_touch", )

end

local function createFromOverrides(args)
  local screen, leftOffset, topOffset, bottomOffset = args.screen,
    args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0, args.bottomOffset or 0
  local _,height = screen.getSize()
  heightOverride = height - topOffset - bottomOffset
  
  return create{
    screen=screen, 
    xStartingScreenPos=1 + leftOffset,
    yStartingScreenPos=1 + topOffset,
    height=heightOverride,
    bgColor=args.bgColor,
    textColor=args.textColor
  }
end

return {
  create=create,
  createFromOverrides=createFromOverrides
}