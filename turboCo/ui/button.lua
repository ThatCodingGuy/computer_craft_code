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
    text=args.text,
    textColor=args.textColor,
    bgColor=args.bgColor,
    leftClickCallback=args.leftClickCallback,
    rightClickCallback=args.rightClickCallback,
    currentScreenPos= { x=0, y=0 },
    bufferCursorPos= { x=0, y=0 },
    monitorTouchKeyHandlerId = nil,
    mouseClickKeyHandlerId = nil,
    clickTimerId = nil
  }

  local wasClicked = function(x, y)
    local maxPosX = self.currentScreenPos.x + #self.text
    return x >= self.currentScreenPos.x and x <= maxPosX and y == self.currentScreenPos.y
  end

  local leftClick = function()
    --We want to flip the colors
    self.screenBuffer.write{text=self.text, color=self.bgColor, bgColor=self.textColor, bufferCursorPos=self.bufferCursorPos}
    self.screenBuffer.render()
    self.clickTimerId = os.startTimer(0.15)
    self.leftClickCallback()
  end

  local monitorTouchHandler = function(eventData)
    local x, y = eventData[3], eventData[4]
    if wasClicked(x, y) then
      if self.leftClickCallback ~= nil then
        leftClick()
      end
    end
  end

  local mouseClickHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if wasClicked(x, y) then
      if button == 1 and self.leftClickCallback ~= nil then
        leftClick()
      elseif button == 2 and self.rightClickCallback ~= nil then
        self.rightClickCallback()
      end
    end
  end
  
  local screenBufferCallback = function(callbackData)
    self.currentScreenPos.x = self.currentScreenPos.x + callbackData.movementOffset.x
    self.currentScreenPos.y = self.currentScreenPos.y + callbackData.movementOffset.y
  end

  local isActive = function()
    return self.monitorTouchKeyHandlerId ~= nil
  end

  local makeActive = function()
    --Can assume both input method IDs to be in same state
    if not isActive() then
      self.monitorTouchKeyHandlerId = self.eventHandler.addHandle("monitor_touch", monitorTouchHandler)
      self.mouseClickKeyHandlerId = self.eventHandler.addHandle("mouse_click", mouseClickHandler)
    end
  end

  local makeInactive = function()
    --Can assume both input method IDs to be in same state
    if isActive() then
      self.eventHandler.removeHandle(self.monitorTouchKeyHandlerId)
      self.eventHandler.removeHandle(self.mouseClickKeyHandlerId)
      self.monitorTouchKeyHandlerId = nil
      self.mouseClickKeyHandlerId = nil
    end
  end

  local timerCallback = function(eventData)
    --we want to flip back the colors 
    if eventData[2] == self.clickTimerId then
      self.screenBuffer.write{text=self.text, color=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.bufferCursorPos}
      self.clickTimerId = nil
      if isActive() then
        self.screenBuffer.render()
      end
    end
  end

  local getLeftClickCallback = function()
    return self.leftClickCallback
  end

  local getRightClickCallback = function()
    return self.rightClickCallback
  end

  local setLeftClickCallback = function(callbackFunc)
    self.leftClickCallback = callbackFunc
  end

  local setRightClickCallback = function(callbackFunc)
    self.rightClickCallback = callbackFunc
  end

  local writeData = self.screenBufferWriteFunc{text=self.text, color=self.textColor, bgColor=self.bgColor}
  self.currentScreenPos = writeData.screenCursorPosBefore
  self.bufferCursorPos = writeData.bufferCursorPosBefore
  self.screenBuffer.registerCallback(screenBufferCallback)
  self.eventHandler.addHandle("timer", timerCallback)
  makeActive()

  return {
    getLeftClickCallback=getLeftClickCallback,
    setLeftClickCallback=setLeftClickCallback,
    getRightClickCallback=getRightClickCallback,
    setRightClickCallback=setRightClickCallback,
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

return {
  create = create
}