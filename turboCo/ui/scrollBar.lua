local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")

local function create(args)
  local screen, eventHandler, trackingScreenBuffer, xStartingScreenPos, yStartingScreenPos, height, emptyBarColor, barColor =
        args.screen, args.eventHandler, args.trackingScreenBuffer, args.xStartingScreenPos, args.yStartingScreenPos,
        args.height, args.barColor, args.trackerColor

  local scrollBarScreenBuffer = ScreenBuffer.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos,
    yStartingScreenPos = yStartingScreenPos,
    width = 1,
    height = height,
  }

  local self = {
    screen = screen,
    eventHandler = eventHandler,
    trackingScreenBuffer = trackingScreenBuffer,
    trackingScreenBufferDimensions = trackingScreenBuffer.getBufferDimensions(),
    scrollBarScreenBuffer = scrollBarScreenBuffer,
    scrollUpButton = nil,
    scrollBarContent = nil,
    scrollDownButton = nil,
    screenStartingPos = { x=xStartingScreenPos, y=yStartingScreenPos },
    height = height,
    emptyBarColor = emptyBarColor or colors.lightBlue,
    barColor = barColor or colors.white,
    monitorTouchKeyHandlerId = nil,
    leftClickKeyHandlerId = nil
  }

  local getFullBarLength = function()
    return self.height - 2
  end

  local getScrollableBarIndexes = function()
    local fullBarLength = getFullBarLength()
    local scrollableHeightRatio =  self.height / self.trackingScreenBufferDimensions.height
    if scrollableHeightRatio > 1 then
      --if > 1, then screenBuffer doesn't cover full screen yet
      scrollableHeightRatio = 1
    end
    local barHeight = math.floor(fullBarLength * scrollableHeightRatio)
    if barHeight == 0 then
      barHeight = 1
    end
    local screenRenderPos = self.trackingScreenBuffer.getRenderPos()
    local renderPosRatio = screenRenderPos.y / self.trackingScreenBufferDimensions.height
    local barMovableHeight = fullBarLength - barHeight
    local barStartingPosIndex = math.floor(barMovableHeight * renderPosRatio) + 1
    return barStartingPosIndex, barStartingPosIndex + barHeight - 1
  end


  local getBarBlits = function()
    local barText = ""
    local bgColors = ""
    local barStartingIndex, barLastIndex = getScrollableBarIndexes()
    for i=1,getFullBarLength() do
      barText = barText .. " "
      if i >= barStartingIndex and i <= barLastIndex then
        bgColors = bgColors .. self.trackingScreenBuffer.blitMap[self.barColor]
      else
        bgColors = bgColors .. self.trackingScreenBuffer.blitMap[self.emptyBarColor]
      end
    end
    return barText, bgColors
  end

  self.scrollUpButton = Button.create{
    screenBuffer=self.scrollBarScreenBuffer,
    screenBufferWriteFunc=self.scrollBarScreenBuffer.writeLn,
    eventHandler=self.eventHandler,
    text="^",
    textColor=colors.gray,
    bgColor=colors.cyan,
    leftClickCallback=self.trackingScreenBuffer.scrollUp
  }
  self.scrollUpButton.makeActive()

  local barText, bgColors = getBarBlits()
  self.scrollBarContent = ScreenContent.create{
    screenBuffer = self.scrollBarScreenBuffer,
    screenBufferWriteFunc = self.scrollBarScreenBuffer.writeWrap,
    text = barText,
    bgColors = bgColors
  }

  self.scrollDownButton = Button.create{
    screenBuffer=self.scrollBarScreenBuffer,
    screenBufferWriteFunc=self.scrollBarScreenBuffer.writeLn,
    eventHandler=self.eventHandler,
    text="v",
    textColor=colors.gray,
    bgColor=colors.cyan,
    leftClickCallback=self.trackingScreenBuffer.scrollDown
  }
  self.scrollDownButton.makeActive()

  --[[
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
  ]]

  local render = function()
    self.trackingScreenBuffer.render()
    self.scrollBarScreenBuffer.render()
  end

  local makeActive = function()
    self.scrollUpButton.makeActive()
    self.scrollDownButton.makeActive()
  end

  local makeInactive = function()
    self.scrollUpButton.makeInactive()
    self.scrollDownButton.makeInactive()
  end

  local screenBufferCallback = function(callbackData)
    self.trackingScreenBufferDimensions = callbackData.dimensions
    local barText, bgColors = getBarBlits()
    self.scrollBarContent.updateText{text=barText, bgColors=bgColors}
  end

  self.trackingScreenBuffer.registerCallback(screenBufferCallback)
  render()
  --self.eventHandler.addHandle("monitor_touch", )

  return {
    render=render,
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

local function createFromOverrides(args)
  local screen, eventHandler, trackingScreenBuffer, leftOffset, topOffset, bottomOffset = 
    args.screen, args.eventHandler, args.trackingScreenBuffer, args.leftOffset or 0,
    args.topOffset or 0, args.bottomOffset or 0

  local _,height = screen.getSize()
  heightOverride = height - topOffset - bottomOffset
  
  return create{
    screen=screen,
    eventHandler=eventHandler,
    trackingScreenBuffer=trackingScreenBuffer,
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