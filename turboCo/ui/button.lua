--Creates a button on your screenBuffer
--Has mouse hover, mouse click, and mouse

local function create(screenBuffer, eventHandler, text, textColor, backgroundColor, leftClickCallback, rightClickCallback)
  local self = {
    screenBuffer=screenBuffer,
    eventHandler=eventHandler,
    currentScreenPos= { x=0, y=0 },
    text=text,
    textColor=textColor,
    backgroundColor=backgroundColor,
    leftClickCallback=leftClickCallback,
    rightClickCallback=rightClickCallback,
    monitorTouchKeyHandlerId = nil,
    mouseClickKeyHandlerId = nil
  }

  local wasClicked = function(x, y)
    local maxPosX = self.currentScreenPos.x + #text
    return x >= self.currentScreenPos.x and x <= maxPosX and y == self.currentScreenPos.y
  end

  local monitorTouchHandler = function(eventData)
    local x, y = eventData[3], eventData[4]
    if wasClicked(x, y) then
      self.leftClickCallback()
    end
  end

  local mouseClickHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if self.currentScreenPos.x == x and self.currentScreenPos.y == y then
      if button == 1 then
        self.leftClickCallback()
      elseif button == 2 then
        self.rightClickCallback()
      end
    end
  end
  
  local screenMovedCallback = function(x, y)
    self.currentScreenPos.x = self.currentScreenPos.x + x
    self.currentScreenPos.y = self.currentScreenPos.y + y
  end

  local makeActive = function()
    if self.monitorTouchKeyHandlerId == nil then
      self.monitorTouchKeyHandlerId = self.eventHandler.addHandle("monitor_touch", monitorTouchHandler)
    end
    if self.mouseClickKeyHandlerId == nil then
      self.mouseClickKeyHandlerId = self.eventHandler.addHandle("mouse_click", mouseClickHandler)
    end
  end

  local makeInactive = function()
    if self.monitorTouchKeyHandlerId ~= nil then
      self.eventHandler.removeHandle(self.monitorTouchKeyHandlerId)
    end
    if self.mouseClickKeyHandlerId ~= nil then
      self.eventHandler.removeHandle(self.mouseClickKeyHandlerId)
    end
  end

  self.currentScreenPos.x, self.currentScreenPos.y = screenBuffer.getScreenCursorPos()
  screenBuffer.write(text, textColor, backgroundColor)
  screenBuffer.registerCallback(screenMovedCallback)
  makeActive()

  return {
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

return {
  create = create
}