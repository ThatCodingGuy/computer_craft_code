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
    leftMouseClickScreenPos = nil,
    draggingRoundingError = 0
  }

  local getFullBarLength = function()
    return self.height - 2
  end

  local getScrollableBarData = function()
    local fullBarLength = getFullBarLength()
    local dimensions = self.trackingScreenBuffer.getBufferDimensions()
    local screenRenderPos = self.trackingScreenBuffer.getRenderPos()
    local maxRenderPos = self.trackingScreenBuffer.getMaxRenderPos()
    local scrollableHeightRatio =  self.height / dimensions.height
    if scrollableHeightRatio >= 1 then
      -- if >= 1, then screenBuffer doesn't have content past the screen,
      -- si no need for scrolling
      return {
        startIndex=0,
        endIndex=0,
        heightReal=0,
        height=0,
      }
    end
    local barHeightReal = fullBarLength * scrollableHeightRatio
    local barHeight = math.floor(barHeightReal)
    if barHeight == 0 then
      barHeight = 1
    end
    local renderPosRatio = screenRenderPos.y / maxRenderPos.y
    local barMovableHeight = fullBarLength - barHeight
    local barStartingPosIndex = math.floor(barMovableHeight * renderPosRatio) + 1
    return {
      startIndex=barStartingPosIndex,
      endIndex=barStartingPosIndex + barHeight - 1,
      heightReal=barHeightReal,
      height=barHeight,
      barMovableHeight=barMovableHeight
    }
  end


  local getBarBlits = function()
    local barText = ""
    local bgColors = ""
    local scrollBarData = getScrollableBarData()
    for i=1,getFullBarLength() do
      barText = barText .. " "
      if i >= scrollBarData.startIndex and i <= scrollBarData.endIndex then
        bgColors = bgColors .. self.trackingScreenBuffer.blitMap[self.barColor]
      else
        bgColors = bgColors .. self.trackingScreenBuffer.blitMap[self.emptyBarColor]
      end
    end
    return barText, bgColors
  end

  local wasFullBarClicked = function(x, y)
    local barStartingY = self.screenStartingPos.y + 1
    local barEndingY = self.screenStartingPos.y + getFullBarLength()
    return y >= barStartingY and y <= barEndingY and x == self.screenStartingPos.x
  end

  local wasBarClicked = function(x, y)
    local scrollBarData = getScrollableBarData()
    if scrollBarData.startIndex == 0 then
      return false
    end
    local barStartingY = self.screenStartingPos.y + scrollBarData.startIndex --We add the index because the starting position is the scrollUp button
    local barEndingY = self.screenStartingPos.y + scrollBarData.endIndex
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
    if button == 1 and self.leftMouseDragScreenPos then

      local distanceY = y - self.leftMouseDragScreenPos.y
      self.leftMouseDragScreenPos = {x = x, y = y}
      if distanceY == 0 then
        return
      end
      local maxRenderPos = self.trackingScreenBuffer.getMaxRenderPos()
      local scrollBarData = getScrollableBarData()
      local renderPosRatio = (scrollBarData.startIndex - 1 + distanceY) / scrollBarData.barMovableHeight
      local scrollToPosY = math.floor(renderPosRatio * maxRenderPos.y) + 1
      self.trackingScreenBuffer.scrollTo(scrollToPosY)
    end
  end

  --Let's render to the middle of the bar when clicked
  local monitorTouchHandler = function(eventData)
    local side, x, y = eventData[2], eventData[3], eventData[4]
    if wasFullBarClicked(x, y) then
      local maxRenderPos = self.trackingScreenBuffer.getMaxRenderPos()
      local scrollBarData = getScrollableBarData()
      local barOffset = y - self.screenStartingPos.y - 1
      local startIndexToGoto = barOffset - math.floor(scrollBarData.height / 2)
      local renderPosRatio = startIndexToGoto / scrollBarData.barMovableHeight
      local scrollToPosY = math.floor(renderPosRatio * maxRenderPos.y) + 1
      self.trackingScreenBuffer.scrollTo(scrollToPosY)
    end
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
    
  end

  local makeActive = function()
    if not self.leftMouseDownHandlerId then
      self.monitorTouchHandlerId = self.eventHandler.addHandle("monitor_touch", monitorTouchHandler)
      self.leftMouseDownHandlerId = self.eventHandler.addHandle("mouse_click", mouseDownHandler)
      self.leftMouseUpHandlerId = self.eventHandler.addHandle("mouse_up", mouseUpHandler)
      self.leftMouseDragHandlerId = self.eventHandler.addHandle("mouse_drag", mouseDragHandler)
    end
    self.scrollUpButton.makeActive()
    self.scrollDownButton.makeActive()
    self.scrollBarScreenBuffer.render()
  end

  local makeInactive = function()
    if self.leftMouseDownHandlerId ~= nil then
      self.eventHandler.removeHandle(self.monitorTouchHandlerId)
      self.eventHandler.removeHandle(self.leftMouseDownHandlerId)
      self.eventHandler.removeHandle(self.leftMouseUpHandlerId)
      self.eventHandler.removeHandle(self.leftMouseDragHandlerId)

      self.monitorTouchHandlerId = nil
      self.leftMouseDownHandlerId = nil
      self.leftMouseUpHandlerId = nil
      self.leftMouseDragHandlerId = nil
    end
    
    self.scrollUpButton.makeInactive()
    self.scrollDownButton.makeInactive()
  end

  local screenBufferCallback = function(callbackData)
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