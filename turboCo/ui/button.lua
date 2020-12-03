--Creates a button on your screenBuffer
--Has mouse hover, mouse click, and mouse

local function create(args)
  if args.screenBufferWriteFunc == nil then
    args.screenBufferWriteFunc = args.screenBuffer.write
  end

  local self = {
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    eventHandler=args.eventHandler,
    currentScreenPos= { x=0, y=0 },
    text=args.text,
    textColor=args.textColor,
    backgroundColor=args.backgroundColor,
    leftClickCallback=args.leftClickCallback,
    rightClickCallback=args.rightClickCallback,
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
  
  local screenBufferCallback = function(callbackData)
    self.currentScreenPos.x = self.currentScreenPos.x + callbackData.movementOffset.x
    self.currentScreenPos.y = self.currentScreenPos.y + callbackData.movementOffset.y
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
      self.monitorTouchKeyHandlerId = nil
    end
    if self.mouseClickKeyHandlerId ~= nil then
      self.eventHandler.removeHandle(self.mouseClickKeyHandlerId)
      self.mouseClickKeyHandlerId = nil
    end
  end

  local writeData = self.screenBufferWriteFunc{text=args.text, color=textColor, bgColor=backgroundColor}
  self.currentScreenPos = writeData.screenCursorPosBefore
  screenBuffer.registerCallback(screenBufferCallback)
  makeActive()

  return {
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

return {
  create = create
}