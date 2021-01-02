local lua_helpers = dofile('./gitlib/turboCo/lua_helpers.lua')
local logger = dofile('./gitlib/turboCo/logger.lua').new()

local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")

local function create(args)

  local self = {
    screen = args.screen,
    eventHandler = args.eventHandler,
    trackingScreenBuffer = args.trackingScreenBuffer,
    trackingScreenBufferDimensions = args.trackingScreenBuffer.getBufferDimensions(),
    scrollBarScreenBuffer = ScreenBuffer.create{
      screen = args.screen,
      xStartingScreenPos = args.xStartingScreenPos,
      yStartingScreenPos = args.yStartingScreenPos,
      width = 1,
      height = args.height,
    },
    scrollUpButton = nil,
    scrollBarContent = nil,
    scrollDownButton = nil,
    screenStartingPos = { x=args.xStartingScreenPos, y=args.yStartingScreenPos },
    height = args.height,
    emptyBarColor = args.emptyBarColor or colors.lightBlue,
    barColor = args.barColor or colors.white,
    monitorTouchHandlerId = nil,
    leftMouseDownHandlerId = nil,
    leftMouseUpHandlerId = nil,
    leftMouseDragHandlerId = nil,
    leftMouseClickScreenPos = nil
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

  local wasBarClicked = function(x, y)
    local barStartingIndex, barLastIndex = getScrollableBarIndexes()
    local barStartingY = self.screenStartingPos.y + barStartingIndex - 1
    local barEndingY = self.screenStartingPos.y + barLastIndex - 1
    return y >= barStartingY and y <= barEndingY and x == self.screenStartingPos.x
  end

  local mouseDownHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if button == 1 and wasBarClicked(x, y) then
      self.leftMouseDragScreenPos = {x = x, y = y}
    end
  end

  local mouseUpHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if button == 1 then
      self.leftMouseDragScreenPos = nil
    end
  end

  local mouseDragHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    local barStartingIndex, barEndingIndex = getScrollableBarIndexes()
    local barHeight = barEndingIndex - barStartingIndex + 1
    local singleBarUnitHeight = math.floor(self.trackingScreenBufferDimensions.height / (getFullBarLength() - barHeight))
    if button == 1 and self.leftMouseDragScreenPos then
      local distanceY = self.leftMouseDragScreenPos.y - y
      local scrollTimes = singleBarUnitHeight * math.abs(distanceY)
      for i=1,scrollTimes do
        if distanceY < 0 then
          self.trackingScreenBuffer.scrollDown()
        else
          self.trackingScreenBuffer.scrollUp()
        end
      end
      self.leftMouseDragScreenPos = {x = x, y = y}
    end
  end

  local monitorTouchHandler = function(eventData)
    --TODO
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

  local bText, bColors = getBarBlits()
  self.scrollBarContent = ScreenContent.create{
    screenBuffer = self.scrollBarScreenBuffer,
    screenBufferWriteFunc = self.scrollBarScreenBuffer.writeWrap,
    text = bText,
    bgColors = bColors
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

  local render = function()
    self.scrollBarScreenBuffer.render()
  end

  local makeActive = function()
    if not self.leftMouseDownHandlerId then
      self.monitorTouchHandlerId = self.eventHandler.addHandle("mouse_click", mouseDownHandler)
      self.leftMouseDownHandlerId = self.eventHandler.addHandle("mouse_click", mouseDownHandler)
      self.leftMouseUpHandlerId = self.eventHandler.addHandle("mouse_up", mouseUpHandler)
      self.leftMouseDragHandlerId = self.eventHandler.addHandle("mouse_drag", mouseDragHandler)
    end
    self.scrollUpButton.makeActive()
    self.scrollDownButton.makeActive()
    render()
  end

  local makeInactive = function()
    if self.leftMouseDownHandlerId ~= nil then
      self.eventHandler.removeHandle(self.leftMouseDownHandlerId)
      self.eventHandler.removeHandle(self.leftMouseUpHandlerId)
      self.eventHandler.removeHandle(self.leftMouseDragHandlerId)

      self.leftMouseDownHandlerId = nil
      self.leftMouseUpHandlerId = nil
      self.leftMouseDragHandlerId = nil
    end
    
    self.scrollUpButton.makeInactive()
    self.scrollDownButton.makeInactive()
  end

  local screenBufferCallback = function(callbackData)
    self.trackingScreenBufferDimensions = callbackData.dimensions
    local barText, bgColors = getBarBlits()
    self.scrollBarContent.updateText{text=barText, bgColors=bgColors, render=true}
  end

  self.trackingScreenBuffer.registerCallback(screenBufferCallback)
  makeActive()
  

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